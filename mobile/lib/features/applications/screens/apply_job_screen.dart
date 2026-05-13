import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/application_service.dart';

class ApplyJobScreen extends StatefulWidget {
  final String jobId;

  const ApplyJobScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final ApplicationService applicationService = ApplicationService();
  final TextEditingController coverLetterController = TextEditingController();

  File? selectedResume;
  bool loading = false;
  double uploadProgress = 0;
  String? errorMessage;

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = selectedResume?.path.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply to Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            OutlinedButton.icon(
              onPressed: loading ? null : pickResume,
              icon: const Icon(Icons.upload_file),
              label: Text(
                fileName ?? 'Select Resume PDF/DOCX',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: coverLetterController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Cover Letter',
                hintText: 'Write a short cover letter...',
                border: OutlineInputBorder(),
              ),
            ),

            if (loading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: uploadProgress),
              const SizedBox(height: 8),
              Text('${(uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
            ],

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : submitApplication,
                child: Text(
                  loading ? 'Submitting...' : 'Submit Application',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}