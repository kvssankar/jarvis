import 'package:flutter/material.dart';
import 'package:shots_studio/screens/transaction_analysis_screen.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Features',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('Transaction Analysis'),
          subtitle: const Text('Analyze SMS messages for transactions'),
          onTap: () {
            // Log analytics
            AnalyticsService().logFeatureUsed('transaction_analysis');
            AnalyticsService().logScreenView('transaction_analysis_screen');

            // Navigate to transaction analysis screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TransactionAnalysisScreen(),
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }
}
