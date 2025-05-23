import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProcessWithAI;

  const HomeAppBar({super.key, this.onProcessWithAI});

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
        if (onProcessWithAI != null)
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
