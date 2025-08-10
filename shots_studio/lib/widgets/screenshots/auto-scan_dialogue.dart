import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shots_studio/services/analytics/analytics_service.dart';

class ScanConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final String collectionName;

  const ScanConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.collectionName,
  });

  @override
  State<ScanConfirmationDialog> createState() => _ScanConfirmationDialogState();
}

class _ScanConfirmationDialogState extends State<ScanConfirmationDialog> {
  bool _dontShowAgain = false;

  Future<void> _saveDontShowAgain() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('scan_dialog_dont_show_again', true);
      AnalyticsService().logFeatureUsed('scan_dialog_dont_show_again');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_fix_high, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Find Matching Screenshots',
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Would you like to search your existing screenshots to find ones that might belong in "${widget.collectionName}"?',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Important Note:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This feature searches text from previously analyzed screenshots (titles and descriptions) to find potential matches. It only uses text data, not the actual images, so accuracy may vary.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() {
                    _dontShowAgain = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _dontShowAgain = !_dontShowAgain;
                    });
                  },
                  child: Text(
                    'Don\'t show this again',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            AnalyticsService().logFeatureUsed('scan_dialog_cancelled');
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await _saveDontShowAgain();
            AnalyticsService().logFeatureUsed('scan_dialog_confirmed');
            Navigator.of(context).pop();
            widget.onConfirm();
          },
          icon: const Icon(Icons.auto_fix_high, size: 18),
          label: const Text('Find Matches'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}
