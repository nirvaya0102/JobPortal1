import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../services/job_service.dart';

class CreateJobScreen extends StatefulWidget {
  final String token;

  const CreateJobScreen({
    super.key,
    required this.token,
  });

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen>
    with SingleTickerProviderStateMixin {
  final JobService jobService = JobService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final salaryMinController = TextEditingController();
  final salaryMaxController = TextEditingController();
  final skillsController = TextEditingController();

  final titleFocus = FocusNode();
  final descriptionFocus = FocusNode();
  final locationFocus = FocusNode();
  final salaryMinFocus = FocusNode();
  final salaryMaxFocus = FocusNode();
  final skillsFocus = FocusNode();

  String jobType = 'Full-time';
  String experience = 'Fresher';
  bool loading = false;
  String? errorMessage;
  final List<String> requiredSkills = [];

  static const Color primaryBlue = Color(0xFF001B7A);
  static const List<String> jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Remote',
  ];
  static const List<String> experienceOptions = [
    'Fresher',
    '1-2 Years',
    '3-5 Years',
    '5+ Years',
  ];
  static const List<String> recentLocations = [
    'Kathmandu',
    'Pokhara',
    'Lalitpur',
    'Bhaktapur',
    'Remote',
  ];

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutCubic,
    );
    _animationController!.forward();

    titleController.addListener(_refreshPreview);
    descriptionController.addListener(_refreshPreview);
    locationController.addListener(_refreshPreview);
    salaryMinController.addListener(_refreshPreview);
    salaryMaxController.addListener(_refreshPreview);
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> handleCreateJob() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final salaryMinText = salaryMinController.text.trim();
    final salaryMaxText = salaryMaxController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      setState(() {
        errorMessage = 'Please fill all required fields.';
      });
      return;
    }

    if (salaryMinText.isEmpty || salaryMaxText.isEmpty) {
      setState(() {
        errorMessage = 'Please enter salary range.';
      });
      return;
    }

    final salaryMin = int.tryParse(salaryMinText);
    final salaryMax = int.tryParse(salaryMaxText);

    if (salaryMin == null || salaryMax == null) {
      setState(() {
        errorMessage = 'Salary must be a valid number.';
      });
      return;
    }

    if (salaryMin > salaryMax) {
      setState(() {
        errorMessage = 'Minimum salary cannot be greater than maximum salary.';
      });
      return;
    }

    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      await jobService.createJob(
        token: widget.token,
        title: title,
        description: description,
        location: location,
        jobType: jobType,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posted successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceAll('Exception: ', '');
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
      const SnackBar(content: Text('Draft saved locally for this session.')),
    );
  }

  void _openPreview() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: JobPreviewCard(
            title: _previewTitle,
            companyName: 'Your Company',
            location: _previewLocation,
            salary: _salaryText,
            jobType: jobType,
            isEmpty: _isEmptyDraft,
          ),
        );
      },
    );
  }

  void _insertDescriptionTemplate(String type) {
    final template = switch (type) {
      'Responsibility' => 'Responsibilities\n• ',
      'Requirement' => 'Requirements\n• ',
      'Benefit' => 'Benefits\n• ',
      'Qualification' => 'Qualifications\n• ',
      _ => '$type\n• ',
    };
    final current = descriptionController.text;
    final prefix = current.trim().isEmpty ? '' : '\n\n';
    descriptionController.text = '$current$prefix$template';
    descriptionController.selection = TextSelection.collapsed(
      offset: descriptionController.text.length,
    );
    descriptionFocus.requestFocus();
  }

  void _addSkill([String? value]) {
    final skill = (value ?? skillsController.text).trim();
    if (skill.isEmpty) return;
    if (!requiredSkills.any((item) => item.toLowerCase() == skill.toLowerCase())) {
      setState(() => requiredSkills.add(skill));
    }
    skillsController.clear();
  }

  void _removeSkill(String skill) {
    setState(() => requiredSkills.remove(skill));
  }

  String get _previewTitle {
    final value = titleController.text.trim();
    return value.isEmpty ? 'Senior UI Designer' : value;
  }

  String get _previewLocation {
    final value = locationController.text.trim();
    return value.isEmpty ? 'Pokhara' : value;
  }

  bool get _isEmptyDraft =>
      titleController.text.trim().isEmpty &&
      descriptionController.text.trim().isEmpty &&
      locationController.text.trim().isEmpty &&
      salaryMinController.text.trim().isEmpty &&
      salaryMaxController.text.trim().isEmpty;

  String get _salaryText {
    final min = int.tryParse(salaryMinController.text.trim());
    final max = int.tryParse(salaryMaxController.text.trim());
    if (min != null && max != null) {
      return 'Rs ${_formatNumber(min)} - Rs ${_formatNumber(max)}';
    }
    if (min != null) return 'From Rs ${_formatNumber(min)}';
    if (max != null) return 'Up to Rs ${_formatNumber(max)}';
    return 'Rs 30,000 - Rs 50,000';
  }

  List<ValidationItem> get _validationItems {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final salaryMin = int.tryParse(salaryMinController.text.trim());
    final salaryMax = int.tryParse(salaryMaxController.text.trim());

    return [
      ValidationItem(
        label: title.length >= 3
            ? 'Job title looks good'
            : 'Add a clear job title',
        isValid: title.length >= 3,
      ),
      ValidationItem(
        label: description.length >= 10
            ? 'Description is ready'
            : 'Description is too short',
        isValid: description.length >= 10,
      ),
      ValidationItem(
        label: location.isNotEmpty
            ? 'Location selected'
            : 'Choose a hiring location',
        isValid: location.isNotEmpty,
      ),
      ValidationItem(
        label: salaryMin != null && salaryMax != null && salaryMin <= salaryMax
            ? 'Salary range entered'
            : 'Enter a valid salary range',
        isValid: salaryMin != null && salaryMax != null && salaryMin <= salaryMax,
      ),
    ];
  }

  String _formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    titleController.removeListener(_refreshPreview);
    descriptionController.removeListener(_refreshPreview);
    locationController.removeListener(_refreshPreview);
    salaryMinController.removeListener(_refreshPreview);
    salaryMaxController.removeListener(_refreshPreview);
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    salaryMinController.dispose();
    salaryMaxController.dispose();
    skillsController.dispose();
    titleFocus.dispose();
    descriptionFocus.dispose();
    locationFocus.dispose();
    salaryMinFocus.dispose();
    salaryMaxFocus.dispose();
    skillsFocus.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: AppColors.canvasLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post a Job',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation ?? const AlwaysStoppedAnimation<double>(1),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
            children: [
              JobPreviewCard(
                title: _previewTitle,
                companyName: 'Your Company',
                location: _previewLocation,
                salary: _salaryText,
                jobType: jobType,
                isEmpty: _isEmptyDraft,
              ),
              if (_isEmptyDraft) ...[
                const SizedBox(height: 12),
                const EmptyDraftHint(),
              ],
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.work_outline_rounded,
                title: 'Job Details',
                subtitle: 'Make the role easy to understand at a glance.',
                children: [
                  PremiumTextField(
                    controller: titleController,
                    focusNode: titleFocus,
                    label: 'Job Title',
                    helperText: 'Example: Senior Flutter Developer',
                    icon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => descriptionFocus.requestFocus(),
                  ),
                  const SizedBox(height: 14),
                  DescriptionEditor(
                    controller: descriptionController,
                    focusNode: descriptionFocus,
                    onInsertTemplate: _insertDescriptionTemplate,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.business_center_outlined,
                title: 'Work Information',
                subtitle: 'Set where, how, and what this role pays.',
                children: [
                  LocationField(
                    controller: locationController,
                    focusNode: locationFocus,
                    suggestions: recentLocations,
                  ),
                  const SizedBox(height: 14),
                  EmploymentTypeSelector(
                    selectedType: jobType,
                    options: jobTypes,
                    onChanged: (value) {
                      setState(() => jobType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  SalaryCard(
                    minController: salaryMinController,
                    maxController: salaryMaxController,
                    minFocusNode: salaryMinFocus,
                    maxFocusNode: salaryMaxFocus,
                    salaryText: _salaryText,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.tune_rounded,
                title: 'Hiring Preferences',
                subtitle: 'Add helpful signals for better candidate matching.',
                children: [
                  ExperienceSelector(
                    selectedExperience: experience,
                    options: experienceOptions,
                    onChanged: (value) {
                      setState(() => experience = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  SkillsInput(
                    controller: skillsController,
                    focusNode: skillsFocus,
                    skills: requiredSkills,
                    onAddSkill: _addSkill,
                    onRemoveSkill: _removeSkill,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.verified_outlined,
                title: 'Readiness Check',
                subtitle: 'Live validation before publishing.',
                children: [
                  ValidationChecklist(items: _validationItems),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    ErrorBanner(message: errorMessage!),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const CompanyPreviewCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StickyBottomBar(
        loading: loading,
        onSaveDraft: _saveDraft,
        onPreview: _openPreview,
        onPublish: handleCreateJob,
      ),
    );
  }
}

class JobPreviewCard extends StatelessWidget {
  final String title;
  final String companyName;
  final String location;
  final String salary;
  final String jobType;
  final bool isEmpty;

  const JobPreviewCard({
    super.key,
    required this.title,
    required this.companyName,
    required this.location,
    required this.salary,
    required this.jobType,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF051066), Color(0xFF1739A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001B7A).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -44,
            child: _SoftCircle(size: 132, opacity: 0.11),
          ),
          Positioned(
            right: 34,
            bottom: -64,
            child: _SoftCircle(size: 142, opacity: 0.08),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.work_rounded,
                      color: Color(0xFF001B7A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      isEmpty ? 'DRAFT PREVIEW' : 'LIVE PREVIEW',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                companyName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PreviewPill(icon: Icons.location_on_outlined, text: location),
                  _PreviewPill(icon: Icons.payments_outlined, text: salary),
                  _PreviewPill(icon: Icons.check_circle_outline, text: jobType),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyDraftHint extends StatelessWidget {
  const EmptyDraftHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lightSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF001B7A)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Create a job post to attract the right candidates.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
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
                  color: lightSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF001B7A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String helperText;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PremiumTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    required this.helperText,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: const Color(0xFF001B7A)),
        filled: true,
        fillColor: const Color(0xFFFAFBFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: _fieldBorder(AppColors.borderLight),
        enabledBorder: _fieldBorder(AppColors.borderLight),
        focusedBorder: _fieldBorder(const Color(0xFF001B7A), width: 1.5),
      ),
    );
  }
}

class DescriptionEditor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onInsertTemplate;

  const DescriptionEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onInsertTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 6,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Job Description',
              helperText: 'Use bullets for responsibilities and requirements.',
              prefixIcon: Icon(Icons.subject_rounded, color: Color(0xFF001B7A)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                'Responsibility',
                'Requirement',
                'Benefit',
                'Qualification',
              ])
                ActionChip(
                  label: Text(item),
                  avatar: const Icon(Icons.add_rounded, size: 16),
                  onPressed: () => onInsertTemplate(item),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.borderLight),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmploymentTypeSelector extends StatelessWidget {
  final String selectedType;
  final List<String> options;
  final ValueChanged<String> onChanged;
  static const Set<String> supportedTypes = {'Full-time', 'Part-time', 'Remote'};

  const EmploymentTypeSelector({
    super.key,
    required this.selectedType,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Employment Type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              Tooltip(
                message: supportedTypes.contains(option)
                    ? option
                    : '$option is not supported by the current API yet',
                child: ChoiceChip(
                  label: Text(option),
                  selected: selectedType == option,
                  onSelected: supportedTypes.contains(option)
                      ? (_) => onChanged(option)
                      : null,
                  selectedColor: const Color(0xFFE8EEFF),
                  disabledColor: const Color(0xFFF3F4F6),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selectedType == option
                        ? const Color(0xFF001B7A)
                        : AppColors.borderLight,
                  ),
                  labelStyle: TextStyle(
                    color: !supportedTypes.contains(option)
                        ? AppColors.textHint
                        : selectedType == option
                        ? const Color(0xFF001B7A)
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SalaryCard extends StatelessWidget {
  final TextEditingController minController;
  final TextEditingController maxController;
  final FocusNode minFocusNode;
  final FocusNode maxFocusNode;
  final String salaryText;

  const SalaryCard({
    super.key,
    required this.minController,
    required this.maxController,
    required this.minFocusNode,
    required this.maxFocusNode,
    required this.salaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Salary Range'),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: minController,
                  focusNode: minFocusNode,
                  label: 'Minimum Salary',
                  helperText: 'Monthly NPR',
                  icon: Icons.south_west_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => maxFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PremiumTextField(
                  controller: maxController,
                  focusNode: maxFocusNode,
                  label: 'Maximum Salary',
                  helperText: 'Monthly NPR',
                  icon: Icons.north_east_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: Color(0xFF001B7A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Salary',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        salaryText,
                        style: const TextStyle(
                          color: Color(0xFF001B7A),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;

  const LocationField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Location',
            helperText: 'Choose a city or use Remote.',
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF001B7A),
            ),
            suffixIcon: controller.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear location',
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: const Color(0xFFFAFBFF),
            border: _fieldBorder(AppColors.borderLight),
            enabledBorder: _fieldBorder(AppColors.borderLight),
            focusedBorder: _fieldBorder(const Color(0xFF001B7A), width: 1.5),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final location in suggestions)
              ActionChip(
                label: Text(location),
                avatar: const Icon(Icons.history_rounded, size: 16),
                onPressed: () {
                  controller.text = location;
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                },
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.borderLight),
              ),
          ],
        ),
      ],
    );
  }
}

class ExperienceSelector extends StatelessWidget {
  final String selectedExperience;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const ExperienceSelector({
    super.key,
    required this.selectedExperience,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Experience'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: selectedExperience == option,
                onSelected: (_) => onChanged(option),
                selectedColor: const Color(0xFFEAF7EE),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selectedExperience == option
                      ? AppColors.success
                      : AppColors.borderLight,
                ),
                labelStyle: TextStyle(
                  color: selectedExperience == option
                      ? AppColors.success
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SkillsInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> skills;
  final ValueChanged<String> onAddSkill;
  final ValueChanged<String> onRemoveSkill;

  const SkillsInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.skills,
    required this.onAddSkill,
    required this.onRemoveSkill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Required Skills'),
          if (skills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in skills)
                  InputChip(
                    label: Text(skill),
                    onDeleted: () => onRemoveSkill(skill),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    backgroundColor: const Color(0xFFE8EEFF),
                    side: const BorderSide(color: Color(0xFFDDE7FF)),
                    labelStyle: const TextStyle(
                      color: Color(0xFF001B7A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: onAddSkill,
            decoration: InputDecoration(
              labelText: 'Add skill',
              helperText: 'Type a skill and press Enter.',
              prefixIcon: const Icon(Icons.bolt_outlined, color: Color(0xFF001B7A)),
              suffixIcon: IconButton(
                tooltip: 'Add skill',
                onPressed: () => onAddSkill(controller.text),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              filled: true,
              fillColor: Colors.white,
              border: _fieldBorder(AppColors.borderLight),
              enabledBorder: _fieldBorder(AppColors.borderLight),
              focusedBorder: _fieldBorder(const Color(0xFF001B7A), width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationChecklist extends StatelessWidget {
  final List<ValidationItem> items;

  const ValidationChecklist({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  item.isValid
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: item.isValid ? AppColors.success : orangeShade,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.isValid
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class CompanyPreviewCard extends StatelessWidget {
  const CompanyPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      icon: Icons.apartment_outlined,
      title: 'Company Information',
      subtitle: 'Candidates will see your company identity with this post.',
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: lightSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.business_rounded, color: Color(0xFF001B7A)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Company',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Company details are attached from your employer profile.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StickyBottomBar extends StatelessWidget {
  final bool loading;
  final VoidCallback onSaveDraft;
  final VoidCallback onPreview;
  final VoidCallback onPublish;

  const StickyBottomBar({
    super.key,
    required this.loading,
    required this.onSaveDraft,
    required this.onPreview,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 50,
                child: OutlinedButton(
                  onPressed: loading ? null : onSaveDraft,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.bookmark_border_rounded),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                height: 50,
                child: OutlinedButton(
                  onPressed: loading ? null : onPreview,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.visibility_outlined),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onPublish,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: Text(loading ? 'Publishing...' : 'Publish Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001B7A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

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
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationItem {
  final String label;
  final bool isValid;

  const ValidationItem({
    required this.label,
    required this.isValid,
  });
}

class _PreviewPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PreviewPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _SoftCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
}

const Color lightSurface = Color(0xFFF4F1FF);
const Color orangeShade = Color(0xFFFF9800);
