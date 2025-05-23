import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
                value: 'gemini-2.0-flash',
                dropdownColor: theme.cardTheme.color ?? Colors.grey[900],
                icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                style: TextStyle(color: Colors.white),
                underline: SizedBox.shrink(),
                onChanged: (String? newValue) {
                  // TODO: Handle model change
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
}
