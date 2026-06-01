import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/candidate_footer.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/screens/candidate_main_screen.dart';
import '../../jobs/services/job_service.dart';
import '../services/application_service.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;
  final int currentIndex;

  const ApplyJobScreen({super.key, required this.jobId, this.currentIndex = 0});

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final ApplicationService applicationService = ApplicationService();
  final JobService _jobService = JobService();
  final TextEditingController coverLetterController = TextEditingController();

  File? selectedResume;
  JobModel? job;
  bool loading = false;
  bool loadingJob = true;
  double uploadProgress = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    try {
      final result = await _jobService.getJobById(widget.jobId);
      if (!mounted) return;
      setState(() {
        job = result;
      });
    } catch (_) {
      // Keep screen usable even if header data fails.
    } finally {
      if (!mounted) return;
      setState(() {
        loadingJob = false;
      });
    }
  }

  Future<void> pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final fileSizeInMb = await file.length() / (1024 * 1024);

    if (fileSizeInMb > 5) {
      setState(() {
        errorMessage = 'Resume must be less than 5MB.';
      });
      return;
    }

    setState(() {
      selectedResume = file;
      errorMessage = null;
    });
  }

  Future<void> submitApplication() async {
    if (selectedResume == null) {
      setState(() {
        errorMessage = 'Please upload your resume.';
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMessage = null;
        uploadProgress = 0;
      });

      await applicationService.applyToJob(
        jobId: widget.jobId,
        resumeFile: selectedResume!,
        coverLetter: coverLetterController.text.trim(),
        onProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              uploadProgress = sent / total;
            });
          }
        },
      );

      if (!mounted) return;

      // JOB-DET-006: Show success dialog with clear action
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Application Submitted!'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Your application has been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'The hiring team will review your application and contact you soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // Close dialog
                Navigator.pop(context);  // Go back to job detail
              },
              child: const Text('Back to Job'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CandidateMainScreen(initialIndex: 2),  // Go to applied jobs
                  ),
                  (route) => false,
                );
              },
              child: const Text('View My Applications'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally.')),
    );
  }

  @override
  void dispose() {
    coverLetterController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => CandidateMainScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? AppSpacing.md : 14.0;
    final fileName = selectedResume?.path.split(RegExp(r'[/\\]')).last;
    final company = (job?.companyName ?? 'Company').trim();
    final title = (job?.title ?? 'Job Position').trim();
    final location = (job?.location ?? 'Kathmandu, Nepal').trim();
    final type = (job?.type ?? 'Full-time').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F8),
      appBar: AppBar(
        title: const Text('Rojgar Kendra'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5F4F8),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
      ),
      body: loadingJob
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Icon(Icons.work_outline_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF242744),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          company,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6C6F86),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _MetaText(icon: Icons.location_on_outlined, text: location),
                            _MetaText(icon: Icons.schedule_rounded, text: type),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Resume / CV *',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: loading ? null : pickResume,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EFF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0DFE6)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDEDFE8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Click to upload or drag and drop',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF4F526A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PDF, DOCX, or RTF (Max. 5MB)',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8689A1),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Text(
                              'Browse Files',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (fileName != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD7D8F2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFFDB554F)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B3E5A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Cover Letter',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(Optional)',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EFF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0DFE6)),
                    ),
                    child: TextField(
                      controller: coverLetterController,
                      minLines: 5,
                      maxLines: 8,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText:
                            'Write a brief message to the hiring manager detailing why you are a great fit for this role...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(value: uploadProgress, minHeight: 6),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${(uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.soft(),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : _saveDraft,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: loading ? 'Submitting...' : 'Submit Application',
                      leadingIcon: Icons.arrow_forward_rounded,
                      // JOB-DET-002: Disable button until resume is selected
                      onPressed: (loading || selectedResume == null) ? null : submitApplication,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CandidateFooter(
            currentIndex: widget.currentIndex,
            onTap: _goToTab,
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF737792)),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF737792),
              ),
        ),
      ],
    );
  }
}
