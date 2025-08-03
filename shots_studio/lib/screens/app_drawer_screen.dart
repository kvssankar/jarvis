import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shots_studio/widgets/app_drawer/index.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

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
  final bool? currentBetaTestingEnabled;
  final Function(bool)? onBetaTestingEnabledChanged;
  final bool? currentAmoledModeEnabled;
  final Function(bool)? onAmoledModeChanged;
  final String? currentSelectedTheme;
  final Function(String)? onThemeChanged;
  final Key? apiKeyFieldKey;
  final VoidCallback? onResetAiProcessing;
  final Function(Locale)? onLocaleChanged;

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
    this.currentBetaTestingEnabled,
    this.onBetaTestingEnabledChanged,
    this.currentAmoledModeEnabled,
    this.onAmoledModeChanged,
    this.currentSelectedTheme,
    this.onThemeChanged,
    this.apiKeyFieldKey,
    this.onResetAiProcessing,
    this.onLocaleChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '...';

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
    // No longer needed - developer mode is now always accessible
  }

  void _handleAboutLongPress() {
    if (widget.currentDevMode == true) {
      if (widget.onDevModeChanged != null) {
        widget.onDevModeChanged!(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.developerModeDisabled ??
                  'Advanced settings disabled',
            ),
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
              currentAmoledModeEnabled: widget.currentAmoledModeEnabled,
              onAmoledModeChanged: widget.onAmoledModeChanged,
              currentSelectedTheme: widget.currentSelectedTheme,
              onThemeChanged: widget.onThemeChanged,
              currentDevMode: widget.currentDevMode,
              onDevModeChanged: widget.onDevModeChanged,
              onLocaleChanged: widget.onLocaleChanged,
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
                currentBetaTestingEnabled: widget.currentBetaTestingEnabled,
                onBetaTestingEnabledChanged: widget.onBetaTestingEnabledChanged,
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
