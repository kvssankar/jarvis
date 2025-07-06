import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/snackbar_service.dart';
import 'package:shots_studio/utils/privacy_content_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shots_studio/services/analytics_service.dart';

class PrivacyAcknowledgementDialog extends StatelessWidget {
  final VoidCallback onAgreed;
  final VoidCallback? onDisagreed;

  const PrivacyAcknowledgementDialog({
    super.key,
    required this.onAgreed,
    this.onDisagreed,
  });

  Future<void> _launchURL(BuildContext context, String urlString) async {
    // Track URL launches from privacy dialog
    AnalyticsService().logFeatureUsed('privacy_dialog_url_clicked');

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      SnackbarService().showError(context, 'Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        'Data Processing Acknowledgment',
        style: TextStyle(color: theme.colorScheme.primary),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              "By clicking 'Agree & Continue', you acknowledge and consent to the following:\n",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            ...PrivacyContentProvider.getPrivacyContent(
              context,
              launchUrlCallback: _launchURL,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Disagree',
            style: TextStyle(color: theme.colorScheme.secondary),
          ),
          onPressed: () {
            // Track privacy disagreement
            AnalyticsService().logFeatureUsed('privacy_dialog_disagreed');

            Navigator.of(context).pop();
            if (onDisagreed != null) {
              onDisagreed!();
            } else {
              SystemNavigator.pop();
            }
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          child: Text(
            'Agree & Continue',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
          onPressed: () {
            // Track privacy agreement
            AnalyticsService().logFeatureUsed('privacy_dialog_agreed');

            Navigator.of(context).pop();
            onAgreed();
          },
        ),
      ],
    );
  }
}

Future<bool> showPrivacyDialogIfNeeded(BuildContext context) async {
  const String privacyAcknowledgementKey = 'privacyAcknowledgementAccepted';
  final prefs = await SharedPreferences.getInstance();
  bool? acknowledged = prefs.getBool(privacyAcknowledgementKey);

  if (acknowledged == true) {
    // Privacy already accepted, no need to show dialog
    return true;
  }

  if (!context.mounted) return false;

  // Track privacy dialog shown
  AnalyticsService().logFeatureUsed('privacy_dialog_shown');

  // Create a completer to handle the async result
  Completer<bool> dialogCompleter = Completer<bool>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return PrivacyAcknowledgementDialog(
        onAgreed: () async {
          await prefs.setBool(privacyAcknowledgementKey, true);
          dialogCompleter.complete(true);
        },
        onDisagreed: () {
          SystemNavigator.pop();
          dialogCompleter.complete(false);
        },
      );
    },
  );

  // Wait for dialog to complete
  return dialogCompleter.future;
}
