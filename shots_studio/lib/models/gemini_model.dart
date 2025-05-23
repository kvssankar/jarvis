import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'package:http/http.dart' as http;
import 'package:shots_studio/models/screenshot_model.dart';

class GeminiModel {
  String baseUrl;
  String? modelName;
  String apiKey;
  int timeoutSeconds;
  int maxParallel;
  int? maxRetries;

  GeminiModel({
    required this.modelName,
    required this.apiKey,
    this.timeoutSeconds = 60,
    this.maxParallel = 4,
    this.maxRetries,
  }) : baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  String getPrompt() {
    return """
      You are a screenshot analyzer. You will be given single or multiple images.
      For each image, generate a title, short description and 3-5 relevant tags
      with which users can search and find later with ease.
      Respond strictly in this JSON format:
      [{filename: '', title: '', desc: '', tags: [], other: []}, ...]
      """;
  }

  Future<Map<String, String>> convertImageToBase64(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception("Image file not found: $imagePath");
    }
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    String mimeType = 'image/png'; // Default to png
    if (imagePath.toLowerCase().endsWith('.jpg') ||
        imagePath.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    }
    return {'mime_type': mimeType, 'data': encoded};
  }

  Map<String, String> bytesToBase64(Uint8List bytes, {String? fileName}) {
    final encoded = base64Encode(bytes);
    String mimeType = 'image/png'; // Default to png
    if (fileName != null &&
        (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg'))) {
      mimeType = 'image/jpeg';
    }
    return {'mime_type': mimeType, 'data': encoded};
  }

  Future<Map<String, dynamic>> _prepareRequestData(
    List<Screenshot> images,
  ) async {
    List<Map<String, dynamic>> contentParts = [
      {'text': getPrompt()},
    ];

    for (var image in images) {
      String imageIdentifier = "Image ${image.id}";

      // Handle path-based images (mobile) and byte-based images (web)
      if (image.path != null && image.path!.isNotEmpty) {
        // Path-based image for mobile
        imageIdentifier = image.path!.split('/').last;
        contentParts.add({'text': '\\nAnalyzing image: ${imageIdentifier}'});

        try {
          final imageData = await convertImageToBase64(image.path!);
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error converting image ${image.path} to base64: $e");
          continue; // Skip this image and continue with others
        }
      } else if (image.bytes != null) {
        // Byte-based image for web
        imageIdentifier = image.title ?? "Web image ${image.id}";
        contentParts.add({'text': '\\nAnalyzing image: ${imageIdentifier}'});

        try {
          final imageData = bytesToBase64(image.bytes!, fileName: image.title);
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error converting image bytes to base64: $e");
          continue; // Skip this image and continue with others
        }
      } else {
        print("Warning: Screenshot with id ${image.id} has no path or bytes.");
        continue; // Skip this image as it has no data
      }
    }

    final requestData = {
      'contents': [
        {'parts': contentParts},
      ],
    };
    print('Request data prepared: $requestData');
    return requestData;
  }

  Future<Map<String, dynamic>> _fetchAiResponse(
    Map<String, dynamic> requestData,
    Map<String, String> headers,
  ) async {
    final url = Uri.parse(
      '$baseUrl/${modelName ?? "gemini-pro-vision"}:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode(requestData);
    print('Request body size: ${requestBody.length} bytes'); // Added log

    try {
      final response = await http
          .post(url, headers: headers, body: requestBody) // Use requestBody
          .timeout(Duration(seconds: timeoutSeconds));

      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final candidates = responseJson['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null) {
                return {'data': text, 'statusCode': response.statusCode};
              }
            }
          }
        }
        return {
          'error': 'No response text from AI',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      } else {
        return {
          'error': responseJson['error']?['message'] ?? 'API Error',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }
    } on SocketException catch (e) {
      return {
        'error': 'Network error: ${e.message}',
        'statusCode': 503,
      }; // Service Unavailable
    } on TimeoutException catch (_) {
      return {'error': 'Request timed out', 'statusCode': 408};
    } catch (e) {
      return {'error': 'Unexpected error: ${e.toString()}', 'statusCode': 500};
    }
  }

  Future<Map<String, dynamic>> processImages(List<Screenshot> images) async {
    if (images.isEmpty) {
      return {'error': 'No images to process', 'statusCode': 400};
    }

    print('Processing ${images.length} images...');
    try {
      final requestData = await _prepareRequestData(images);
      final headers = {'Content-Type': 'application/json'};
      return await _fetchAiResponse(requestData, headers);
    } catch (e) {
      return {
        'error': 'Error preparing request: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  Future<Map<String, dynamic>> processBatchedImages(
    List<Screenshot> images,
    Function(List<Screenshot>, Map<String, dynamic>) onBatchProcessed,
  ) async {
    if (images.isEmpty) {
      return {'error': 'No images to process', 'statusCode': 400};
    }

    print('Processing ${images.length} images in batches of $maxParallel...');

    // Final results to be returned when all batches are done
    Map<String, dynamic> finalResults = {
      'batchResults': [],
      'statusCode': 200,
      'processedCount': 0,
      'totalCount': images.length,
    };

    // Process in batches
    for (int i = 0; i < images.length; i += maxParallel) {
      int end =
          (i + maxParallel < images.length) ? i + maxParallel : images.length;
      List<Screenshot> batch = images.sublist(i, end);

      print(
        'Processing batch ${(i ~/ maxParallel) + 1}: ${i + 1} to $end of ${images.length}',
      );

      try {
        // Process this batch
        final requestData = await _prepareRequestData(batch);
        final headers = {'Content-Type': 'application/json'};
        final result = await _fetchAiResponse(requestData, headers);

        // Add to final results
        finalResults['batchResults'].add({
          'batch': (i ~/ maxParallel) + 1,
          'result': result,
        });

        if (result.containsKey('error')) {
          print('Error in batch ${(i ~/ maxParallel) + 1}: ${result['error']}');
          // Even if there's an error, some images might have been processed successfully
          final updatedScreenshots = parseResponseAndUpdateScreenshots(
            batch,
            result,
          );
          final successfullyProcessed =
              updatedScreenshots.where((s) => s.aiProcessed).length;
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int) + successfullyProcessed;

          // Call the callback even for partial success
          onBatchProcessed(batch, result);
        } else {
          // All images in this batch were processed successfully
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int) + batch.length;

          // Call the callback function to update the UI with successful results
          onBatchProcessed(batch, result);
        }

        // Add a small delay between batches to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print(
          'Error processing batch ${(i ~/ maxParallel) + 1}: ${e.toString()}',
        );
        finalResults['batchResults'].add({
          'batch': (i ~/ maxParallel) + 1,
          'error': e.toString(),
        });
        // Still call callback so UI can be updated even in case of errors
        onBatchProcessed(batch, {'error': e.toString()});
      }
    }

    return finalResults;
  }

  Future<Map<String, dynamic>> processImage(Screenshot screenshot) async {
    if ((screenshot.path == null || screenshot.path!.isEmpty) &&
        screenshot.bytes == null) {
      return {
        'error': 'No image data provided (path or bytes)',
        'statusCode': 400,
      };
    }

    print('Processing image ${screenshot.id}...');
    try {
      final List<Screenshot> singleImage = [screenshot];
      final requestData = await _prepareRequestData(singleImage);
      final headers = {'Content-Type': 'application/json'};
      return await _fetchAiResponse(requestData, headers);
    } catch (e) {
      return {
        'error': 'Error processing image: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }

  Map<String, dynamic> extractCommand(String query) {
    query = query.trim();
    if (!query.startsWith("```json")) {
      return {'text': query, 'commands': <String>[]};
    }
    query = query.replaceAll("```json", "").replaceAll("```", "").trim();

    try {
      final data = jsonDecode(query);
      if (data is Map<String, dynamic>) {
        return {
          'text': data['text'] ?? '',
          'commands': List<String>.from(data['commands'] ?? []),
        };
      }
      return {
        'text': '',
        'commands': <String>[],
        'error': 'Decoded JSON is not a Map',
      };
    } catch (e) {
      print("Error processing query for command extraction: $e");
      return {'text': '', 'commands': <String>[], 'error': e.toString()};
    }
  }

  List<Screenshot> parseResponseAndUpdateScreenshots(
    List<Screenshot> screenshots,
    Map<String, dynamic> response,
  ) {
    if (response.containsKey('error') || !response.containsKey('data')) {
      print('Error in response: ${response['error'] ?? 'No data found'}');
      return screenshots; // Return unchanged if there was an error
    }

    try {
      // Parse JSON response
      final String responseText = response['data'];
      List<dynamic> parsedResponse = [];

      try {
        // Try to parse the JSON - sometimes the AI might return malformed JSON
        parsedResponse = jsonDecode(responseText);
      } catch (e) {
        print('Failed to parse JSON response: $e');
        print('Response text: $responseText');
        // Attempt to extract JSON from text if it's embedded in other content
        final RegExp jsonRegExp = RegExp(r'\[.*\]', dotAll: true);
        final match = jsonRegExp.firstMatch(responseText);
        if (match != null) {
          try {
            parsedResponse = jsonDecode(match.group(0)!);
          } catch (e) {
            print('Failed to extract JSON from response: $e');
            return screenshots;
          }
        } else {
          return screenshots;
        }
      }

      if (parsedResponse.isEmpty) {
        return screenshots;
      }

      // Match responses to screenshots based on filename/path/index
      List<Screenshot> updatedScreenshots = [];

      // If only one screenshot and one response, assume they match
      if (screenshots.length == 1 && parsedResponse.length == 1) {
        var screenshot = screenshots[0];
        var item = parsedResponse[0];

        if (item is Map<String, dynamic>) {
          final updatedScreenshot = Screenshot(
            id: screenshot.id,
            path: screenshot.path,
            bytes: screenshot.bytes,
            title:
                item['desc']?.toString().split('.').first ?? screenshot.title,
            description: item['desc'] ?? screenshot.description,
            tags: List<String>.from(item['tags'] ?? []),
            aiProcessed: true,
            addedOn: screenshot.addedOn,
            collectionIds: screenshot.collectionIds,
          );
          return [updatedScreenshot];
        }
      }

      // For multiple screenshots, try to match each one
      for (var screenshot in screenshots) {
        // Try to get an identifier for matching
        String identifier = '';

        // Use path for mobile screenshots
        if (screenshot.path != null && screenshot.path!.isNotEmpty) {
          identifier = screenshot.path!.split('/').last;
        }
        // Use title for web screenshots
        else if (screenshot.title != null && screenshot.title!.isNotEmpty) {
          identifier = screenshot.title!;
        }
        // Fall back to ID
        else {
          identifier = screenshot.id;
        }

        bool updated = false;

        for (var item in parsedResponse) {
          if (item is! Map<String, dynamic>) continue;

          String responseFilename = item['filename'] ?? '';

          // Try to match by filename/identifier
          if (responseFilename.isNotEmpty &&
              (identifier.contains(responseFilename) ||
                  responseFilename.contains(identifier) ||
                  // Fall back to matching the ID or any substring
                  screenshot.id.contains(responseFilename) ||
                  responseFilename.contains(screenshot.id))) {
            // Update the screenshot
            final updatedScreenshot = Screenshot(
              id: screenshot.id,
              path: screenshot.path,
              bytes: screenshot.bytes,
              title: item['title'] ?? screenshot.title,
              description: item['desc'] ?? screenshot.description,
              tags: List<String>.from(item['tags'] ?? []),
              aiProcessed: true,
              addedOn: screenshot.addedOn,
              collectionIds: screenshot.collectionIds,
            );

            updatedScreenshots.add(updatedScreenshot);
            updated = true;
            break;
          }
        }

        // If no match found by name, just update sequentially
        if (!updated && updatedScreenshots.length < parsedResponse.length) {
          var item = parsedResponse[updatedScreenshots.length];
          if (item is Map<String, dynamic>) {
            final updatedScreenshot = Screenshot(
              id: screenshot.id,
              path: screenshot.path,
              bytes: screenshot.bytes,
              title:
                  item['desc']?.toString().split('.').first ?? screenshot.title,
              description: item['desc'] ?? screenshot.description,
              tags: List<String>.from(item['tags'] ?? []),
              aiProcessed: true,
              addedOn: screenshot.addedOn,
              collectionIds: screenshot.collectionIds,
            );

            updatedScreenshots.add(updatedScreenshot);
          } else {
            // No valid item to use, keep original
            updatedScreenshots.add(screenshot);
          }
        }
        // If we run out of responses, keep the original screenshot
        else if (!updated) {
          updatedScreenshots.add(screenshot);
        }
      }

      return updatedScreenshots;
    } catch (e) {
      print('Error parsing response and updating screenshots: $e');
      return screenshots;
    }
  }
}
