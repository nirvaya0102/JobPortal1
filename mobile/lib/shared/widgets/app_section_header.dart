import 'package:flutter/material.dart';

import 'section_title.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SectionTitle(
      title: title,
      actionText: actionText,
      onActionTap: onAction,
    );
  }
}
