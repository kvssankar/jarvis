import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';
import 'package:shots_studio/utils/ai_language_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class AISettingsScreen extends StatefulWidget {
  final String currentModelName;
  final Function(String) onModelChanged;

  const AISettingsScreen({
    super.key,
    required this.currentModelName,
    required this.onModelChanged,
  });

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  Map<String, bool> _providerStates = {};
  late String _selectedModelName;
  String? _gemmaModelPath;
  bool _isLoadingGemmaModel = false;
  String _selectedLanguage = AILanguageConfig.defaultLanguageKey;
  bool _gemmaUseCPU = true; // CPU by default

  @override
  void initState() {
    super.initState();
    _selectedModelName = widget.currentModelName;
    _loadProviderSettings();

    // Track AI settings screen access
    AnalyticsService().logScreenView('ai_settings_screen');
    AnalyticsService().logFeatureUsed('ai_settings_accessed');
  }

  Future<void> _loadProviderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        for (final provider in AIProviderConfig.getProviders()) {
          final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
          if (prefKey != null) {
            if (provider == 'gemma') {
              // For Gemma, only enable if model file exists
              final modelPath = prefs.getString('gemma_model_path');
              _providerStates[provider] =
                  (modelPath != null && modelPath.isNotEmpty)
                      ? (prefs.getBool(prefKey) ?? false)
                      : false;
            } else {
              _providerStates[provider] =
                  prefs.getBool(prefKey) ?? (provider == 'gemini');
            }
          }
        }
        // Load saved Gemma model path
        _gemmaModelPath = prefs.getString('gemma_model_path');
        // Load saved AI output language
        _selectedLanguage =
            prefs.getString(AILanguageConfig.prefKey) ??
            AILanguageConfig.defaultLanguageKey;
        // Load saved Gemma CPU/GPU preference (CPU by default)
        _gemmaUseCPU = prefs.getBool('gemma_use_cpu') ?? true;
      });
    }
  }

  Future<void> _pickGemmaModelFile() async {
    try {
      setState(() {
        _isLoadingGemmaModel = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin', 'gguf'],
        dialogTitle: 'Select Gemma Model File',
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final sourceFile = File(sourcePath);

        if (await sourceFile.exists()) {
          // Copy the file to app's documents directory to ensure persistence
          final appDocDir = await getApplicationDocumentsDirectory();
          final modelsDir = Directory('${appDocDir.path}/gemma_models');

          // Create models directory if it doesn't exist
          if (!await modelsDir.exists()) {
            await modelsDir.create(recursive: true);
          }

          // Create destination file with original name
          final originalFileName = result.files.single.name;
          final destinationFile = File('${modelsDir.path}/$originalFileName');

          // Copy the file
          await sourceFile.copy(destinationFile.path);

          // Verify the copied file exists
          if (await destinationFile.exists()) {
            // Save the permanent model path
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gemma_model_path', destinationFile.path);

            setState(() {
              _gemmaModelPath = destinationFile.path;
            });

            // Track analytics
            AnalyticsService().logFeatureUsed('gemma_model_file_selected');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gemma model file copied: $originalFileName'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Failed to copy model file to permanent location');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting model file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingGemmaModel = false;
      });
    }
  }

  Future<void> _clearGemmaModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentModelPath = prefs.getString('gemma_model_path');

      // Delete the model file if it exists in our app directory
      if (currentModelPath != null) {
        final modelFile = File(currentModelPath);
        if (await modelFile.exists()) {
          await modelFile.delete();
        }
      }

      await prefs.remove('gemma_model_path');

      setState(() {
        _gemmaModelPath = null;
        // Automatically disable Gemma provider when model is cleared
        _providerStates['gemma'] = false;
      });

      // Save the disabled state
      await _saveProviderSetting('gemma', false);

      // If current model is Gemma, switch to first available model
      if (_selectedModelName.toLowerCase().contains('gemma')) {
        final availableModels = _getAvailableModels();
        if (availableModels.isNotEmpty) {
          final newModel = availableModels.first;
          setState(() {
            _selectedModelName = newModel;
          });
          widget.onModelChanged(newModel);
        }
      }

      AnalyticsService().logFeatureUsed('gemma_model_cleared');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemma model cleared and provider disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProviderSetting(String provider, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
    if (prefKey != null) {
      await prefs.setBool(prefKey, enabled);
    }
  }

  Future<void> _saveLanguageSetting(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AILanguageConfig.prefKey, languageCode);

    // Track language change in analytics
    AnalyticsService().logFeatureUsed(
      'ai_output_language_changed_to_$languageCode',
    );
  }

  Future<void> _saveGemmaCpuGpuSetting(bool useCPU) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gemma_use_cpu', useCPU);

    // Track CPU/GPU preference change in analytics
    AnalyticsService().logFeatureUsed(
      'gemma_backend_changed_to_${useCPU ? 'cpu' : 'gpu'}',
    );
  }

  List<String> _getAvailableModels() {
    List<String> availableModels = [];

    for (final provider in AIProviderConfig.getProviders()) {
      if (_providerStates[provider] == true) {
        availableModels.addAll(AIProviderConfig.getModelsForProvider(provider));
      }
    }

    // If no providers are enabled, show 'none' models
    if (availableModels.isEmpty) {
      availableModels.addAll(AIProviderConfig.getModelsForProvider('none'));
    }

    return availableModels;
  }

  Future<void> _showGemmaWarningDialog(String provider) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Warning: Local AI Model'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Important Notice:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• App may crash during model initialization or inference'),
              Text('• Requires at least 8GB of RAM to work properly'),
              Text('• Make sure your device is capable of running this model'),
              SizedBox(height: 12),
              Text(
                'This feature may have limitations and could produce unexpected results. Use this feature at your own discretion.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                backgroundColor:
                    Theme.of(context).colorScheme.tertiaryContainer,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _providerStates[provider] = true;
      });

      await _saveProviderSetting(provider, true);

      // Track provider toggle in analytics
      AnalyticsService().logFeatureUsed(
        'ai_provider_${provider}_enabled_with_warning',
      );
    }
  }

  void _onProviderToggle(String provider, bool enabled) async {
    // For Gemma provider, check if model file is available before enabling
    if (provider == 'gemma' &&
        enabled &&
        (_gemmaModelPath == null || _gemmaModelPath!.isEmpty)) {
      // Show a message that model file is required
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a Gemma model file first'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show warning dialog when enabling Gemma
    if (provider == 'gemma' && enabled) {
      await _showGemmaWarningDialog(provider);
      return;
    }

    setState(() {
      _providerStates[provider] = enabled;
    });

    await _saveProviderSetting(provider, enabled);

    // Track provider toggle in analytics
    AnalyticsService().logFeatureUsed(
      'ai_provider_${provider}_${enabled ? 'enabled' : 'disabled'}',
    );

    // If the current model belongs to the disabled provider, switch to first available model
    final availableModels = _getAvailableModels();
    if (availableModels.isNotEmpty &&
        !availableModels.contains(_selectedModelName)) {
      final newModel = availableModels.first;
      setState(() {
        _selectedModelName = newModel;
      });
      widget.onModelChanged(newModel);

      AnalyticsService().logFeatureUsed(
        'ai_model_auto_switched_due_to_provider_disable',
      );
    }
  }

  Widget _buildProviderToggle(String provider, ThemeData theme) {
    final isEnabled = _providerStates[provider] ?? false;
    final models = AIProviderConfig.getModelsForProvider(provider);

    // For Gemma provider, check if model file is available
    bool canToggle = true;
    bool forceDisabled = false;
    String? disabledReason;

    if (provider == 'gemma') {
      canToggle = _gemmaModelPath != null && _gemmaModelPath!.isNotEmpty;
      if (!canToggle) {
        forceDisabled = true;
        disabledReason = 'Select a model file first';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          forceDisabled
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(
                                0.6,
                              )
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    disabledReason ?? models.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          forceDisabled
                              ? theme.colorScheme.error.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: forceDisabled ? false : isEnabled,
              onChanged:
                  canToggle
                      ? (value) => _onProviderToggle(provider, value)
                      : null,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGemmaModelSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.android, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'LOCAL GEMMA MODEL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a local Gemma model file (.bin or .task) to use for on-device AI processing.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.download,
                        color: theme.colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Download Model',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommended: Gemma 3N E2B IT INT4',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      const url =
                          'https://www.kaggle.com/models/google/gemma-3n/tfLite/gemma-3n-e2b-it-int4';
                      try {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // Fallback to copying to clipboard if URL can't be launched
                          await Clipboard.setData(
                            const ClipboardData(text: url),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open browser. Link copied to clipboard!',
                                ),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        // Fallback to copying to clipboard on error
                        await Clipboard.setData(const ClipboardData(text: url));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Error opening link. URL copied to clipboard!',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: theme.colorScheme.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'kaggle.com/models/google/gemma-3n/tfLite/gemma-3n-e2b-it-int4',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_gemmaModelPath != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Model:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _gemmaModelPath!.split('/').last,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CPU/GPU Performance Toggle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_applications,
                          color: theme.colorScheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Processing Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the processing mode for the local model:',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _gemmaUseCPU = true;
                              });
                              _saveGemmaCpuGpuSetting(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _gemmaUseCPU
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      _gemmaUseCPU
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                              .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.battery_saver,
                                    color:
                                        _gemmaUseCPU
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'CPU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Optimized for lower resource usage.',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          _gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                                  .withOpacity(0.8)
                                              : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _gemmaUseCPU = false;
                              });
                              _saveGemmaCpuGpuSetting(false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    !_gemmaUseCPU
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      !_gemmaUseCPU
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                              .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.memory,
                                    color:
                                        !_gemmaUseCPU
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                    size: 16,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GPU',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          !_gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Designed for higher performance tasks.',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          !_gemmaUseCPU
                                              ? theme.colorScheme.onPrimary
                                                  .withOpacity(0.8)
                                              : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isLoadingGemmaModel ? null : _pickGemmaModelFile,
                      icon:
                          _isLoadingGemmaModel
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                              : const Icon(Icons.folder_open),
                      label: Text(
                        _isLoadingGemmaModel ? 'Loading...' : 'Change Model',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isLoadingGemmaModel ? null : _clearGemmaModel,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingGemmaModel ? null : _pickGemmaModelFile,
                  icon:
                      _isLoadingGemmaModel
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSecondary,
                            ),
                          )
                          : const Icon(Icons.folder_open),
                  label: Text(
                    _isLoadingGemmaModel ? 'Loading...' : 'Select Model File',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI OUTPUT LANGUAGE (BETA)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the language for AI-generated descriptions. Other fields (title, tags) will remain in English for consistency.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onChanged: (String? newValue) async {
                    if (newValue != null && newValue != _selectedLanguage) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                      await _saveLanguageSetting(newValue);
                    }
                  },
                  items:
                      AILanguageConfig.getAllLanguageCodes()
                          .map<DropdownMenuItem<String>>((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AILanguageConfig.getLanguageName(code),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                ),
              ),
            ),
            if (_selectedLanguage != AILanguageConfig.defaultLanguageKey) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Selected: ${AILanguageConfig.getLanguageName(_selectedLanguage)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current model info
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Model: $_selectedModelName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // AI Output Settings Section (moved to top)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'AI Output Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLanguageSection(theme),

            // AI Providers Header section
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Providers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toggle AI providers on or off. Enabled providers will show their models in the main settings dropdown.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Provider toggles
            ...AIProviderConfig.getProviders().map(
              (provider) => _buildProviderToggle(provider, theme),
            ),

            // Local Models Section
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Local Models',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildGemmaModelSection(theme),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
