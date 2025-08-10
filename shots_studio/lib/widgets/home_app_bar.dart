import 'package:flutter/material.dart';
import 'package:shots_studio/l10n/app_localizations.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProcessWithAI;
  final bool isProcessingAI;
  final int aiProcessedCount;
  final int aiTotalToProcess;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onStopProcessingAI;
  final VoidCallback? onRemindersPressed;
  final int activeRemindersCount;
  final bool devMode;
  final bool autoProcessEnabled;

  const HomeAppBar({
    super.key,
    this.onProcessWithAI,
    this.isProcessingAI = false,
    this.aiProcessedCount = 0,
    this.aiTotalToProcess = 0,
    this.onSearchPressed,
    this.onStopProcessingAI,
    this.onRemindersPressed,
    this.activeRemindersCount = 0,
    this.devMode = false,
    this.autoProcessEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Show AI buttons when auto-processing is disabled
    final bool showAIButtons = !autoProcessEnabled;

    return AppBar(
      title: Text(
        AppLocalizations.of(context)?.appTitle ?? 'Shots Studio',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip:
              AppLocalizations.of(context)?.searchScreenshots ??
              'Search Screenshots',
          onPressed: onSearchPressed,
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color:
                activeRemindersCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : null,
          ),
          tooltip: AppLocalizations.of(context)?.reminders ?? 'Reminders',
          onPressed: onRemindersPressed,
        ),

        // Show stop button whenever AI is processing (regardless of auto-processing setting)
        if (isProcessingAI)
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            color:
                activeRemindersCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : null,
            tooltip:
                AppLocalizations.of(context)?.stopProcessing ??
                'Stop Processing',
            onPressed: onStopProcessingAI,
          )
        // Show AI process button only when auto-processing is disabled and not currently processing
        else if (showAIButtons && onProcessWithAI != null)
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip:
                AppLocalizations.of(context)?.processWithAI ??
                'Process with AI',
            onPressed: onProcessWithAI,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
