import 'package:flutter/material.dart';

class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // App icon with theme coloring
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onPrimaryContainer,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/icon/ic_launcher_monochrome.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Text(
            'Shots Studio',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Screenshot Manager',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
