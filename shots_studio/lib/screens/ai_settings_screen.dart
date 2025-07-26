import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/utils/ai_provider_config.dart';

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
            _providerStates[provider] =
                prefs.getBool(prefKey) ?? (provider == 'gemini');
          }
        }
      });
    }
  }

  Future<void> _saveProviderSetting(String provider, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final prefKey = AIProviderConfig.getPrefKeyForProvider(provider);
    if (prefKey != null) {
      await prefs.setBool(prefKey, enabled);
    }
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

  void _onProviderToggle(String provider, bool enabled) async {
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
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    models.join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (value) => _onProviderToggle(provider, value),
              activeColor: theme.colorScheme.primary,
            ),
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
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Providers',
                  style: TextStyle(
                    fontSize: 24,
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

          // Current model info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

          // Provider toggles
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),
                ...AIProviderConfig.getProviders().map(
                  (provider) => _buildProviderToggle(provider, theme),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
