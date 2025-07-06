import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/services/api_validation_service.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/theme_manager.dart';

class SettingsSection extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final Key? apiKeyFieldKey;
  final bool? currentAutoProcessEnabled;
  final Function(bool)? onAutoProcessEnabledChanged;
  final bool? currentAmoledModeEnabled;
  final Function(bool)? onAmoledModeChanged;
  final String? currentSelectedTheme;
  final Function(String)? onThemeChanged;

  const SettingsSection({
    super.key,
    this.currentApiKey,
    required this.currentModelName,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    this.apiKeyFieldKey,
    this.currentAutoProcessEnabled,
    this.onAutoProcessEnabledChanged,
    this.currentAmoledModeEnabled,
    this.onAmoledModeChanged,
    this.currentSelectedTheme,
    this.onThemeChanged,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late TextEditingController _apiKeyController;
  late String _selectedModelName;
  final FocusNode _apiKeyFocusNode = FocusNode();
  bool _autoProcessEnabled = true;
  bool _amoledModeEnabled = false;
  String _selectedTheme = 'Dynamic Theme';
  bool _isValidatingApiKey = false;
  bool? _apiKeyValid;

  static const String _apiKeyPrefKey = 'apiKey';
  static const String _modelNamePrefKey = 'modelName';
  static const String _autoProcessEnabledPrefKey = 'auto_process_enabled';
  static const String _amoledModeEnabledPrefKey = 'amoled_mode_enabled';

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

    // Initialize AMOLED mode state
    if (widget.currentAmoledModeEnabled != null) {
      _amoledModeEnabled = widget.currentAmoledModeEnabled!;
    } else {
      _loadAmoledModeEnabledPref();
    }

    // Initialize theme selection
    if (widget.currentSelectedTheme != null) {
      _selectedTheme = widget.currentSelectedTheme!;
    } else {
      _loadThemePref();
    }

    // Request focus on the API key field when it's empty
    if (widget.currentApiKey?.isEmpty ?? true) {
      // Request focus on the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apiKeyFocusNode.requestFocus();
      });
    }

    // Load API key validation state
    _loadApiKeyValidationState();
  }

  void _loadAutoProcessEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoProcessEnabled = prefs.getBool(_autoProcessEnabledPrefKey) ?? true;
    });
  }

  void _loadAmoledModeEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _amoledModeEnabled = prefs.getBool(_amoledModeEnabledPrefKey) ?? false;
    });
  }

  void _loadThemePref() async {
    final selectedTheme = await ThemeManager.getSelectedTheme();
    setState(() {
      _selectedTheme = selectedTheme;
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
        // Reset validation state when API key changes
        _apiKeyValid = null;
        _loadApiKeyValidationState();
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
    if (widget.currentAmoledModeEnabled != oldWidget.currentAmoledModeEnabled &&
        widget.currentAmoledModeEnabled != null) {
      _amoledModeEnabled = widget.currentAmoledModeEnabled!;
    }
    if (widget.currentSelectedTheme != oldWidget.currentSelectedTheme) {
      _selectedTheme = widget.currentSelectedTheme ?? 'Dynamic Theme';
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

  Future<void> _saveAmoledModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledModeEnabledPrefKey, value);
  }

  Future<void> _saveSelectedTheme(String value) async {
    await ThemeManager.setSelectedTheme(value);
  }

  Future<void> _validateApiKey() async {
    if (_isValidatingApiKey) return;

    setState(() {
      _isValidatingApiKey = true;
      _apiKeyValid = null;
    });

    try {
      final result = await ApiValidationService().validateApiKey(
        apiKey: _apiKeyController.text,
        modelName: _selectedModelName,
        context: context,
        showMessages: true,
        forceValidation: true,
      );

      setState(() {
        _apiKeyValid = result.isValid;
        _isValidatingApiKey = false;
      });

      // Track validation in analytics
      AnalyticsService().logFeatureUsed('api_key_validation');
      if (result.isValid) {
        AnalyticsService().logFeatureUsed('api_key_validation_success');
      } else {
        AnalyticsService().logFeatureUsed('api_key_validation_failed');
      }
    } catch (e) {
      setState(() {
        _isValidatingApiKey = false;
        _apiKeyValid = false;
      });
      SnackbarService().showError(
        context,
        'Validation failed: ${e.toString()}',
      );
    }
  }

  Future<void> _loadApiKeyValidationState() async {
    if (_apiKeyController.text.isNotEmpty) {
      final isValid = await ApiValidationService().isApiKeyValid(
        apiKey: _apiKeyController.text,
        modelName: _selectedModelName,
      );
      setState(() {
        _apiKeyValid = isValid;
      });
    }
  }

  String _getApiKeyHelperText() {
    if (_apiKeyController.text.isEmpty) {
      return 'Required for AI features';
    } else if (_apiKeyValid == true) {
      return 'API key is valid';
    } else if (_apiKeyValid == false) {
      return 'API key validation failed';
    } else {
      return 'API key is set (not validated)';
    }
  }

  Color _getApiKeyHelperColor(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return theme.colorScheme.error.withOpacity(0.7);
    } else if (_apiKeyValid == true) {
      return theme.colorScheme.primary;
    } else if (_apiKeyValid == false) {
      return theme.colorScheme.error;
    } else {
      return theme.colorScheme.onSecondaryContainer;
    }
  }

  Color _getApiKeyBorderColor(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return theme.colorScheme.error.withOpacity(0.5);
    } else if (_apiKeyValid == false) {
      return theme.colorScheme.error.withOpacity(0.5);
    } else {
      return theme.colorScheme.outline;
    }
  }

  Widget _getApiKeySuffixIcon(ThemeData theme) {
    if (_apiKeyController.text.isEmpty) {
      return Icon(Icons.key_off, color: theme.colorScheme.error, size: 20);
    } else if (_apiKeyValid == true) {
      return Icon(Icons.verified, color: theme.colorScheme.primary, size: 20);
    } else if (_apiKeyValid == false) {
      return Icon(Icons.error, color: theme.colorScheme.error, size: 20);
    } else {
      return Icon(
        Icons.help_outline,
        color: theme.colorScheme.onSecondaryContainer,
        size: 20,
      );
    }
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Model',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _selectedModelName,
                      dropdownColor: theme.colorScheme.secondaryContainer,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      underline: SizedBox.shrink(),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedModelName = newValue;
                          });
                          widget.onModelChanged(newValue);
                          _saveModelName(newValue);

                          // Track model change in analytics
                          AnalyticsService().logFeatureUsed(
                            'setting_changed_ai_model',
                          );
                          AnalyticsService().logFeatureAdopted(
                            'model_$newValue',
                          );
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'API Key',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
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
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: widget.apiKeyFieldKey,
                controller: _apiKeyController,
                focusNode: _apiKeyFocusNode,
                autofocus: widget.currentApiKey?.isEmpty ?? true,
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                decoration: InputDecoration(
                  hintText: 'Enter Gemini API Key',
                  helperText: _getApiKeyHelperText(),
                  helperStyle: TextStyle(
                    color: _getApiKeyHelperColor(theme),
                    fontSize: 12,
                  ),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _getApiKeyBorderColor(theme),
                      width: _apiKeyController.text.isEmpty ? 2.0 : 1.0,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  suffixIcon: _getApiKeySuffixIcon(theme),
                ),
                obscureText: true,
                onChanged: (value) {
                  widget.onApiKeyChanged(value);
                  _saveApiKey(value);

                  // Track API key changes in analytics (only track if key was added or removed, not the actual key)
                  if (_apiKeyController.text.isEmpty && value.isNotEmpty) {
                    // API key was added
                    AnalyticsService().logFeatureUsed('api_key_added');
                    AnalyticsService().logFeatureAdopted(
                      'gemini_api_configured',
                    );
                  } else if (_apiKeyController.text.isNotEmpty &&
                      value.isEmpty) {
                    // API key was removed
                    AnalyticsService().logFeatureUsed('api_key_removed');
                  }

                  // Reset validation state when API key changes
                  setState(() {
                    _apiKeyValid = null;
                  });
                },
              ),
              // Validation button
              if (_apiKeyController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isValidatingApiKey ? null : _validateApiKey,
                      icon:
                          _isValidatingApiKey
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                              : Icon(
                                _apiKeyValid == true
                                    ? Icons.check_circle
                                    : Icons.security,
                                size: 16,
                              ),
                      label: Text(
                        _isValidatingApiKey
                            ? 'Validating...'
                            : _apiKeyValid == true
                            ? 'Valid'
                            : 'Validate API Key',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _apiKeyValid == true
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.secondaryContainer,
                        foregroundColor:
                            _apiKeyValid == true
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSecondaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
                      Expanded(
                        child: Text(
                          'How to get an API key:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
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
        SwitchListTile(
          secondary: Icon(
            Icons.nightlight_round,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'AMOLED Mode',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _amoledModeEnabled
                ? 'Dark theme optimized for AMOLED screens'
                : 'Default dark theme',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _amoledModeEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _amoledModeEnabled = value;
            });
            _saveAmoledModeEnabled(value);

            // Track settings change in analytics
            AnalyticsService().logFeatureUsed('setting_changed_amoled_mode');
            AnalyticsService().logFeatureAdopted(
              value ? 'amoled_mode_enabled' : 'amoled_mode_disabled',
            );

            if (widget.onAmoledModeChanged != null) {
              widget.onAmoledModeChanged!(value);
            }
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.palette, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Color',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: _selectedTheme,
                      dropdownColor: theme.colorScheme.secondaryContainer,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      underline: SizedBox.shrink(),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTheme = newValue;
                          });
                          widget.onThemeChanged?.call(newValue);
                          _saveSelectedTheme(newValue);

                          // Track theme change in analytics
                          AnalyticsService().logFeatureUsed(
                            'setting_changed_theme',
                          );
                          AnalyticsService().logFeatureAdopted(
                            'theme_${newValue.replaceAll(' ', '_').toLowerCase()}',
                          );
                        }
                      },
                      items:
                          ThemeManager.getAvailableThemes()
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: ThemeManager.getThemeColor(
                                            value,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        value,
                                        style: TextStyle(
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ],
                ),
              ),
            ],
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
