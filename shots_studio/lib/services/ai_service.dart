// AI Service Interface and Base Classes
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shots_studio/models/screenshot_model.dart';

typedef ShowMessageCallback =
    void Function({
      required String message,
      Color? backgroundColor,
      Duration? duration,
    });

typedef BatchProcessedCallback =
    void Function(List<Screenshot> batch, Map<String, dynamic> result);

// AI metadata for tracking processing information
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

// Base configuration for AI operations
class AIConfig {
  final String apiKey;
  final String modelName;
  final int maxParallel;
  final int timeoutSeconds;
  final ShowMessageCallback? showMessage;
  final Map<String, dynamic> providerSpecificConfig;

  const AIConfig({
    required this.apiKey,
    required this.modelName,
    this.maxParallel = 4,
    this.timeoutSeconds = 120,
    this.showMessage,
    this.providerSpecificConfig = const {},
  });
}

// Progress tracking for AI operations
class AIProgress {
  final int processedCount;
  final int totalCount;
  final bool isProcessing;
  final bool isCancelled;
  final String? currentOperation;

  const AIProgress({
    required this.processedCount,
    required this.totalCount,
    required this.isProcessing,
    this.isCancelled = false,
    this.currentOperation,
  });

  double get progress => totalCount > 0 ? processedCount / totalCount : 0.0;

  AIProgress copyWith({
    int? processedCount,
    int? totalCount,
    bool? isProcessing,
    bool? isCancelled,
    String? currentOperation,
  }) {
    return AIProgress(
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      isProcessing: isProcessing ?? this.isProcessing,
      isCancelled: isCancelled ?? this.isCancelled,
      currentOperation: currentOperation ?? this.currentOperation,
    );
  }
}

// Results for AI operations
class AIResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final bool cancelled;
  final Map<String, dynamic> metadata;

  const AIResult({
    required this.success,
    this.data,
    this.error,
    this.statusCode = 200,
    this.cancelled = false,
    this.metadata = const {},
  });

  factory AIResult.success(T data, {Map<String, dynamic>? metadata}) {
    return AIResult(success: true, data: data, metadata: metadata ?? {});
  }

  factory AIResult.error(String error, {int statusCode = 500}) {
    return AIResult(success: false, error: error, statusCode: statusCode);
  }

  factory AIResult.cancelled() {
    return const AIResult(success: false, cancelled: true, statusCode: 499);
  }
}

// Abstract API provider interface for different AI models
abstract class APIProvider {
  Future<Map<String, dynamic>> makeRequest(
    Map<String, dynamic> requestData,
    AIConfig config,
  );

  bool canHandleModel(String modelName);
}

// Gemini API provider implementation
class GeminiAPIProvider implements APIProvider {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  bool canHandleModel(String modelName) {
    return modelName.toLowerCase().contains('gemini');
  }

  @override
  Future<Map<String, dynamic>> makeRequest(
    Map<String, dynamic> requestData,
    AIConfig config,
  ) async {
    // Check if this is an empty request (all images already processed)
    if (requestData.containsKey('contents')) {
      final contents = requestData['contents'] as List;
      if (contents.length == 1 &&
          contents[0]['parts'] != null &&
          (contents[0]['parts'] as List).length == 1 &&
          (contents[0]['parts'][0]['text'] as String).contains(
            'No images to process',
          )) {
        return {
          'data': '[]', // Empty results
          'statusCode': 200,
          'skipped': true,
        };
      }
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
}

// Factory for API providers
class APIProviderFactory {
  static final List<APIProvider> _providers = [
    GeminiAPIProvider(),
    // Future providers can be added here:
    // GemmaProvider(),
    // LocalLlamaAPIProvider(),
  ];

  static APIProvider? getProvider(String modelName) {
    for (final provider in _providers) {
      if (provider.canHandleModel(modelName)) {
        return provider;
      }
    }
    return null;
  }
}

// Abstract base class for AI services
abstract class AIService {
  final AIConfig config;
  bool _isCancelled = false;

  AIService(this.config);

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    config.showMessage?.call(
      message: "AI processing cancelled.",
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 2),
    );
  }

  void reset() {
    _isCancelled = false;
  }

  // Protected method for making API requests that delegates to appropriate provider
  Future<Map<String, dynamic>> makeAPIRequest(
    Map<String, dynamic> requestData,
  ) async {
    if (isCancelled) {
      return {'error': 'Request cancelled by user', 'statusCode': 499};
    }

    final provider = APIProviderFactory.getProvider(config.modelName);
    if (provider == null) {
      return {
        'error': 'No API provider found for model: ${config.modelName}',
        'statusCode': 400,
      };
    }

    try {
      return await provider.makeRequest(requestData, config);
    } catch (e) {
      return {'error': 'Provider error: ${e.toString()}', 'statusCode': 500};
    }
  }
}
