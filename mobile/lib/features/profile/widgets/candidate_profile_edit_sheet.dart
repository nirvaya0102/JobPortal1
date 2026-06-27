import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/candidate_profile_service.dart';

enum CandidateProfileEditResult {
  profileUpdated,
  resumeUploaded,
  resumeDeleted,
}

class CandidateProfileEditSheet extends StatefulWidget {
  final CandidateProfileData profile;
  final CandidateProfileService service;

  const CandidateProfileEditSheet({
    super.key,
    required this.profile,
    required this.service,
  });

  @override
  State<CandidateProfileEditSheet> createState() =>
      _CandidateProfileEditSheetState();
}

class _CandidateProfileEditSheetState extends State<CandidateProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _headlineController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _skillsController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _headlineController = TextEditingController(text: widget.profile.headline);
    _bioController = TextEditingController(text: widget.profile.bio);
    _locationController = TextEditingController(text: widget.profile.location);
    _skillsController = TextEditingController(
      text: widget.profile.skills.join(', '),
    );
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> _parseSkills(String value) {
    return value
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      await widget.service.updateProfile(
        headline: _headlineController.text,
        bio: _bioController.text,
        location: _locationController.text,
        skills: _parseSkills(_skillsController.text),
      );

      if (!mounted) return;
      Navigator.pop(context, CandidateProfileEditResult.profileUpdated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(error);
    }
  }

  Future<void> _uploadResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );

    final filePath = result?.files.single.path;
    if (filePath == null || !mounted) return;

    final file = File(filePath);
    final fileSizeInBytes = await file.length();
    if (!mounted) return;

    if (fileSizeInBytes > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume must be less than 5MB.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.service.uploadResume(file);

      if (!mounted) return;
      Navigator.pop(context, CandidateProfileEditResult.resumeUploaded);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(error);
    }
  }

  Future<void> _deleteResume() async {
    setState(() => _isSaving = true);

    try {
      await widget.service.deleteResume();

      if (!mounted) return;
      Navigator.pop(context, CandidateProfileEditResult.resumeDeleted);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _headlineController,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Headline',
                    hintText: 'Flutter Developer',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length > 100) {
                      return 'Headline must be 100 characters or less.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell employers about your experience.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length > 1000) {
                      return 'Bio must be 1000 characters or less.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Pokhara',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skillsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Skills',
                    hintText: 'Flutter, Dart, Firebase',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _uploadResume,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload Resume'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving || !widget.profile.hasResume
                            ? null
                            : _deleteResume,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Resume'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
