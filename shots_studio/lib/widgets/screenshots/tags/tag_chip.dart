import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final VoidCallback? onTap; // New callback for tap events

  const TagChip({
    super.key,
    required this.label,
    this.onDelete,
    this.onTap, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Handle tap events
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
