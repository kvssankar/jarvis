// AI Service Interface and Base Classes
import 'package:flutter/material.dart';
import 'package:shots_studio/models/screenshot_model.dart';

typedef ShowMessageCallback =
    void Function({
      required String message,
      Color? backgroundColor,
      Duration? duration,
    });

typedef BatchProcessedCallback =
    void Function(List<Screenshot> batch, Map<String, dynamic> result);

// Base configuration for AI operations
class AIConfig {
  final String apiKey;
  final String modelName;
  final int maxParallel;
  final int timeoutSeconds;
  final ShowMessageCallback? showMessage;

  const AIConfig({
    required this.apiKey,
    required this.modelName,
    this.maxParallel = 4,
    this.timeoutSeconds = 120,
    this.showMessage,
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
}
