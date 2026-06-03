import 'package:flutter/material.dart';
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

class _CreateJobScreenState extends State<CreateJobScreen> {
  final JobService jobService = JobService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final salaryMinController = TextEditingController();
  final salaryMaxController = TextEditingController();

  String jobType = 'Full-time';
  bool loading = false;
  String? errorMessage;

  static const Color primaryBlue = Color(0xFF001B7A);
  static const Color lightPurple = Color(0xFFF4F1FF);
  static const Color orange = Color(0xFFFF9800);

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
    // Job creation token initialized

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

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    salaryMinController.dispose();
    salaryMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'RojgarKendra',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),

            const SizedBox(height: 24),

            _label('Job Title', required: true),
            _inputField(
              controller: titleController,
              hint: 'Barista',
            ),

            const SizedBox(height: 18),

            _label('Job Description', required: true),
            _inputField(
              controller: descriptionController,
              hint: 'Write job responsibilities, skills, and requirements...',
              maxLines: 6,
            ),

            const SizedBox(height: 18),

            _label('Location', required: true),
            _inputField(
              controller: locationController,
              hint: ']Pokhara, Kathmandu',
              icon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 18),

            _label('Job Type', required: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: lightPurple,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: jobType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Full-time',
                      child: Text('Full-time'),
                    ),
                    DropdownMenuItem(
                      value: 'Part-time',
                      child: Text('Part-time'),
                    ),
                    DropdownMenuItem(
                      value: 'Remote',
                      child: Text('Remote'),
                    ),

                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        jobType = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            _label('Salary Range', required: true),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    controller: salaryMinController,
                    hint: 'Min',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    controller: salaryMaxController,
                    hint: 'Max',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: loading ? null : handleCreateJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  loading ? 'Posting...' : 'Post Job',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          left: BorderSide(
            color: orange,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: lightPurple,
            child: Icon(
              Icons.work_outline,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Create New Job Post',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add job details so candidates can apply easily.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: lightPurple,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
    );
  }
}