import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/application_model.dart';
import 'job_detail_screen.dart';

class CandidateAppliedJobsScreen extends StatefulWidget {
  const CandidateAppliedJobsScreen({super.key});

  @override
  State<CandidateAppliedJobsScreen> createState() =>
      _CandidateAppliedJobsScreenState();
}

class _CandidateAppliedJobsScreenState
    extends State<CandidateAppliedJobsScreen> {
  late Future<List<ApplicationModel>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _loadApplications();
  }

  Future<List<ApplicationModel>> _loadApplications() async {
    final response = await ApiClient.dio.get(
      'jobs/my-applications?page=1&limit=50',
    );
    final data = response.data['data'] ?? {};
    final applicationsJson = (data['applications'] ?? []) as List;
    return applicationsJson
        .map(
          (item) => ApplicationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _applicationsFuture = _loadApplications();
    });
    await _applicationsFuture;
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection. Please check your network.';
      }
      if (error.response?.statusCode == 401) {
        return 'Session expired. Please login again.';
      }
      if ((error.response?.statusCode ?? 0) >= 500) {
        return 'Server error. Please try again later.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'REVIEWED':
        return Colors.blue;
      case 'SHORTLISTED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    final color = _statusColor(status);
    return color.withValues(alpha: 0.14);
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Date unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(title: const Text('Applied Jobs')),
      body: FutureBuilder<List<ApplicationModel>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _AppliedJobsLoadingState();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _StateCard(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load applications',
                  message: _friendlyError(snapshot.error!),
                  actionLabel: 'Retry',
                  onAction: _refresh,
                ),
              ),
            );
          }

          final applications = snapshot.data ?? const [];
          if (applications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _StateCard(
                  icon: Icons.work_outline_rounded,
                  title: 'No applications yet',
                  message: 'Apply to jobs to track your hiring progress here.',
                  actionLabel: 'Refresh',
                  onAction: _refresh,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: applications.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final application = applications[index];
                final statusColor = _statusColor(application.status);
                final job = application.job;

                final jobTitle = job?.title ?? 'Application #${application.id.substring(0, application.id.length > 8 ? 8 : application.id.length)}';
                final companyName = job?.companyName ?? 'Confidential Company';
                final companyLogo = job?.companyLogo;
                final jobLocation = job?.location ?? 'Remote / Flexible';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    onTap: job == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(
                                  jobId: job.id,
                                  currentIndex: 2,
                                ),
                              ),
                            );
                          },
                    child: Ink(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: AppShadows.soft(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFEAF0FF),
                                backgroundImage: companyLogo != null && companyLogo.trim().isNotEmpty
                                    ? NetworkImage(companyLogo)
                                    : null,
                                child: companyLogo == null || companyLogo.trim().isEmpty
                                    ? const Icon(Icons.business, color: AppColors.primaryBlue)
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      jobTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      companyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBg(application.status),
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                ),
                                child: Text(
                                  application.status,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    jobLocation,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Applied: ${_formatDate(application.appliedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if ((application.coverLetter ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(color: AppColors.borderLight, height: 1),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              application.coverLetter!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.primaryBlue),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _AppliedJobsLoadingState extends StatelessWidget {
  const _AppliedJobsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemBuilder: (_, _) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
      ),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemCount: 4,
    );
  }
}
