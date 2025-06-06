import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/analytics_service.dart';

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
              Text(
                "Shots Studio utilizes Google Gemini, a third-party cloud-based AI service, to process and analyze your images for features such as generating searchable text, suggesting tags, and organizing collections. For these features to function, your images will be transmitted to and processed by Google's servers.\n",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                child: Text(
                  "This image processing is subject to Google's Privacy Policy.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () {
                  // Log analytics for privacy policy link click
                  AnalyticsService().logFeatureUsed(
                    'privacy_policy_link_clicked',
                  );
                  AnalyticsService().logFeatureUsed(
                    'google_privacy_policy_clicked',
                  );

                  _launchURL(context, 'https://policies.google.com/privacy');
                },
              ),
              const SizedBox(height: 5),
              InkWell(
                child: Text(
                  "And Google's Gemini API Terms of Service.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () {
                  // Log analytics for terms of service link click
                  AnalyticsService().logFeatureUsed(
                    'terms_of_service_link_clicked',
                  );
                  AnalyticsService().logFeatureUsed(
                    'google_gemini_terms_clicked',
                  );

                  _launchURL(context, 'https://ai.google.dev/terms');
                },
              ),
              const SizedBox(height: 10),
              Text(
                "\nShots Studio itself does not permanently store your original images on its own servers after they have been processed by Google Gemini for the aforementioned AI features.\n\n"
                "Please ensure you review and are comfortable with Google's terms and privacy practices before using the AI features.\n"
                "P.S. Don't worry, your cat memes are safe with us. 😺",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
