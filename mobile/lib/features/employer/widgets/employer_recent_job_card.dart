import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';

class EmployerRecentJobCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String applicantSummary;
  final String status;
  final String? rejectionReason;
  final VoidCallback onTapApplicants;

  const EmployerRecentJobCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.applicantSummary,
    required this.status,
    this.rejectionReason,
    required this.onTapApplicants,
  });

  Color _statusColor(String value) {
    final normalized = value.toUpperCase();
    if (normalized == 'APPROVED') {
      return AppColors.success;
    }
    if (normalized == 'REJECTED') {
      return AppColors.danger;
    }
    if (normalized == 'CLOSED') {
      return AppColors.textSecondary;
    }
    return Colors.orange;
  }

  String _statusLabel(String value) {
    switch (value.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'CLOSED':
        return 'Closed';
      case 'PENDING':
      default:
        return 'Pending Approval';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    final reason = rejectionReason?.trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (status.toUpperCase() == 'REJECTED' &&
                    reason != null &&
                    reason.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Reason: $reason',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      applicantSummary,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onTapApplicants,
                      child: const Text('View Applicants'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

