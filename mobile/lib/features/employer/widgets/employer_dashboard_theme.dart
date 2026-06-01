import 'package:flutter/material.dart';

class EmployerDashboardPalette {
  static const Color primary = Color(0xFF12308F);
  static const Color secondary = Color(0xFF2B5CC7);
  static const Color surface = Colors.white;
  static const Color canvas = Color(0xFFF3F7FF);
  static const Color border = Color(0xFFDCE6FF);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textMuted = Color(0xFF667085);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
}

class EmployerGradientBackground extends StatelessWidget {
  final Widget child;

  const EmployerGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF1FF), Color(0xFFF3F7FF), Colors.white],
          stops: [0, 0.46, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -60,
            right: -40,
            child: _BlurOrb(size: 180, color: Color(0x552B5CC7)),
          ),
          const Positioned(
            top: 140,
            left: -35,
            child: _BlurOrb(size: 130, color: Color(0x4416A34A)),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

