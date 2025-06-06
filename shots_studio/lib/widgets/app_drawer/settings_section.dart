import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics_service.dart';

class SettingsSection extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final Key? apiKeyFieldKey;
  final bool? currentAutoProcessEnabled;
  final Function(bool)? onAutoProcessEnabledChanged;

  const SettingsSection({
    super.key,
    this.currentApiKey,
    required this.currentModelName,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    this.apiKeyFieldKey,
    this.currentAutoProcessEnabled,
    this.onAutoProcessEnabledChanged,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late TextEditingController _apiKeyController;
  late String _selectedModelName;
  final FocusNode _apiKeyFocusNode = FocusNode();
  bool _autoProcessEnabled = true;

  static const String _apiKeyPrefKey = 'apiKey';
  static const String _modelNamePrefKey = 'modelName';
  static const String _autoProcessEnabledPrefKey = 'auto_process_enabled';

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.currentApiKey ?? '');
    _selectedModelName = widget.currentModelName;

    // Track when settings are viewed
    AnalyticsService().logScreenView('settings_section');
    AnalyticsService().logFeatureUsed('view_settings');

    // Initialize auto-processing state
    if (widget.currentAutoProcessEnabled != null) {
      _autoProcessEnabled = widget.currentAutoProcessEnabled!;
    } else {
      _loadAutoProcessEnabledPref();
    }

    // Request focus on the API key field when it's empty
    if (widget.currentApiKey?.isEmpty ?? true) {
      // Request focus on the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apiKeyFocusNode.requestFocus();
      });
    }
  }

  void _loadAutoProcessEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoProcessEnabled = prefs.getBool(_autoProcessEnabledPrefKey) ?? true;
    });
  }

  @override
  void didUpdateWidget(covariant SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentApiKey != oldWidget.currentApiKey) {
      if (_apiKeyController.text != (widget.currentApiKey ?? '')) {
        _apiKeyController.text = widget.currentApiKey ?? '';
        _apiKeyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _apiKeyController.text.length),
        );
      }
    }
    if (widget.currentModelName != oldWidget.currentModelName) {
      if (_selectedModelName != widget.currentModelName) {
        _selectedModelName = widget.currentModelName;
      }
    }
    if (widget.currentAutoProcessEnabled !=
            oldWidget.currentAutoProcessEnabled &&
        widget.currentAutoProcessEnabled != null) {
      _autoProcessEnabled = widget.currentAutoProcessEnabled!;
    }
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, value);
  }

  Future<void> _saveModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNamePrefKey, value);
  }

  Future<void> _saveAutoProcessEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoProcessEnabledPrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          title: Text(
            'Auto-Process Screenshots',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _autoProcessEnabled
                ? 'Screenshots will be automatically processed when added'
                : 'Manual processing only',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _autoProcessEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _autoProcessEnabled = value;
            });
            _saveAutoProcessEnabled(value);

            // Track settings change in analytics
            AnalyticsService().logFeatureUsed('setting_changed_auto_process');
            AnalyticsService().logFeatureAdopted(
              value ? 'auto_process_enabled' : 'auto_process_disabled',
            );

            if (widget.onAutoProcessEnabledChanged != null) {
              widget.onAutoProcessEnabledChanged!(value);
            }
          },
        ),
        ListTile(
          leading: Icon(
            Icons.auto_awesome_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'AI Model',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          trailing: DropdownButton<String>(
            value: _selectedModelName,
            dropdownColor: theme.colorScheme.secondaryContainer,
            icon: Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            underline: SizedBox.shrink(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedModelName = newValue;
                });
                widget.onModelChanged(newValue);
                _saveModelName(newValue);

                // Track model change in analytics
                AnalyticsService().logFeatureUsed('setting_changed_ai_model');
                AnalyticsService().logFeatureAdopted('model_$newValue');
              }
            },
            items:
                <String>[
                  'gemini-2.0-flash',
                  'gemini-2.5-flash-pro',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.vpn_key_outlined,
            color: theme.colorScheme.primary,
          ),
          trailing: IconButton(
            tooltip: "Get an API key",
            icon: Icon(
              Icons.help_outline,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            onPressed: () async {
              // Track when users seek API key help
              AnalyticsService().logFeatureUsed('api_key_help_clicked');

              final Uri url = Uri.parse(
                'https://aistudio.google.com/app/apikey',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          title: TextFormField(
            key: widget.apiKeyFieldKey,
            controller: _apiKeyController,
            focusNode: _apiKeyFocusNode,
            autofocus: widget.currentApiKey?.isEmpty ?? true,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'Enter Gemini API Key',
              helperText:
                  _apiKeyController.text.isEmpty
                      ? 'Required for AI features'
                      : 'API key is set',
              helperStyle: TextStyle(
                color:
                    _apiKeyController.text.isEmpty
                        ? theme.colorScheme.error.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 12,
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color:
                      _apiKeyController.text.isEmpty
                          ? theme.colorScheme.error.withOpacity(0.5)
                          : theme.colorScheme.outline,
                  width: _apiKeyController.text.isEmpty ? 2.0 : 1.0,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ),
              ),
              suffixIcon:
                  _apiKeyController.text.isEmpty
                      ? Icon(
                        Icons.key_off,
                        color: theme.colorScheme.error,
                        size: 20,
                      )
                      : Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
            ),
            obscureText: true,
            onChanged: (value) {
              widget.onApiKeyChanged(value);
              _saveApiKey(value);

              // Track API key changes in analytics (only track if key was added or removed, not the actual key)
              if (_apiKeyController.text.isEmpty && value.isNotEmpty) {
                // API key was added
                AnalyticsService().logFeatureUsed('api_key_added');
                AnalyticsService().logFeatureAdopted('gemini_api_configured');
              } else if (_apiKeyController.text.isNotEmpty && value.isEmpty) {
                // API key was removed
                AnalyticsService().logFeatureUsed('api_key_removed');
              }

              setState(() {}); // Refresh to update the suffix icon
            },
          ),
        ),

        // Add a helper note about getting an API key
        if (_apiKeyController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'How to get an API key:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Go to Google AI Studio website',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '2. Create or log in to your account',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '3. Navigate to API Keys section',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '4. Create a new key and paste it here',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }
}
