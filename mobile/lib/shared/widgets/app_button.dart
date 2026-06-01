import 'package:flutter/material.dart';

import '../../core/constants/app_metrics.dart';
import '../../core/constants/app_spacing.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: AppMetrics.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: AppMetrics.iconLg,
                height: AppMetrics.iconLg,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: AppMetrics.iconSm),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: child);
    }

    return child;
  }
}
