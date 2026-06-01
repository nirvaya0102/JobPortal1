import 'package:flutter/material.dart';

class AppShadows {
  static List<BoxShadow> soft({Color color = Colors.black}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> medium({Color color = Colors.black}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
