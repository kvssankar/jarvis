import 'package:flutter/material.dart';
import '../../services/analytics_service.dart';
import '../../screens/privacy_screen.dart';

class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
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
            // Log analytics for privacy screen access
            AnalyticsService().logFeatureUsed('privacy_screen_opened');
            AnalyticsService().logScreenView('privacy_screen');

            // Navigate to privacy screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) =>
                        const PrivacyScreen(isAcknowledgementRequired: false),
              ),
            );
          },
        ),
      ],
    );
  }
}
