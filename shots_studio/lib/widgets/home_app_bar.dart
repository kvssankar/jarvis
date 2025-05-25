import 'package:flutter/material.dart';
import 'package:shots_studio/screens/search_screen.dart'; // Import the search screen

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProcessWithAI;
  final bool isProcessingAI;
  final int aiProcessedCount;
  final int aiTotalToProcess;
  final VoidCallback? onSearchPressed;

  const HomeAppBar({
    super.key,
    this.onProcessWithAI,
    this.isProcessingAI = false,
    this.aiProcessedCount = 0,
    this.aiTotalToProcess = 0,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Shots Studio',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.transparent,
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
          onPressed: onSearchPressed, // Use the callback
        ),
        if (isProcessingAI)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                'Analyzed $aiProcessedCount/$aiTotalToProcess',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (onProcessWithAI != null ||
            isProcessingAI) // Show button if callback exists or is processing
          IconButton(
            icon:
                isProcessingAI
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).iconTheme.color ?? Colors.white,
                        ),
                      ),
                    )
                    : const Icon(Icons.auto_awesome_outlined),
            tooltip: isProcessingAI ? 'Processing...' : 'Process with AI',
            onPressed: onProcessWithAI,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
