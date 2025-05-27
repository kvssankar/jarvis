import 'package:flutter/material.dart';

class AddCollectionButton extends StatefulWidget {
  final VoidCallback onTap;

  const AddCollectionButton({super.key, required this.onTap});

  @override
  State<AddCollectionButton> createState() => _AddCollectionButtonState();
}

class _AddCollectionButtonState extends State<AddCollectionButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Card(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color:
                    isHovered
                        ? const Color.fromARGB(255, 255, 236, 179)
                        : const Color.fromARGB(255, 252, 224, 140),
              ),
              child: Icon(
                Icons.add,
                size: isHovered ? 38 : 32,
                color: Colors.black.withOpacity(isHovered ? 0.8 : 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
