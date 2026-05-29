import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? foreground;

  const Pill({super.key, required this.text, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = background ?? colorScheme.surfaceContainerHighest;
    final fg = foreground ?? colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
