import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProcessWithAI;
  final bool isProcessingAI;
  final int aiProcessedCount;
  final int aiTotalToProcess;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onStopProcessingAI;
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
    this.devMode = false,
    this.autoProcessEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Show AI buttons when auto-processing is disabled
    final bool showAIButtons = !autoProcessEnabled;

    return AppBar(
      title: const Text(
        'Shots Studio',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
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
          tooltip: 'Search Screenshots',
          onPressed: onSearchPressed,
        ),

        // Show AI processing buttons when in dev mode OR auto-processing is disabled
        if (showAIButtons && isProcessingAI)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                'Analyzed $aiProcessedCount/$aiTotalToProcess',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (showAIButtons && isProcessingAI)
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Stop Processing',
            onPressed: onStopProcessingAI,
          )
        else if (showAIButtons && onProcessWithAI != null)
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Process with AI',
            onPressed: onProcessWithAI,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
