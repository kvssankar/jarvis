import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;

  const HomeAppBar({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'PixelShot',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          // TODO: Implement menu functionality
        },
      ),
      actions: [
        // Only show refresh button on Android/iOS
        if (!kIsWeb && onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh screenshots',
            onPressed: onRefresh,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
