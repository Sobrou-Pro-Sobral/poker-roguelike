import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE51B2B),
            foregroundColor: Colors.white,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black38),
          );

    final child = SizedBox(
      height: 48,
      child: Center(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );

    return primary
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}
