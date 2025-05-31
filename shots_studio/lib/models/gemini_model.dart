import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shots_studio/models/screenshot_model.dart';

typedef ShowMessageCallback =
    void Function({
      required String message,
      Color? backgroundColor,
      Duration? duration,
    });

class AiMetaData {
  String modelName;
  DateTime processingTime;

  AiMetaData({required this.modelName, required this.processingTime});

  // Method to convert AiMetaData instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'processingTime': processingTime.toIso8601String(),
    };
  }

  // Factory constructor to create an AiMetaData instance from a Map (JSON)
  factory AiMetaData.fromJson(Map<String, dynamic> json) {
    return AiMetaData(
      modelName: json['modelName'] as String,
      processingTime: DateTime.parse(json['processingTime'] as String),
    );
  }
}

class GeminiModel {
  String baseUrl;
  String? modelName;
  String apiKey;
  int timeoutSeconds;
  int maxParallel;
  int? maxRetries;
  ShowMessageCallback? showMessage;
  bool _isCancelled = false;

  GeminiModel({
    required this.modelName,
    required this.apiKey,
    this.timeoutSeconds = 120,
    this.maxParallel = 4,
    this.maxRetries,
    this.showMessage,
  }) : baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  void cancel() {
    _isCancelled = true;
    if (showMessage != null) {
      showMessage!(
        message: "AI processing cancellation requested.",
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      );
    }
    print("GeminiModel: Cancellation requested by user.");
  }

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
      Map<String, String> imageData;

      // Path-based image for mobile
      if (image.path != null && image.path!.isNotEmpty) {
        contentParts.add({'text': '\\nAnalyzing image: $imageIdentifier'});
        imageData = await convertImageToBase64(image.path!);
        try {
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error adding path-based image data for ${image.id}: $e");
        }
      } else if (image.bytes != null) {
        // Byte-based image for web
        contentParts.add({'text': '\\nAnalyzing image: $imageIdentifier'});
        imageData = bytesToBase64(
          image.bytes!,
          fileName: image.path,
        ); // Assuming path might hold a filename
        try {
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error adding byte-based image data for ${image.id}: $e");
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
    if (_isCancelled) {
      // Check cancellation flag
      print("GeminiModel: Fetch AI response cancelled before request.");
      return {
        'error': 'Request cancelled by user',
        'statusCode': 499,
      }; // 499 Client Closed Request
    }

    final url = Uri.parse(
      '$baseUrl/${modelName ?? "gemini-pro-vision"}:generateContent?key=$apiKey',
    );

    final requestBody = jsonEncode(requestData);
    print('Request body size: ${requestBody.length} bytes');

    try {
      final response = await http
          .post(url, headers: headers, body: requestBody)
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
    _isCancelled = false;

    if (images.isEmpty) {
      return {'error': 'No images to process', 'statusCode': 400};
    }

    print('Processing ${images.length} images in batches of $maxParallel...');

    Map<String, dynamic> finalResults = {
      'batchResults': [],
      'statusCode': 200,
      'processedCount': 0,
      'totalCount': images.length,
      'cancelled': false,
    };

    // Process in batches
    for (int i = 0; i < images.length; i += maxParallel) {
      if (_isCancelled) {
        print("GeminiModel: Batch processing loop cancelled.");
        finalResults['cancelled'] = true;
        break;
      }

      int end = min(i + maxParallel, images.length);
      List<Screenshot> batch = images.sublist(i, end);

      print(
        'Processing batch ${(i ~/ maxParallel) + 1}: ${i + 1} to $end of ${images.length}',
      );

      try {
        if (_isCancelled) {
          print(
            "GeminiModel: Batch processing cancelled before preparing request data for batch ${(i ~/ maxParallel) + 1}.",
          );
          finalResults['cancelled'] = true;
          // Optionally call onBatchProcessed with a cancellation status for the current batch
          onBatchProcessed(batch, {
            'error': 'Processing cancelled by user',
            'cancelled': true,
          });
          break;
        }

        final requestData = await _prepareRequestData(
          batch, // Pass the current batch
          autoAddCollections: autoAddCollections,
        );
        final headers = {'Content-Type': 'application/json'};
        final result = await _fetchAiResponse(requestData, headers);

        if (_isCancelled && result['statusCode'] == 499) {
          print(
            "GeminiModel: Batch processing detected cancellation from _fetchAiResponse for batch ${(i ~/ maxParallel) + 1}.",
          );
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, result);
          break;
        }

        (finalResults['batchResults'] as List).add({
          'batch':
              batch
                  .map((s) => s.id)
                  .toList(), // Log which image ids were in this batch
          'result': result,
        });

        if (result.containsKey('error')) {
          // If there's an error, update processed count for this batch as 0 or handle as needed
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int);
          onBatchProcessed(batch, result); // Call with error
        } else {
          // Assuming result['data'] contains info that helps count actual successes if needed
          // For now, count the batch size as processed if no error at this stage
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int) + batch.length;
          onBatchProcessed(batch, result); // Call with success
        }

        // Add a small delay between batches to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print(
          'Error processing batch ${(i ~/ maxParallel) + 1}: ${e.toString()}',
        );
        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'error': e.toString(),
        });
        // Still call callback so UI can be updated even in case of errors
        onBatchProcessed(batch, {'error': e.toString()});
      }
    }

    if (_isCancelled) {
      print(
        "GeminiModel: ProcessBatchedImages completed with cancellation status.",
      );
    }
    return finalResults;
  }

  List<Screenshot> parseResponseAndUpdateScreenshots(
    List<Screenshot> screenshots,
    Map<String, dynamic> response,
  ) {
    if (response.containsKey('error') || !response.containsKey('data')) {
      if (response['error'] != null &&
          response['error'].toString().contains('API key not valid')) {
        showMessage?.call(
          message: 'Invalid API key provided. Please check your API key.',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      } else if (response['error'] != null &&
          response['error'].toString().contains('Network error')) {
        showMessage?.call(
          message:
              'Network issue detected. Please check your internet connection and try again.',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        );
      } else {
        showMessage?.call(
          message:
              'No data found in response or error occurred: ${response['error']}',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        );
      }
      print('Error in response: ${response['error'] ?? 'No data found'}');
      return screenshots;
    }

    try {
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

      AiMetaData aiMetaData = AiMetaData(
        modelName: modelName ?? 'Unknown Model',
        processingTime: DateTime.now().add(Duration(seconds: timeoutSeconds)),
      );

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
          aiMetadata: aiMetaData,
          fileSize: screenshot.fileSize,
          isDeleted: screenshot.isDeleted,
          reminderTime: screenshot.reminderTime,
          reminderText: screenshot.reminderText,
        );

        // Store collection names for automatic adding later in the main component
        if (collectionNames.isNotEmpty) {
          Map<String, List<String>> suggestedCollections = {};
          suggestedCollections[updatedScreenshot.id] = collectionNames;

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
        String identifier = screenshot.id;

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
              break;
            }
          }
        }

        if (matchedAiItem != null) {
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
            aiMetadata: aiMetaData,
            fileSize: screenshot.fileSize,
            isDeleted: screenshot.isDeleted,
            reminderTime: screenshot.reminderTime,
            reminderText: screenshot.reminderText,
          );

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
            availableResponses.removeAt(matchedAiItemIndex);
          }
        } else {
          print(
            "No AI responses left for sequential fallback for screenshot id: $identifier. Adding original screenshot.",
          );
          updatedScreenshots.add(screenshot);
        }
      }
      return updatedScreenshots;
    } catch (e) {
      print('Error parsing response and updating screenshots: $e');
      return screenshots;
    }
  }

  String getCategorizePrompt(
    String collectionName,
    String? collectionDescription,
  ) {
    String basePrompt = """
      You are a screenshot categorization system. You will be given a collection and a list of screenshots with their metadata.
      
      Collection to categorize into:
      - Name: "$collectionName"
      - Description: "${collectionDescription ?? 'No description provided'}"
      
      For each screenshot provided, analyze the title, description, and tags to determine if it fits into this collection.
      Consider the semantic meaning and context, not just exact keyword matches.
      
      Respond strictly in this JSON format:
      {
        "matching_screenshots": ["screenshot_id_1", "screenshot_id_2", ...],
        "reasoning": "Brief explanation of why these screenshots match the collection"
      }
      
      Only include screenshot IDs that genuinely fit the collection's purpose and description.
    """;

    return basePrompt;
  }

  Future<Map<String, dynamic>> categorizeScreenshotsIntoCollection({
    required String collectionId,
    required String collectionName,
    String? collectionDescription,
    required List<Screenshot> screenshots,
    required Function(List<Screenshot>, Map<String, dynamic>) onBatchProcessed,
  }) async {
    _isCancelled = false;

    if (screenshots.isEmpty) {
      return {'error': 'No screenshots to categorize', 'statusCode': 400};
    }

    print(
      'Categorizing ${screenshots.length} screenshots into collection: $collectionName...',
    );

    Map<String, dynamic> finalResults = {
      'batchResults': [],
      'statusCode': 200,
      'processedCount': 0,
      'totalCount': screenshots.length,
      'cancelled': false,
      'matchingScreenshots': <String>[],
    };

    // Process in batches
    for (int i = 0; i < screenshots.length; i += maxParallel) {
      if (_isCancelled) {
        print("GeminiModel: Categorization batch processing cancelled.");
        finalResults['cancelled'] = true;
        break;
      }

      int end = min(i + maxParallel, screenshots.length);
      List<Screenshot> batch = screenshots.sublist(i, end);

      print(
        'Categorizing batch ${(i ~/ maxParallel) + 1}: ${i + 1} to $end of ${screenshots.length}',
      );

      try {
        if (_isCancelled) {
          print(
            "GeminiModel: Categorization cancelled before processing batch ${(i ~/ maxParallel) + 1}.",
          );
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, {
            'error': 'Categorization cancelled by user',
            'cancelled': true,
          });
          break;
        }

        final requestData = await _prepareCategorizeRequestData(
          collectionName,
          collectionDescription,
          batch,
        );
        final headers = {'Content-Type': 'application/json'};
        final result = await _fetchAiResponse(requestData, headers);

        if (_isCancelled && result['statusCode'] == 499) {
          print(
            "GeminiModel: Categorization detected cancellation for batch ${(i ~/ maxParallel) + 1}.",
          );
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, result);
          break;
        }

        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'result': result,
        });

        if (result.containsKey('error')) {
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int);
          onBatchProcessed(batch, result);
        } else {
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int) + batch.length;

          // Parse the categorization result
          final matchingIds = _parseCategorizeResponse(result);
          (finalResults['matchingScreenshots'] as List<String>).addAll(
            matchingIds,
          );

          onBatchProcessed(batch, result);
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print(
          'Error categorizing batch ${(i ~/ maxParallel) + 1}: ${e.toString()}',
        );
        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'error': e.toString(),
        });
        onBatchProcessed(batch, {'error': e.toString()});
      }
    }

    if (_isCancelled) {
      print("GeminiModel: Categorization completed with cancellation status.");
    }
    return finalResults;
  }

  Future<Map<String, dynamic>> _prepareCategorizeRequestData(
    String collectionName,
    String? collectionDescription,
    List<Screenshot> screenshots,
  ) async {
    List<Map<String, dynamic>> contentParts = [
      {'text': getCategorizePrompt(collectionName, collectionDescription)},
    ];

    contentParts.add({'text': '\nScreenshots to analyze:'});

    for (var screenshot in screenshots) {
      String screenshotInfo = '''
      ID: ${screenshot.id}
      Title: ${screenshot.title ?? 'No title'}
      Description: ${screenshot.description ?? 'No description'}
      Tags: ${screenshot.tags.join(', ')}
      ''';
      contentParts.add({'text': screenshotInfo});
    }

    final requestData = {
      'contents': [
        {'parts': contentParts},
      ],
    };
    return requestData;
  }

  List<String> _parseCategorizeResponse(Map<String, dynamic> response) {
    List<String> matchingScreenshots = [];

    try {
      if (response.containsKey('data')) {
        final String responseText = response['data'];
        final RegExp jsonRegExp = RegExp(r'\{.*\}', dotAll: true);
        final match = jsonRegExp.firstMatch(responseText);

        if (match != null) {
          final parsedResponse = jsonDecode(match.group(0)!);
          if (parsedResponse['matching_screenshots'] is List) {
            matchingScreenshots = List<String>.from(
              parsedResponse['matching_screenshots'],
            );
          }
        }
      }
    } catch (e) {
      print('Error parsing categorization response: $e');
    }

    return matchingScreenshots;
  }
}
