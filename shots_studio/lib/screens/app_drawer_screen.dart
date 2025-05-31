import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/widgets/app_drawer/index.dart';

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
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = '...';
  int _aboutTapCount = 0;
  bool _showAdvancedSettings = false;
  static const int _requiredTaps = 7;
  static const String _advancedSettingsKey = 'show_advanced_settings';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadAdvancedSettingsState();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _loadAdvancedSettingsState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAdvancedSettings = prefs.getBool(_advancedSettingsKey) ?? false;
    });
  }

  Future<void> _saveAdvancedSettingsState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_advancedSettingsKey, _showAdvancedSettings);
  }

  void _handleAboutTap() {
    setState(() {
      _aboutTapCount++;
      if (_aboutTapCount >= _requiredTaps) {
        _showAdvancedSettings = true;
        _aboutTapCount = 0; // Reset counter after unlocking
        _saveAdvancedSettingsState(); // Save the new state
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advanced settings unlocked!'),
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
    if (_showAdvancedSettings) {
      setState(() {
        _showAdvancedSettings = false;
        _saveAdvancedSettingsState();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advanced settings hidden'),
            duration: Duration(seconds: 2),
          ),
        );
      });
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
            ),
            if (_showAdvancedSettings)
              AdvancedSettingsSection(
                currentLimit: widget.currentLimit,
                onLimitChanged: widget.onLimitChanged,
                currentMaxParallel: widget.currentMaxParallel,
                onMaxParallelChanged: widget.onMaxParallelChanged,
                currentLimitEnabled: widget.currentLimitEnabled,
                onLimitEnabledChanged: widget.onLimitEnabledChanged,
              ),
            const PerformanceSection(),
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
