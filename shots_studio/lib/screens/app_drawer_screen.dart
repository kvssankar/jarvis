import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shots_studio/widgets/app_drawer/index.dart';
import 'package:shots_studio/services/analytics_service.dart';

class AppDrawer extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;
  final bool? currentLimitEnabled;
  final Function(bool)? onLimitEnabledChanged;
  final bool? currentDevMode;
  final Function(bool)? onDevModeChanged;
  final bool? currentAutoProcessEnabled;
  final Function(bool)? onAutoProcessEnabledChanged;
  final bool? currentAnalyticsEnabled;
  final Function(bool)? onAnalyticsEnabledChanged;
  final Key? apiKeyFieldKey;
  final VoidCallback? onResetAiProcessing;

  const AppDrawer({
    super.key,
    this.currentApiKey,
    required this.currentModelName,
    required this.onApiKeyChanged,
    required this.onModelChanged,
    required this.currentLimit,
    required this.onLimitChanged,
    required this.currentMaxParallel,
    required this.onMaxParallelChanged,
    this.currentLimitEnabled,
    this.onLimitEnabledChanged,
    this.currentDevMode,
    this.onDevModeChanged,
    this.currentAutoProcessEnabled,
    this.onAutoProcessEnabledChanged,
    this.currentAnalyticsEnabled,
    this.onAnalyticsEnabledChanged,
    this.apiKeyFieldKey,
    this.onResetAiProcessing,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '...';
  int _aboutTapCount = 0;
  static const int _requiredTaps = 7;

  @override
  void initState() {
    super.initState();

    // Log analytics for app drawer view
    AnalyticsService().logScreenView('app_drawer_screen');
    AnalyticsService().logFeatureUsed('app_drawer');

    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _handleAboutTap() {
    setState(() {
      _aboutTapCount++;
      if (_aboutTapCount >= _requiredTaps) {
        // Enable dev mode when 7 taps reached
        if (widget.onDevModeChanged != null) {
          widget.onDevModeChanged!(true);
        }
        _aboutTapCount = 0; // Reset counter after unlocking

        // Log analytics for dev mode unlock
        AnalyticsService().logFeatureUsed('dev_mode_unlock');
        AnalyticsService().logFeatureAdopted('dev_mode');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Developer mode enabled!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (_aboutTapCount >= _requiredTaps - 2) {
        // Give subtle feedback when getting close
        HapticFeedback.lightImpact();
      }
    });
  }

  void _handleAboutLongPress() {
    if (widget.currentDevMode == true) {
      if (widget.onDevModeChanged != null) {
        widget.onDevModeChanged!(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Developer mode disabled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const AppDrawerHeader(),
            SettingsSection(
              currentApiKey: widget.currentApiKey,
              currentModelName: widget.currentModelName,
              onApiKeyChanged: widget.onApiKeyChanged,
              onModelChanged: widget.onModelChanged,
              apiKeyFieldKey: widget.apiKeyFieldKey,
              currentAutoProcessEnabled: widget.currentAutoProcessEnabled,
              onAutoProcessEnabledChanged: widget.onAutoProcessEnabledChanged,
            ),
            if (widget.currentDevMode == true) ...[
              AdvancedSettingsSection(
                currentLimit: widget.currentLimit,
                onLimitChanged: widget.onLimitChanged,
                currentMaxParallel: widget.currentMaxParallel,
                onMaxParallelChanged: widget.onMaxParallelChanged,
                currentLimitEnabled: widget.currentLimitEnabled,
                onLimitEnabledChanged: widget.onLimitEnabledChanged,
                currentDevMode: widget.currentDevMode,
                onDevModeChanged: widget.onDevModeChanged,
                currentAnalyticsEnabled: widget.currentAnalyticsEnabled,
                onAnalyticsEnabledChanged: widget.onAnalyticsEnabledChanged,
                onResetAiProcessing: widget.onResetAiProcessing,
              ),
              const PerformanceSection(),
            ],
            AboutSection(
              appVersion: _appVersion,
              onTap: _handleAboutTap,
              onLongPress: _handleAboutLongPress,
            ),
            const PrivacySection(),
          ],
        ),
      ),
    );
  }
}
