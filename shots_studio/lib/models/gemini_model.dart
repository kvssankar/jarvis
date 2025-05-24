import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
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

  String getPrompt({List<Map<String, String?>>? autoAddCollections}) {
    String basePrompt = """
      You are a screenshot analyzer. You will be given single or multiple images.
      For each image, generate a title, short description and 3-5 relevant tags
      with which users can search and find later with ease.
    """;

    // Add collections part to prompt if provided
    if (autoAddCollections != null && autoAddCollections.isNotEmpty) {
      basePrompt += """
      
      Here are list of collections and their descriptions that these images can potentially fit in.
      If the image belongs to any of these collections, include them in the response, if not, keep the collections list empty.
      
      Available collections:
      """;

      for (var collection in autoAddCollections) {
        basePrompt += """
        - Name: "${collection['name'] ?? 'Unnamed'}"
          Description: "${collection['description'] ?? 'No description'}"
        """;
      }
    }

    basePrompt += """
      
      Respond strictly in this JSON format:
      [{filename: '', title: '', desc: '', tags: [], collections: [], other: []}, ...]
      
      The "collections" field should contain names of collections that match the image content.
    """;

    return basePrompt;
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
    List<Screenshot> images, {
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    List<Map<String, dynamic>> contentParts = [
      {'text': getPrompt(autoAddCollections: autoAddCollections)},
    ];

    for (var image in images) {
      String imageIdentifier = image.id;

      // Path-based image for mobile
      if (image.path != null && image.path!.isNotEmpty) {
        contentParts.add({'text': '\\nAnalyzing image: $imageIdentifier'});

        try {
          final imageData = await convertImageToBase64(image.path!);
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error converting image ${image.path} to base64: $e");
          continue; // Skip this image and continue with others
        }
      } else if (image.bytes != null) {
        // Byte-based image for web
        contentParts.add({'text': '\\nAnalyzing image: $imageIdentifier'});

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

  Future<Map<String, dynamic>> processImages(
    List<Screenshot> images, {
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    if (images.isEmpty) {
      return {'error': 'No images to process', 'statusCode': 400};
    }

    print('Processing ${images.length} images...');
    try {
      final requestData = await _prepareRequestData(
        images,
        autoAddCollections: autoAddCollections,
      );
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
    Function(List<Screenshot>, Map<String, dynamic>) onBatchProcessed, {
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    if (images.isEmpty) {
      return {'error': 'No images to process', 'statusCode': 400};
    }

    print('Processing ${images.length} images in batches of $maxParallel...');

    Map<String, dynamic> finalResults = {
      'batchResults': [],
      'statusCode': 200,
      'processedCount': 0,
      'totalCount': images.length,
    };

    // Process in batches
    for (int i = 0; i < images.length; i += maxParallel) {
      int end = min(i + maxParallel, images.length);
      List<Screenshot> batch = images.sublist(i, end);

      print(
        'Processing batch ${(i ~/ maxParallel) + 1}: ${i + 1} to $end of ${images.length}',
      );

      try {
        final requestData = await _prepareRequestData(
          batch,
          autoAddCollections: autoAddCollections,
        );
        final headers = {'Content-Type': 'application/json'};
        final result = await _fetchAiResponse(requestData, headers);

        (finalResults['batchResults'] as List).add({
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
      final RegExp jsonRegExp = RegExp(r'\[.*\]', dotAll: true);
      final match = jsonRegExp.firstMatch(responseText);
      if (match != null) {
        try {
          parsedResponse = jsonDecode(match.group(0)!);
        } catch (e) {
          print('Failed to parse extracted JSON: $e');
          try {
            parsedResponse = jsonDecode(responseText);
          } catch (e) {
            print('Failed to parse full response: $e');
            return screenshots;
          }
        }
      } else {
        print('No JSON array found in response');
        return screenshots;
      }

      if (parsedResponse.isEmpty) {
        return screenshots;
      }

      print("\n\n response: $parsedResponse");

      List<Screenshot> updatedScreenshots = [];

      // If only one screenshot and one response, assume they match
      if (screenshots.length == 1 && parsedResponse.length == 1) {
        var screenshot = screenshots[0];
        var item = parsedResponse[0];

        final List<String> collectionNames = List<String>.from(
          item['collections'] ?? [],
        );

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

        // Store collection names for automatic adding later in the main component
        if (collectionNames.isNotEmpty) {
          Map<String, List<String>> suggestedCollections = {};
          suggestedCollections[updatedScreenshot.id] = collectionNames;

          // Make sure we can modify the response
          try {
            response['suggestedCollections'] = suggestedCollections;
          } catch (e) {
            print('Error storing collection suggestions: $e');
          }
        }

        print("\n\n updatedScreenshot: $updatedScreenshot returned here");
        return [updatedScreenshot];
      }

      // For multiple screenshots, try to match each one
      print("multiple screenshots present");

      List<dynamic> availableResponses = List.from(parsedResponse);

      for (var screenshot in screenshots) {
        String identifier = screenshot.id; // Using ID as the primary identifier

        Map<String, dynamic>? matchedAiItem;
        int? matchedAiItemIndex;

        // 1. Attempt to match by 'filename' (expected to be screenshot.id)
        for (int i = 0; i < availableResponses.length; i++) {
          var currentAiItem = availableResponses[i];
          if (currentAiItem is Map<String, dynamic>) {
            String responseFileId = currentAiItem['filename'] ?? '';
            if (responseFileId.isNotEmpty &&
                (identifier == responseFileId || // Exact match preferred
                    identifier.contains(responseFileId) || // Broader for safety
                    responseFileId.contains(identifier))) {
              matchedAiItem = currentAiItem;
              matchedAiItemIndex = i;
              print(
                "Matched screenshot id: $identifier with AI response filename: $responseFileId",
              );
              break; // Found a match for this screenshot
            }
          }
        }

        if (matchedAiItem != null) {
          // Update screenshot using the directly matched AI item
          final List<String> collectionNames = List<String>.from(
            matchedAiItem['collections'] ?? [],
          );
          final updatedSc = Screenshot(
            id: screenshot.id,
            path: screenshot.path,
            bytes: screenshot.bytes,
            title: matchedAiItem['title'] ?? screenshot.title,
            description: matchedAiItem['desc'] ?? screenshot.description,
            tags: List<String>.from(matchedAiItem['tags'] ?? []),
            aiProcessed: true,
            addedOn: screenshot.addedOn,
            collectionIds: screenshot.collectionIds,
          );

          // Store collection names for automatic adding later
          if (collectionNames.isNotEmpty) {
            try {
              Map<String, List<String>> suggestedCollections;
              if (response.containsKey('suggestedCollections') &&
                  response['suggestedCollections'] is Map) {
                suggestedCollections = Map<String, List<String>>.from(
                  response['suggestedCollections'] as Map,
                );
              } else {
                suggestedCollections = {};
              }
              suggestedCollections[updatedSc.id] = collectionNames;
              response['suggestedCollections'] = suggestedCollections;
            } catch (e) {
              print(
                'Error storing collection suggestions for matched item: $e',
              );
            }
          }

          updatedScreenshots.add(updatedSc);
          if (matchedAiItemIndex != null) {
            availableResponses.removeAt(
              matchedAiItemIndex,
            ); // Consume the matched response
          }
        } else {
          // No direct match by filename, try sequential
          print(
            "No AI responses left for sequential fallback for screenshot id: $identifier. Adding original screenshot.",
          );
          updatedScreenshots.add(screenshot); // Add original
        }
      }
      return updatedScreenshots;
    } catch (e) {
      print('Error parsing response and updating screenshots: $e');
      return screenshots;
    }
  }
}
