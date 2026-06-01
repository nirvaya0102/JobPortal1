import 'package:flutter/material.dart';

import '../../../shared/widgets/dashboard_card.dart';

class EmployerStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color accent;

  const EmployerStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      icon: icon,
      label: label,
      value: value,
      helper: helper,
      accent: accent,
    );
  }
}

