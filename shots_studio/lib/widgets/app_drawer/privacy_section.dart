import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/analytics_service.dart';
import '../../utils/privacy_content_provider.dart';

// Privacy dialog as a stateless widget
class _PrivacyDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 50),
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            width: 1.5,
          ),
        ),
        title: Text(
          'Data Processing Information',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              ...PrivacyContentProvider.getPrivacyContent(
                context,
                launchUrlCallback: (BuildContext ctx, String urlString) {
                  // Add analytics tracking for different links
                  if (urlString.contains('policies.google.com')) {
                    AnalyticsService().logFeatureUsed(
                      'privacy_policy_link_clicked',
                    );
                    AnalyticsService().logFeatureUsed(
                      'google_privacy_policy_clicked',
                    );
                  } else if (urlString.contains('ai.google.dev/terms')) {
                    AnalyticsService().logFeatureUsed(
                      'terms_of_service_link_clicked',
                    );
                    AnalyticsService().logFeatureUsed(
                      'google_gemini_terms_clicked',
                    );
                  } else if (urlString.contains('ansahmohammad.github.io')) {
                    AnalyticsService().logFeatureUsed(
                      'app_privacy_policy_clicked',
                    );
                  }

                  _launchURL(ctx, urlString);
                },
              ),
              const SizedBox(height: 10),
              Text(
                "Analytics collection is optional and can be disabled in Advanced Settings (accessible by tapping 'About' 7 times in the app drawer).",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Helper method to launch URLs
  Future<void> _launchURL(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error launching URL: $e')));
    }
  }
}

class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key});

  // Moved to _PrivacyDialog class

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Divider(color: theme.colorScheme.outline),
        ListTile(
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'Privacy Notice',
            style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
          ),
          subtitle: Text(
            'Data Processing Information',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          onTap: () {
            // Log analytics for privacy dialog access
            AnalyticsService().logFeatureUsed('privacy_dialog_opened');
            AnalyticsService().logScreenView('privacy_dialog');

            // Close drawer
            Navigator.pop(context);

            // Push a new route for the privacy dialog
            Navigator.of(context).push(
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (BuildContext context, _, __) {
                  return _PrivacyDialog();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
