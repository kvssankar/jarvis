import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.currentApiKey);
    _selectedModelName = widget.currentModelName;
    _limitController = TextEditingController(
      text: widget.currentLimit.toString(),
    );
    _maxParallelController = TextEditingController(
      text: widget.currentMaxParallel.toString(),
    );
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
      _selectedModelName = widget.currentModelName;
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
                onChanged: widget.onApiKeyChanged,
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
                Icons.filter_list, // Example Icon
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
                  }
                },
              ),
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
            Divider(color: Colors.grey[700]), // Subtle divider
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ), // Use primary color
              title: Text('About', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Version 1.2.0',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                showAboutDialog(
                  context: context,
                  applicationName: 'Shots Studio', // Consistent App Name
                  applicationVersion: '1.2.0',
                  applicationIcon: Icon(
                    Icons.photo_library,
                    size: 50,
                    color:
                        theme.colorScheme.primary, // Use primary color for icon
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
                          color:
                              theme
                                  .colorScheme
                                  .primary, // Use primary color for link
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
    _limitController.dispose(); // Dispose new controller
    _maxParallelController.dispose(); // Dispose new controller
    super.dispose();
  }
}
