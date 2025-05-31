// Screenshot Analysis Service
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/models/gemini_model.dart';
import 'package:shots_studio/services/ai_service.dart';

class ScreenshotAnalysisService extends AIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  ScreenshotAnalysisService(super.config);

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
      [{filename: '', title: '', desc: '', tags: [], collections: [], other: []}, ...]
      
      The "collections" field should contain names of collections that match the image content.
    """;

    return basePrompt;
  }

  Future<Map<String, String>> _convertImageToBase64(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception("Image file not found: $imagePath");
    }
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    String mimeType = 'image/png';
    if (imagePath.toLowerCase().endsWith('.jpg') ||
        imagePath.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    }
    return {'mime_type': mimeType, 'data': encoded};
  }

  Map<String, String> _bytesToBase64(Uint8List bytes, {String? fileName}) {
    final encoded = base64Encode(bytes);
    String mimeType = 'image/png';
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
      {'text': _getAnalysisPrompt(autoAddCollections: autoAddCollections)},
    ];

    for (var image in images) {
      String imageIdentifier = image.id;
      Map<String, String> imageData;

      if (image.path != null && image.path!.isNotEmpty) {
        contentParts.add({'text': '\\nAnalyzing image: $imageIdentifier'});
        imageData = await _convertImageToBase64(image.path!);
        try {
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error adding path-based image data for ${image.id}: $e");
        }
      } else if (image.bytes != null) {
        contentParts.add({'text': '\\nAnalyzing image: $imageIdentifier'});
        imageData = _bytesToBase64(image.bytes!, fileName: image.path);
        try {
          contentParts.add({'inline_data': imageData});
        } catch (e) {
          print("Error adding byte-based image data for ${image.id}: $e");
        }
      } else {
        print("Warning: Screenshot with id ${image.id} has no path or bytes.");
        continue;
      }
    }

    return {
      'contents': [
        {'parts': contentParts},
      ],
    };
  }

  Future<Map<String, dynamic>> _makeAPIRequest(
    Map<String, dynamic> requestData,
  ) async {
    if (isCancelled) {
      return {'error': 'Request cancelled by user', 'statusCode': 499};
    }

    final url = Uri.parse(
      '$_baseUrl/${config.modelName}:generateContent?key=${config.apiKey}',
    );

    final requestBody = jsonEncode(requestData);
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http
          .post(url, headers: headers, body: requestBody)
          .timeout(Duration(seconds: config.timeoutSeconds));

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
      return {'error': 'Network error: ${e.message}', 'statusCode': 503};
    } on TimeoutException catch (_) {
      return {'error': 'Request timed out', 'statusCode': 408};
    } catch (e) {
      return {'error': 'Unexpected error: ${e.toString()}', 'statusCode': 500};
    }
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
          batch,
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
          finalResults['processedCount'] =
              (finalResults['processedCount'] as int) + batch.length;
          onBatchProcessed(batch, result);
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
      _handleResponseError(response);
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
          try {
            parsedResponse = jsonDecode(responseText);
          } catch (e) {
            return screenshots;
          }
        }
      } else {
        return screenshots;
      }

      if (parsedResponse.isEmpty) return screenshots;

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

  List<Screenshot> _updateSingleScreenshot(
    Screenshot screenshot,
    Map<String, dynamic> item,
    AiMetaData aiMetaData,
    Map<String, dynamic> response,
  ) {
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

    if (collectionNames.isNotEmpty) {
      _storeSuggestedCollections(
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

        final updatedScreenshot = Screenshot(
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
          _storeSuggestedCollections(
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

  void _storeSuggestedCollections(
    Map<String, dynamic> response,
    String screenshotId,
    List<String> collectionNames,
  ) {
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
      suggestedCollections[screenshotId] = collectionNames;
      response['suggestedCollections'] = suggestedCollections;
    } catch (e) {
      print('Error storing collection suggestions: $e');
    }
  }

  void _handleResponseError(Map<String, dynamic> response) {
    if (response['error'] != null &&
        response['error'].toString().contains('API key not valid')) {
      config.showMessage?.call(
        message: 'Invalid API key provided. Please check your API key.',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } else if (response['error'] != null &&
        response['error'].toString().contains('Network error')) {
      config.showMessage?.call(
        message:
            'Network issue detected. Please check your internet connection and try again.',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      );
    } else {
      config.showMessage?.call(
        message:
            'No data found in response or error occurred: ${response['error']}',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
