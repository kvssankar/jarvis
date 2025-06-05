import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/sponsorship_service.dart';
import '../sponsorship/sponsorship_dialog.dart';

class AboutSection extends StatelessWidget {
  final String appVersion;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AboutSection({
    super.key,
    required this.appVersion,
    this.onTap,
    this.onLongPress,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  void _showSponsorshipDialog(BuildContext context) {
    final sponsorshipOptions = SponsorshipService.getAllOptions();

    // Route to fullscreen dialog
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) =>
                SponsorshipDialog(sponsorshipOptions: sponsorshipOptions),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.code, color: theme.colorScheme.primary),
          title: Text(
            'Source Code',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Contribute on GitHub',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            Navigator.pop(context);
            _launchURL('https://github.com/AnsahMohammad/shots-studio');
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: Colors.redAccent),
          title: Text('Support', style: TextStyle(color: Colors.greenAccent)),
          subtitle: Text(
            'Sponsor the project',
            style: TextStyle(color: Colors.greenAccent),
          ),
          onTap: () {
            Navigator.pop(context);
            _showSponsorshipDialog(context);
          },
        ),
        Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          title: Text(
            'About',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Version $appVersion',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            if (onTap != null) {
              onTap!();
            }
            // Don't close drawer when tapping About to allow for multiple taps
          },
          onLongPress: () {
            if (onLongPress != null) {
              onLongPress!();
            }
          },
        ),
      ],
    );
  }
}
