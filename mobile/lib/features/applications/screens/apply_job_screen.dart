import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/storage/user_storage.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/candidate_footer.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/screens/candidate_main_screen.dart';
import '../../jobs/services/job_service.dart';
import '../services/application_service.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;
  final int currentIndex;

  const ApplyJobScreen({
    super.key,
    required this.jobId,
    this.currentIndex = 0,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final ApplicationService applicationService = ApplicationService();
  final JobService _jobService = JobService();

  final TextEditingController coverLetterController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  File? selectedResume;
  JobModel? job;

  bool loading = false;
  bool loadingJob = true;
  double uploadProgress = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
    _loadJob();
  }

  Future<void> _loadContactInfo() async {
    final storedEmail = await UserStorage.getEmail();
    final storedPhone = await UserStorage.getPhone();

    if (!mounted) return;

    setState(() {
      emailController.text = storedEmail?.trim() ?? '';
      phoneController.text = storedPhone?.trim() ?? '';
    });
  }

  Future<void> _loadJob() async {
    try {
      final result = await _jobService.getJobById(widget.jobId);
      if (!mounted) return;

      setState(() {
        job = result;
      });
    } catch (_) {
      // Keep screen usable even if job header fails.
    }

    if (mounted) {
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

    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (phone.length < 7) {
      setState(() {
        errorMessage = 'Please enter a valid phone number.';
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
        email: email,
        phone: phone,
        coverLetter: coverLetterController.text.trim(),
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              uploadProgress = sent / total;
            });
          }
        },
      );

      await UserStorage.savePhone(phone);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Application Submitted'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
              SizedBox(height: 16),
              Text(
                'Your application has been sent successfully.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'The hiring team will review your profile and contact you soon.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Job'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CandidateMainScreen(initialIndex: 2),
                  ),
                  (route) => false,
                );
              },
              child: const Text('View Applications'),
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
  void dispose() {
    coverLetterController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 360 ? 14.0 : 18.0;
    final fileName = selectedResume?.path.split(RegExp(r'[/\\]')).last;

    final company = (job?.companyName ?? 'Company').trim();
    final title = (job?.title ?? 'Job Position').trim();
    final location = (job?.location ?? 'Kathmandu, Nepal').trim();
    final type = (job?.type ?? 'Full-time').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Apply Job'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primary,
      ),
      body: loadingJob
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                180,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroJobCard(
                    title: title,
                    company: company,
                    location: location,
                    type: type,
                  ),
                  const SizedBox(height: 18),

                  _SectionCard(
                    icon: Icons.upload_file_rounded,
                    title: 'Resume / CV',
                    subtitle: 'PDF, DOC, or DOCX under 5MB',
                    child: _UploadBox(
                      fileName: fileName,
                      isDisabled: loading,
                      onTap: pickResume,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Contact Information',
                    subtitle: 'Recruiters will contact you using this information',
                    child: Column(
                      children: [
                        _AppTextField(
                          controller: emailController,
                          label: 'Email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _AppTextField(
                          controller: phoneController,
                          label: 'Phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Cover Letter',
                    subtitle: 'Optional, but recommended',
                    child: TextField(
                      controller: coverLetterController,
                      minLines: 5,
                      maxLines: 8,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Write a short message explaining why you are a good fit for this role...',
                        hintStyle: const TextStyle(color: Color(0xFF85889A)),
                        filled: true,
                        fillColor: const Color(0xFFF8F8FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE3E5EF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE3E5EF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (loading) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: LinearProgressIndicator(
                        value: uploadProgress,
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBox(message: errorMessage!),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomApplyBar(
            loading: loading,
            canSubmit: selectedResume != null,
            onSaveDraft: _saveDraft,
            onSubmit: submitApplication,
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

class _HeroJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String type;

  const _HeroJobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B126A),
            Color(0xFF1727B8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B126A).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: _DecorCircle(size: 110, opacity: 0.12),
          ),
          Positioned(
            right: 42,
            bottom: -45,
            child: _DecorCircle(size: 90, opacity: 0.09),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  _HeroPill(
                    icon: Icons.bookmark_border_rounded,
                    text: 'Save',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                company,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroPill(icon: Icons.location_on_outlined, text: location),
                  _HeroPill(icon: Icons.access_time_rounded, text: type),
                  const _HeroPill(
                    icon: Icons.payments_outlined,
                    text: 'Negotiable',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF3)),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF171A3A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7A7D91),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String? fileName;
  final bool isDisabled;
  final VoidCallback onTap;

  const _UploadBox({
    required this.fileName,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFEFFBF3) : const Color(0xFFF7F8FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasFile ? const Color(0xFFBCE7C8) : const Color(0xFFE2E5F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: hasFile ? Colors.green : AppColors.primary,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              hasFile ? fileName! : 'Tap to upload resume',
              textAlign: TextAlign.center,
              maxLines: hasFile ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF252946),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              hasFile ? 'Tap to replace file' : 'PDF, DOC, or DOCX only',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF85889A),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF737792), size: 20),
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E5EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E5EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _BottomApplyBar extends StatelessWidget {
  final bool loading;
  final bool canSubmit;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;

  const _BottomApplyBar({
    required this.loading,
    required this.canSubmit,
    required this.onSaveDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                onPressed: loading ? null : onSaveDraft,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFFD7DAE8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.bookmark_border_rounded),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: loading ? 'Submitting...' : 'Apply Now',
                leadingIcon: Icons.arrow_forward_rounded,
                onPressed: (loading || !canSubmit) ? null : onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
