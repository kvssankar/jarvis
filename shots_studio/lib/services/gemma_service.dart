import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GemmaService {
  static GemmaService? _instance;
  GemmaService._internal();

  factory GemmaService() {
    return _instance ??= GemmaService._internal();
  }

  static const String _modelPathPrefKey = 'gemma_model_path';
  static const String _isModelLoadedPrefKey = 'gemma_model_loaded';

  FlutterGemmaPlugin? _gemma;
  ModelFileManager? _modelManager;
  InferenceModel? _inferenceModel;
  InferenceModelSession? _session;

  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _currentModelPath;

  // Initialize Gemma plugin
  void initialize() {
    _gemma = FlutterGemmaPlugin.instance;
    _modelManager = _gemma!.modelManager;
  }

  // Load model from file path
  Future<bool> loadModel(String modelFilePath) async {
    if (_gemma == null) {
      initialize();
    }

    _isLoading = true;

    try {
      // Verify file exists
      final file = File(modelFilePath);
      if (!await file.exists()) {
        throw Exception('Model file does not exist: $modelFilePath');
      }

      // Close existing model if any
      if (_inferenceModel != null) {
        await _inferenceModel!.close();
        _inferenceModel = null;
      }

      // Delete any existing model from device storage
      await _modelManager!.deleteModel();

      // Set the model path - this tells flutter_gemma where to find the model
      await _modelManager!.setModelPath(modelFilePath);

      // Verify the model is properly set
      final isInstalled = await _modelManager!.isModelInstalled;
      if (!isInstalled) {
        throw Exception('Model not properly installed at path: $modelFilePath');
      }

      // Create inference model with multimodal support
      _inferenceModel = await _gemma!.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu, // Use GPU if available
        maxTokens: 4096,
        supportImage: true, // Enable multimodal support
        maxNumImages: 1,
      );

      _isModelLoaded = true;
      _currentModelPath = modelFilePath;

      // Save the model path and loaded state to preferences
      await _saveModelPath(modelFilePath);
      await _saveModelLoadedState(true);

      return true;
    } catch (e) {
      _isModelLoaded = false;
      _currentModelPath = null;
      await _saveModelLoadedState(false);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  // Check if model is ready and load from preferences if needed
  Future<bool> ensureModelReady() async {
    if (_isModelLoaded && _inferenceModel != null) {
      return true;
    }

    // Try to load from saved preferences
    return await loadModelFromPreferences();
  }

  // Load model from saved preferences
  Future<bool> loadModelFromPreferences() async {
    try {
      print("\n\n Loading model from preferences...");
      final prefs = await SharedPreferences.getInstance();
      final savedModelPath = prefs.getString(_modelPathPrefKey);
      print("Saved model path: $savedModelPath");

      if (savedModelPath != null && savedModelPath.isNotEmpty) {
        print('Checking if file exists: $savedModelPath');
        final file = File(savedModelPath);
        if (await file.exists()) {
          print('Loading model from saved path: $savedModelPath');
          return await loadModel(savedModelPath);
        } else {
          print('Saved model path does not exist: $savedModelPath');
          // Clean up invalid path
          await _removeModelPath();
          await _saveModelLoadedState(false);
        }
      } else {
        print('No model path found in preferences');
      }
    } catch (e) {
      print('Error loading model from preferences: $e');
      await _saveModelLoadedState(false);
    }
    print('No valid model found in preferences.');
    return false;
  }

  // Generate response with optional image
  Future<String> generateResponse({
    required String prompt,
    File? imageFile,
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isModelLoaded || _inferenceModel == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    _isGenerating = true;

    try {
      // Create a new session for this inference
      _session = await _inferenceModel!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      Message message;
      if (imageFile != null) {
        // Read image bytes for multimodal input
        final imageBytes = await imageFile.readAsBytes();
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        // Text-only message
        message = Message.text(text: prompt, isUser: true);
      }

      await _session!.addQueryChunk(message);

      // Get response (blocking call)
      final response = await _session!.getResponse();

      // Clean up session
      await _session!.close();
      _session = null;

      return response;
    } catch (e) {
      rethrow;
    } finally {
      _isGenerating = false;
    }
  }

  // Generate streaming response
  Future<Stream<String>> generateResponseStream({
    required String prompt,
    File? imageFile,
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isModelLoaded || _inferenceModel == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    _isGenerating = true;

    try {
      // Create a new session for streaming
      _session = await _inferenceModel!.createSession(
        temperature: temperature,
        randomSeed: randomSeed,
        topK: topK,
      );

      Message message;
      if (imageFile != null) {
        final imageBytes = await imageFile.readAsBytes();
        message = Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        );
      } else {
        message = Message.text(text: prompt, isUser: true);
      }

      await _session!.addQueryChunk(message);

      // Return the streaming response
      return _session!.getResponseAsync();
    } catch (e) {
      _isGenerating = false;
      rethrow;
    }
  }

  // Save model path to preferences
  Future<void> _saveModelPath(String modelPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modelPathPrefKey, modelPath);
    } catch (e) {
      print('Error saving model path: $e');
    }
  }

  // Save model loaded state
  Future<void> _saveModelLoadedState(bool isLoaded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isModelLoadedPrefKey, isLoaded);
    } catch (e) {
      print('Error saving model loaded state: $e');
    }
  }

  // Remove model path from preferences
  Future<void> _removeModelPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_modelPathPrefKey);
      await prefs.remove(_isModelLoadedPrefKey);
    } catch (e) {
      print('Error removing model path: $e');
    }
  }

  // Check if a model file is available (without loading)
  Future<bool> isModelFileAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModelPath = prefs.getString(_modelPathPrefKey);

      if (savedModelPath != null && savedModelPath.isNotEmpty) {
        final file = File(savedModelPath);
        return await file.exists();
      }
    } catch (e) {
      print('Error checking model file availability: $e');
    }
    return false;
  }

  // Get saved model path
  Future<String?> getSavedModelPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_modelPathPrefKey);
    } catch (e) {
      print('Error getting saved model path: $e');
      return null;
    }
  }

  // Get model name from current path
  String? get modelName {
    if (_currentModelPath != null) {
      return _currentModelPath!.split('/').last;
    }
    return null;
  }

  // Check if model is available for use
  bool get isAvailable => _isModelLoaded && _inferenceModel != null;

  // Clear the loaded model and remove from preferences
  Future<void> clearModel() async {
    await _removeModelPath();
    dispose();
  }

  // Dispose all resources
  void dispose() {
    _session?.close();
    _inferenceModel?.close();
    _session = null;
    _inferenceModel = null;
    _gemma = null;
    _modelManager = null;
    _isModelLoaded = false;
    _isLoading = false;
    _isGenerating = false;
    _currentModelPath = null;
  }

  // Status getters
  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get currentModelPath => _currentModelPath;
}
