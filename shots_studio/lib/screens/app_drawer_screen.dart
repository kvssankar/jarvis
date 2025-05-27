import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shots_studio/screens/performance_monitor_screen.dart';

class AppDrawer extends StatefulWidget {
  final String? currentApiKey;
  final String currentModelName;
  final Function(String) onApiKeyChanged;
  final Function(String) onModelChanged;
  final int currentLimit;
  final Function(int) onLimitChanged;
  final int currentMaxParallel;
  final Function(int) onMaxParallelChanged;

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
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late TextEditingController _apiKeyController;
  late String _selectedModelName;
  late TextEditingController _limitController;
  late TextEditingController _maxParallelController;
  String _appVersion = '...';

  static const String _apiKeyPrefKey = 'apiKey';
  static const String _modelNamePrefKey = 'modelName';
  static const String _limitPrefKey = 'limit';
  static const String _maxParallelPrefKey = 'maxParallel';

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _selectedModelName = widget.currentModelName;
    _limitController = TextEditingController();
    _maxParallelController = TextEditingController();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text =
          prefs.getString(_apiKeyPrefKey) ?? widget.currentApiKey ?? '';
      _selectedModelName =
          prefs.getString(_modelNamePrefKey) ?? widget.currentModelName;
      _limitController.text =
          (prefs.getInt(_limitPrefKey) ?? widget.currentLimit).toString();
      _maxParallelController.text =
          (prefs.getInt(_maxParallelPrefKey) ?? widget.currentMaxParallel)
              .toString();

      // Initialize widget callbacks with loaded/default values
      widget.onApiKeyChanged(_apiKeyController.text);
      widget.onModelChanged(_selectedModelName);
      widget.onLimitChanged(
        int.tryParse(_limitController.text) ?? widget.currentLimit,
      );
      widget.onMaxParallelChanged(
        int.tryParse(_maxParallelController.text) ?? widget.currentMaxParallel,
      );
    });
  }

  Future<void> _saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefKey, value);
  }

  Future<void> _saveModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNamePrefKey, value);
  }

  Future<void> _saveLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_limitPrefKey, value);
  }

  Future<void> _saveMaxParallel(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxParallelPrefKey, value);
  }

  @override
  void didUpdateWidget(covariant AppDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentApiKey != oldWidget.currentApiKey) {
      if (_apiKeyController.text != (widget.currentApiKey ?? '')) {
        _apiKeyController.text = widget.currentApiKey ?? '';
        // Ensure the cursor is at the end of the text after programmatically changing it.
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
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? Colors.grey[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Shots Studio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Screenshot Manager',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.auto_awesome_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text('AI Model', style: TextStyle(color: Colors.white)),
              trailing: DropdownButton<String>(
                value: _selectedModelName, // Use state variable
                dropdownColor: theme.cardTheme.color ?? Colors.grey[900],
                icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                style: TextStyle(color: Colors.white),
                underline: SizedBox.shrink(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedModelName = newValue;
                    });
                    widget.onModelChanged(newValue);
                    _saveModelName(newValue);
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
                          style: TextStyle(color: Colors.white),
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
              title: TextFormField(
                controller: _apiKeyController, // Use controller
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'API Key',
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                obscureText: true, // Hide API key input
                onChanged: (value) {
                  // Modified
                  widget.onApiKeyChanged(value);
                  _saveApiKey(value); // Save on change
                },
              ),
            ),
            Divider(color: Colors.grey[700]),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Advanced Settings',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.filter_list,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Screenshot Limit',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: TextFormField(
                controller: _limitController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., 50',
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
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
                    _saveLimit(intValue); // Save on change
                  }
                },
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.sync_alt, // Example Icon
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Max Parallel AI Processes',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: TextFormField(
                controller: _maxParallelController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., 4',
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
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
                  }
                },
              ),
            ),
            Divider(color: Colors.grey[700]),

            // Performance Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Performance',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.speed, color: theme.colorScheme.primary),
              title: Text(
                'Performance Tips',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Lower limits improve performance with many screenshots',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: Icon(
                Icons.info_outline,
                color: Colors.grey[400],
                size: 16,
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerformanceMonitor(),
                  ),
                );
              },
            ),

            Divider(color: Colors.grey[700]),
            ListTile(
              leading: Icon(Icons.code, color: theme.colorScheme.primary),
              title: Text('Source Code', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'View on GitHub',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _launchURL('https://github.com/AnsahMohammad/shots-studio');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.favorite,
                color: Colors.redAccent,
              ), // Keep red for favorite/contribute
              title: Text('Contribute', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Support the project',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _launchURL('http://github.com/AnsahMohammad');
              },
            ),
            Divider(color: Colors.grey[700]),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ), // Use primary color
              title: Text('About', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Version $_appVersion',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Shots Studio',
                  applicationVersion: _appVersion,
                  applicationIcon: Icon(
                    Icons.photo_library,
                    size: 50,
                    color: theme.colorScheme.primary,
                  ),
                  children: [
                    Text(
                      'A screenshot management app built with Flutter.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap:
                          () => _launchURL(
                            'https://github.com/AnsahMohammad/shots-studio',
                          ),
                      child: Text(
                        'Contribute to the project ❤️',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _limitController.dispose();
    _maxParallelController.dispose();
    super.dispose();
  }
}
