import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radii.dart';
import '../../../core/constants/app_spacing.dart';

class ResumePreviewScreen extends StatefulWidget {
  final String resumeUrl;
  final String candidateName;
  final String? fileName;
  final String? fileType;

  const ResumePreviewScreen({
    super.key,
    required this.resumeUrl,
    required this.candidateName,
    this.fileName,
    this.fileType,
  });

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  bool hasError = false;
  String? errorMessage;

  bool get _looksLikePdf {
    final type = widget.fileType?.toLowerCase().trim() ?? '';
    final fileName = widget.fileName?.toLowerCase().trim() ?? '';
    final url = widget.resumeUrl.toLowerCase().split('?').first;

    if (type.contains('pdf')) return true;
    if (fileName.endsWith('.pdf')) return true;
    if (url.endsWith('.pdf')) return true;

    final isWordFile = type.contains('word') ||
        type.contains('doc') ||
        fileName.endsWith('.doc') ||
        fileName.endsWith('.docx') ||
        url.endsWith('.doc') ||
        url.endsWith('.docx');

    return !isWordFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CV Preview'),
            Text(
              widget.candidateName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
      ),
      body: !_looksLikePdf
          ? _UnsupportedFileState(fileName: widget.fileName)
          : hasError
              ? _PreviewErrorState(
                  message: errorMessage ??
                      'Unable to preview this CV inside the app.',
                )
              : Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SfPdfViewer.network(
                    widget.resumeUrl,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,
                    onDocumentLoadFailed: (details) {
                      setState(() {
                        hasError = true;
                        errorMessage = details.description;
                      });
                    },
                  ),
                ),
    );
  }
}

class _UnsupportedFileState extends StatelessWidget {
  final String? fileName;

  const _UnsupportedFileState({this.fileName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 42,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Preview unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                fileName == null || fileName!.trim().isEmpty
                    ? 'This CV file is not a PDF. Please ask the candidate to upload a PDF CV for in-app preview.'
                    : '$fileName is not a PDF. Please ask the candidate to upload a PDF CV for in-app preview.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewErrorState extends StatelessWidget {
  final String message;

  const _PreviewErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Could not preview CV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
