// Screenshot Analysis Service
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/services/ai_service.dart';
import 'package:shots_studio/utils/image_conversion_utils.dart';
import 'package:shots_studio/utils/collection_utils.dart';
import 'package:shots_studio/utils/ai_error_utils.dart';
import 'package:shots_studio/utils/json_utils.dart';

class ScreenshotAnalysisService extends AIService {
  // Track network errors to prevent multiple notifications
  int _networkErrorCount = 0;
  bool _processingTerminated = false;
  bool _apiKeyErrorShown = false;

  // Track when the last successful request was made
  DateTime? _lastSuccessfulRequestTime;

  ScreenshotAnalysisService(super.config);

  @override
  void reset() {
    super.reset();
    _networkErrorCount = 0;
    _processingTerminated = false;
    _apiKeyErrorShown = false;
    _lastSuccessfulRequestTime = DateTime.now();
  }

  Future<AIResult<Map<String, dynamic>>> analyzeScreenshots({
    required List<Screenshot> screenshots,
    required BatchProcessedCallback onBatchProcessed,
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    reset();

    if (screenshots.isEmpty) {
      return AIResult.error('No screenshots to analyze');
    }

    Map<String, dynamic> finalResults = {
      'batchResults': [],
      'statusCode': 200,
      'processedCount': 0,
      'totalCount': screenshots.length,
      'cancelled': false,
    };

    // Process in batches
    for (int i = 0; i < screenshots.length; i += config.maxParallel) {
      if (isCancelled) {
        finalResults['cancelled'] = true;
        break;
      }

      int end = min(i + config.maxParallel, screenshots.length);
      List<Screenshot> batch = screenshots.sublist(i, end);

      // Filter out already processed screenshots from this batch
      final unprocessedBatch = batch.where((s) => !s.aiProcessed).toList();

      // If no screenshots in this batch need processing, skip to next batch
      if (unprocessedBatch.isEmpty) {
        // Still call the callback to maintain progress tracking
        onBatchProcessed(batch, {
          'skipped': true,
          'reason': 'All screenshots already processed',
          'statusCode': 200,
        });
        continue;
      }

      try {
        if (isCancelled) {
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, {
            'error': 'Processing cancelled by user',
            'cancelled': true,
          });
          break;
        }

        final requestData = await _prepareRequestData(
          unprocessedBatch, // Use filtered batch
          autoAddCollections: autoAddCollections,
        );
        final result = await _makeAPIRequest(requestData);

        if (isCancelled && result['statusCode'] == 499) {
          finalResults['cancelled'] = true;
          onBatchProcessed(batch, result);
          break;
        }

        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'result': result,
        });

        if (result.containsKey('error')) {
          onBatchProcessed(batch, result);
        } else {
          // Try to parse and update screenshots
          try {
            parseAndUpdateScreenshots(unprocessedBatch, result);
            finalResults['processedCount'] =
                (finalResults['processedCount'] as int) + batch.length;
            onBatchProcessed(batch, result);
          } catch (parseError) {
            // Handle parsing errors by stopping processing and showing error
            print("Parsing error occurred: $parseError");
            final errorResult = {
              'error': parseError.toString(),
              'statusCode': 422, // Unprocessable Entity
              'parsing_error': true,
            };
            (finalResults['batchResults'] as List).add({
              'batch': batch.map((s) => s.id).toList(),
              'result': errorResult,
            });
            onBatchProcessed(batch, errorResult);
            // Stop processing further batches on parsing error
            break;
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        (finalResults['batchResults'] as List).add({
          'batch': batch.map((s) => s.id).toList(),
          'error': e.toString(),
        });
        onBatchProcessed(batch, {'error': e.toString()});
      }
    }

    if (isCancelled) {
      return AIResult.cancelled();
    }

    return AIResult.success(finalResults);
  }

  List<Screenshot> parseAndUpdateScreenshots(
    List<Screenshot> screenshots,
    Map<String, dynamic> response,
  ) {
    if (response.containsKey('error') || !response.containsKey('data')) {
      // Don't show error messages if processing has already been terminated
      if (!_processingTerminated) {
        _handleResponseError(response);
      }
      return screenshots;
    }

    try {
      final String responseText = response['data'];
      List<dynamic> parsedResponse = [];
      // Clean the response text by removing markdown code fences
      String cleanedResponseText = JsonUtils.cleanMarkdownCodeFences(
        responseText,
      );

      // Check if the JSON is complete (has matching brackets)
      if (!JsonUtils.isCompleteJson(cleanedResponseText)) {
        print("WARNING: JSON appears to be truncated or incomplete");
        // Try to fix incomplete JSON
        cleanedResponseText = JsonUtils.attemptJsonFix(cleanedResponseText);
      }

      // Try to parse the cleaned text directly first
      try {
        parsedResponse = jsonDecode(cleanedResponseText);
      } catch (e) {
        print("Initial JSON parsing failed: $e");

        // Try to extract JSON array with regex as fallback
        final RegExp jsonRegExp = RegExp(r'\[.*\]', dotAll: true);
        final match = jsonRegExp.firstMatch(cleanedResponseText);

        if (match != null) {
          try {
            String extractedJson = match.group(0)!;
            parsedResponse = jsonDecode(extractedJson);
          } catch (e2) {
            print("Failed to parse extracted JSON: $e2");
            // Throw parsing error to stop processing and show error to user
            throw Exception(
              'JSON parsing failed: Unable to parse AI response. The response format is invalid or corrupted. Please try again.',
            );
          }
        } else {
          print("No JSON array pattern found in response");
          // Throw parsing error to stop processing and show error to user
          throw Exception(
            'JSON parsing failed: No valid JSON array found in AI response. Please try again.',
          );
        }
      }

      if (parsedResponse.isEmpty) {
        throw Exception(
          'JSON parsing failed: AI response is empty or invalid. Please try again.',
        );
      }

      // Validate and sanitize the parsed response
      parsedResponse = _validateAndSanitizeResponse(parsedResponse);

      AiMetaData aiMetaData = AiMetaData(
        modelName: config.modelName,
        processingTime: DateTime.now(),
      );

      if (screenshots.length == 1 && parsedResponse.length == 1) {
        return _updateSingleScreenshot(
          screenshots[0],
          parsedResponse[0],
          aiMetaData,
          response,
        );
      }

      return _updateMultipleScreenshots(
        screenshots,
        parsedResponse,
        aiMetaData,
        response,
      );
    } catch (e) {
      print('Error parsing response and updating screenshots: $e');
      return screenshots;
    }
  }

  /// Validates and sanitizes the parsed response to ensure it has the correct structure
  List<dynamic> _validateAndSanitizeResponse(List<dynamic> parsedResponse) {
    List<dynamic> sanitizedResponse = [];

    for (var item in parsedResponse) {
      if (item is Map<String, dynamic>) {
        Map<String, dynamic> sanitizedItem = Map<String, dynamic>.from(item);

        // Ensure required fields exist and have correct types
        sanitizedItem['filename'] =
            (sanitizedItem['filename'] ?? '').toString();
        sanitizedItem['title'] = (sanitizedItem['title'] ?? '').toString();
        sanitizedItem['desc'] = (sanitizedItem['desc'] ?? '').toString();

        // Ensure tags is always a list
        if (sanitizedItem['tags'] is! List) {
          if (sanitizedItem['tags'] is String) {
            // If tags is a string, split by comma or other delimiters
            String tagString = sanitizedItem['tags'].toString();
            sanitizedItem['tags'] =
                tagString
                    .split(RegExp(r'[,;|]'))
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
          } else {
            sanitizedItem['tags'] = [];
          }
        } else {
          // Ensure all items in tags list are strings
          sanitizedItem['tags'] =
              (sanitizedItem['tags'] as List)
                  .map((tag) => tag.toString())
                  .toList();
        }

        // Ensure collections is always a list
        if (sanitizedItem['collections'] is! List) {
          if (sanitizedItem['collections'] is String) {
            // If collections is a string, split by comma or other delimiters
            String collectionString = sanitizedItem['collections'].toString();
            sanitizedItem['collections'] =
                collectionString
                    .split(RegExp(r'[,;|]'))
                    .map((col) => col.trim())
                    .where((col) => col.isNotEmpty)
                    .toList();
          } else {
            sanitizedItem['collections'] = [];
          }
        } else {
          // Ensure all items in collections list are strings
          sanitizedItem['collections'] =
              (sanitizedItem['collections'] as List)
                  .map((col) => col.toString())
                  .toList();
        }

        // Ensure other is always a list
        if (sanitizedItem['other'] is! List) {
          if (sanitizedItem['other'] is String) {
            // If other is a string, convert to single-item list
            sanitizedItem['other'] = [sanitizedItem['other'].toString()];
          } else if (sanitizedItem['other'] != null) {
            sanitizedItem['other'] = [sanitizedItem['other'].toString()];
          } else {
            sanitizedItem['other'] = [];
          }
        } else {
          // Ensure all items in other list are strings
          sanitizedItem['other'] =
              (sanitizedItem['other'] as List)
                  .map((item) => item.toString())
                  .toList();
        }

        sanitizedResponse.add(sanitizedItem);
      } else {
        print("Warning: Invalid item found in response, skipping: $item");
      }
    }

    return sanitizedResponse;
  }

  String _getAnalysisPrompt({List<Map<String, String?>>? autoAddCollections}) {
    String basePrompt = """
      You are a screenshot analyzer. You will be given single or multiple images.
      For each image, generate a title, short description and 3-5 relevant tags
      with which users can search and find later with ease.
    """;

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
      [{"filename": '', "title": '', "desc": '', "tags": [], "collections": [], "other": []}, ...]
      The "other" field can contain any additional information you find relevant.
      The "collections" field should contain names of collections that match the image content.
    """;

    return basePrompt;
  }

  Future<Map<String, dynamic>> _prepareRequestData(
    List<Screenshot> images, {
    List<Map<String, String?>>? autoAddCollections,
  }) async {
    // Filter out screenshots that are already AI processed (including corrupted ones)
    final unprocessedImages =
        images.where((image) => !image.aiProcessed).toList();

    // Prepare image data in a generic format
    List<Map<String, dynamic>> imageData = [];

    for (var image in unprocessedImages) {
      String imageIdentifier = image.id;
      Map<String, String>? imageBase64Data;

      try {
        if (image.path != null && image.path!.isNotEmpty) {
          imageBase64Data = await ImageConversionUtils.convertImageToBase64(
            image.path!,
          );
        } else if (image.bytes != null) {
          imageBase64Data = ImageConversionUtils.bytesToBase64(
            image.bytes!,
            fileName: image.path,
          );
        } else {
          print(
            "Warning: Screenshot with id ${image.id} has no path or bytes.",
          );
          continue;
        }

        imageData.add({'identifier': imageIdentifier, 'data': imageBase64Data});
      } catch (e) {
        print("Error adding image data for ${image.id}: $e");
      }
    }

    // Use the provider-specific request preparation
    final requestData = prepareScreenshotAnalysisRequest(
      prompt: _getAnalysisPrompt(autoAddCollections: autoAddCollections),
      imageData: imageData,
    );

    // Fallback to old format if provider doesn't support new format
    return requestData ??
        {
          'contents': [
            {
              'parts': [
                {'text': 'No images to process - provider not supported.'},
              ],
            },
          ],
        };
  }

  // Wrapper method that adds screenshot-specific logic before calling base API method
  Future<Map<String, dynamic>> _makeAPIRequest(
    Map<String, dynamic> requestData,
  ) async {
    if (isCancelled || _processingTerminated) {
      return {'error': 'Request cancelled by user', 'statusCode': 499};
    }

    // Check if it has been a long time since the last successful request
    if (_lastSuccessfulRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(
        _lastSuccessfulRequestTime!,
      );
      // If more than 2 minutes have passed since the last successful request, assume app was reopened
      if (timeSinceLastRequest.inMinutes > 2) {
        _processingTerminated = true;
        return {
          'error':
              'App was likely closed and reopened. AI processing terminated.',
          'statusCode': 499,
        };
      }
    }

    // Call the base class method to make the actual API request
    final result = await makeAPIRequest(requestData);

    // Update last successful request time if the request was successful
    if (result['statusCode'] == 200) {
      _lastSuccessfulRequestTime = DateTime.now();
    }

    return result;
  }

  List<Screenshot> _updateSingleScreenshot(
    Screenshot screenshot,
    Map<String, dynamic> item,
    AiMetaData aiMetaData,
    Map<String, dynamic> response,
  ) {
    final List<String> collectionNames = List<String>.from(
      item['collections'] ?? [],
    );

    final updatedScreenshot = screenshot.copyWith(
      title: item['title'] ?? screenshot.title,
      description: item['desc'] ?? screenshot.description,
      tags: List<String>.from(item['tags'] ?? []),
      aiProcessed: true,
      aiMetadata: aiMetaData,
    );

    if (collectionNames.isNotEmpty) {
      CollectionUtils.storeSuggestedCollections(
        response,
        updatedScreenshot.id,
        collectionNames,
      );
    }

    return [updatedScreenshot];
  }

  List<Screenshot> _updateMultipleScreenshots(
    List<Screenshot> screenshots,
    List<dynamic> parsedResponse,
    AiMetaData aiMetaData,
    Map<String, dynamic> response,
  ) {
    List<Screenshot> updatedScreenshots = [];
    List<dynamic> availableResponses = List.from(parsedResponse);

    for (var screenshot in screenshots) {
      String identifier = screenshot.id;
      Map<String, dynamic>? matchedAiItem;
      int? matchedAiItemIndex;

      // Find matching AI response by filename
      for (int i = 0; i < availableResponses.length; i++) {
        var currentAiItem = availableResponses[i];
        if (currentAiItem is Map<String, dynamic>) {
          String responseFileId = currentAiItem['filename'] ?? '';
          if (responseFileId.isNotEmpty &&
              (identifier == responseFileId ||
                  identifier.contains(responseFileId) ||
                  responseFileId.contains(identifier))) {
            matchedAiItem = currentAiItem;
            matchedAiItemIndex = i;
            break;
          }
        }
      }

      if (matchedAiItem != null) {
        final List<String> collectionNames = List<String>.from(
          matchedAiItem['collections'] ?? [],
        );

        final updatedScreenshot = screenshot.copyWith(
          title: matchedAiItem['title'] ?? screenshot.title,
          description: matchedAiItem['desc'] ?? screenshot.description,
          tags: List<String>.from(matchedAiItem['tags'] ?? []),
          aiProcessed: true,
          aiMetadata: aiMetaData,
        );

        if (collectionNames.isNotEmpty) {
          CollectionUtils.storeSuggestedCollections(
            response,
            updatedScreenshot.id,
            collectionNames,
          );
        }

        updatedScreenshots.add(updatedScreenshot);
        if (matchedAiItemIndex != null) {
          availableResponses.removeAt(matchedAiItemIndex);
        }
      } else {
        updatedScreenshots.add(screenshot);
      }
    }

    return updatedScreenshots;
  }

  void _handleResponseError(Map<String, dynamic> response) {
    // Check if this is a parsing error
    if (response.containsKey('parsing_error') &&
        response['parsing_error'] == true) {
      // For parsing errors, always show the message and terminate processing
      if (config.showMessage != null) {
        config.showMessage!(
          message:
              'AI Processing Error: ${response['error'] ?? 'Failed to parse AI response'}',
        );
      }
      _processingTerminated = true;
      return;
    }

    final result = AIErrorHandler.handleResponseError(
      response,
      showMessage: config.showMessage,
      isCancelled: () => isCancelled,
      cancelProcessing: cancel,
      apiKeyErrorShown: _apiKeyErrorShown,
      processingTerminated: _processingTerminated,
      networkErrorCount: _networkErrorCount,
      setApiKeyErrorShown: (value) => _apiKeyErrorShown = value,
      setProcessingTerminated: (value) => _processingTerminated = value,
      setNetworkErrorCount: (value) => _networkErrorCount = value,
    );

    // Update state based on error handling result
    if (result.shouldTerminate) {
      _processingTerminated = true;
    }
  }
}
