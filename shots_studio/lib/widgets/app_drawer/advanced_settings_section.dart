import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
// import 'package:shots_studio/screens/debug_notifications_screen.dart'; // Uncomment for debugging
import '../../l10n/app_localizations.dart';

class AdvancedSettingsSection extends StatefulWidget {
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;
  final bool? currentLimitEnabled;
  final Function(bool)? onLimitEnabledChanged;
  final bool? currentDevMode;
  final Function(bool)? onDevModeChanged;
  final bool? currentAnalyticsEnabled;
  final Function(bool)? onAnalyticsEnabledChanged;
  final bool? currentServerMessagesEnabled;
  final Function(bool)? onServerMessagesEnabledChanged;
  final bool? currentBetaTestingEnabled;
  final Function(bool)? onBetaTestingEnabledChanged;
  final VoidCallback? onResetAiProcessing;

  const AdvancedSettingsSection({
    super.key,
    required this.currentLimit,
    required this.onLimitChanged,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
    this.currentLimitEnabled,
    this.onLimitEnabledChanged,
    this.currentDevMode,
    this.onDevModeChanged,
    this.currentAnalyticsEnabled,
    this.onAnalyticsEnabledChanged,
    this.currentServerMessagesEnabled,
    this.onServerMessagesEnabledChanged,
    this.currentBetaTestingEnabled,
    this.onBetaTestingEnabledChanged,
    this.onResetAiProcessing,
  });

  @override
  State<AdvancedSettingsSection> createState() =>
      _AdvancedSettingsSectionState();
}

class _AdvancedSettingsSectionState extends State<AdvancedSettingsSection> {
  late TextEditingController _limitController;
  late TextEditingController _maxParallelController;
  bool _isLimitEnabled = true;
  bool _analyticsEnabled =
      !kDebugMode; // Default to false in debug mode, true in production
  bool _serverMessagesEnabled = true;
  bool _betaTestingEnabled = false;

  static const String _limitPrefKey = 'limit';
  static const String _maxParallelPrefKey = 'maxParallel';
  static const String _limitEnabledPrefKey = 'limit_enabled';
  static const String _serverMessagesPrefKey = 'server_messages_enabled';
  static const String _betaTestingPrefKey = 'beta_testing_enabled';

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.currentLimit.toString(),
    );
    _maxParallelController = TextEditingController(
      text: widget.currentMaxParallel.toString(),
    );

    // Initialize with widget value if provided, otherwise load from prefs
    if (widget.currentLimitEnabled != null) {
      _isLimitEnabled = widget.currentLimitEnabled!;
    } else {
      _loadLimitEnabledPref();
    }

    // Initialize analytics consent state
    if (widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    } else {
      _loadAnalyticsEnabledPref();
    }

    // Initialize server messages state
    if (widget.currentServerMessagesEnabled != null) {
      _serverMessagesEnabled = widget.currentServerMessagesEnabled!;
    } else {
      _loadServerMessagesEnabledPref();
    }

    // Initialize beta testing state
    if (widget.currentBetaTestingEnabled != null) {
      _betaTestingEnabled = widget.currentBetaTestingEnabled!;
    } else {
      _loadBetaTestingEnabledPref();
    }
  }

  Future<void> _loadLimitEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLimitEnabled = prefs.getBool(_limitEnabledPrefKey) ?? true;
    });
  }

  void _loadAnalyticsEnabledPref() async {
    final analyticsService = AnalyticsService();
    setState(() {
      _analyticsEnabled = analyticsService.analyticsEnabled;
    });
  }

  Future<void> _loadServerMessagesEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverMessagesEnabled = prefs.getBool(_serverMessagesPrefKey) ?? true;
    });
  }

  Future<void> _loadBetaTestingEnabledPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _betaTestingEnabled = prefs.getBool(_betaTestingPrefKey) ?? false;
    });
  }

  @override
  void didUpdateWidget(covariant AdvancedSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentLimit != oldWidget.currentLimit) {
      if (_limitController.text != widget.currentLimit.toString()) {
        _limitController.text = widget.currentLimit.toString();
        _limitController.selection = TextSelection.fromPosition(
          TextPosition(offset: _limitController.text.length),
        );
      }
    }
    if (widget.currentMaxParallel != oldWidget.currentMaxParallel) {
      if (_maxParallelController.text != widget.currentMaxParallel.toString()) {
        _maxParallelController.text = widget.currentMaxParallel.toString();
        _maxParallelController.selection = TextSelection.fromPosition(
          TextPosition(offset: _maxParallelController.text.length),
        );
      }
    }
    if (widget.currentAnalyticsEnabled != oldWidget.currentAnalyticsEnabled &&
        widget.currentAnalyticsEnabled != null) {
      _analyticsEnabled = widget.currentAnalyticsEnabled!;
    }
    if (widget.currentServerMessagesEnabled !=
            oldWidget.currentServerMessagesEnabled &&
        widget.currentServerMessagesEnabled != null) {
      _serverMessagesEnabled = widget.currentServerMessagesEnabled!;
    }
    if (widget.currentBetaTestingEnabled !=
            oldWidget.currentBetaTestingEnabled &&
        widget.currentBetaTestingEnabled != null) {
      _betaTestingEnabled = widget.currentBetaTestingEnabled!;
    }
  }

  Future<void> _saveLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_limitPrefKey, value);
  }

  Future<void> _saveMaxParallel(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxParallelPrefKey, value);
  }

  Future<void> _saveLimitEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_limitEnabledPrefKey, value);
  }

  Future<void> _saveAnalyticsEnabled(bool value) async {
    final analyticsService = AnalyticsService();
    if (value) {
      await analyticsService.enableAnalytics();
    } else {
      await analyticsService.disableAnalytics();
    }
  }

  Future<void> _saveServerMessagesEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serverMessagesPrefKey, value);
  }

  Future<void> _saveBetaTestingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_betaTestingPrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.colorScheme.outline),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            AppLocalizations.of(context)?.performanceMenu ??
                'Advanced Settings',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.filter_list, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.enableScreenshotLimit ??
                'Set a limit on screenshots loaded',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _isLimitEnabled
                ? 'Limited to ${widget.currentLimit} screenshots'
                : 'All screenshots will be loaded',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _isLimitEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _isLimitEnabled = value;
            });
            _saveLimitEnabled(value);

            // Track analytics for screenshot limit setting
            AnalyticsService().logFeatureUsed(
              'settings_screenshot_limit_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onLimitEnabledChanged != null) {
              widget.onLimitEnabledChanged!(value);
            }
          },
        ),
        if (_isLimitEnabled)
          ListTile(
            leading: const SizedBox(
              width: 24,
            ), // Keep alignment with icon above
            title: Text(
              'Screenshot Limit Value',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            subtitle: TextFormField(
              controller: _limitController,
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              decoration: InputDecoration(
                hintText: 'e.g., 50',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final intValue = int.tryParse(value);
                if (intValue != null) {
                  widget.onLimitChanged(intValue);
                  _saveLimit(intValue);

                  // Track analytics for screenshot limit value change
                  AnalyticsService().logFeatureUsed(
                    'settings_screenshot_limit_value_changed',
                  );
                }
              },
            ),
          ),
        ListTile(
          leading: Icon(Icons.sync_alt, color: theme.colorScheme.primary),
          title: Text(
            AppLocalizations.of(context)?.maxParallelAI ??
                'Max Parallel AI Processes',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: TextFormField(
            controller: _maxParallelController,
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            decoration: InputDecoration(
              hintText: 'e.g., 4',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                widget.onMaxParallelChanged(intValue);
                _saveMaxParallel(intValue);

                // Track analytics for max parallel processes change
                AnalyticsService().logFeatureUsed(
                  'settings_max_parallel_changed',
                );
              }
            },
          ),
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.analytics_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.analyticsAndTelemetry ??
                'Analytics & Telemetry',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _analyticsEnabled
                ? 'Help improve the app by sharing usage data'
                : 'Analytics and crash reporting disabled',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _analyticsEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _analyticsEnabled = value;
            });
            _saveAnalyticsEnabled(value);

            // Track analytics for analytics setting (meta-analytics!)
            AnalyticsService().logFeatureUsed(
              'settings_analytics_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onAnalyticsEnabledChanged != null) {
              widget.onAnalyticsEnabledChanged!(value);
            }
          },
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.notifications_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.serverMessages ?? 'Server Messages',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _serverMessagesEnabled
                ? 'Receive important updates and notifications'
                : 'Server messages and notifications disabled',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _serverMessagesEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _serverMessagesEnabled = value;
            });
            _saveServerMessagesEnabled(value);

            // Track analytics for server messages setting
            AnalyticsService().logFeatureUsed(
              'settings_server_messages_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onServerMessagesEnabledChanged != null) {
              widget.onServerMessagesEnabledChanged!(value);
            }
          },
        ),
        SwitchListTile(
          secondary: Icon(
            Icons.science_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)?.betaTesting ?? 'Beta Testing',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            _betaTestingEnabled
                ? 'Receive pre-release updates'
                : 'Only receive stable updates',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          value: _betaTestingEnabled,
          activeColor: theme.colorScheme.primary,
          onChanged: (bool value) {
            setState(() {
              _betaTestingEnabled = value;
            });
            _saveBetaTestingEnabled(value);

            // Track analytics for beta testing setting
            AnalyticsService().logFeatureUsed(
              'settings_beta_testing_${value ? 'enabled' : 'disabled'}',
            );

            if (widget.onBetaTestingEnabledChanged != null) {
              widget.onBetaTestingEnabledChanged!(value);
            }
          },
        ),
        // Reset AI Processing Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Track analytics for reset AI processing
                AnalyticsService().logFeatureUsed(
                  'settings_reset_ai_processing',
                );

                if (widget.onResetAiProcessing != null) {
                  widget.onResetAiProcessing!();
                }
              },
              icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              label: Text(
                'Reset AI Processing',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
        // Debug Notifications Button (only in debug mode)
        // Temporarily commented out - uncomment for debugging notification issues
        // if (kDebugMode)
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        //     child: SizedBox(
        //       width: double.infinity,
        //       child: OutlinedButton.icon(
        //         onPressed: () {
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (context) => const DebugNotificationsScreen(),
        //             ),
        //           );
        //         },
        //         icon: Icon(Icons.bug_report, color: theme.colorScheme.secondary),
        //         label: Text(
        //           'Debug Notifications',
        //           style: TextStyle(color: theme.colorScheme.secondary),
        //         ),
        //         style: OutlinedButton.styleFrom(
        //           side: BorderSide(color: theme.colorScheme.secondary),
        //           padding: const EdgeInsets.symmetric(vertical: 12.0),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(8.0),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _maxParallelController.dispose();
    super.dispose();
  }
}
