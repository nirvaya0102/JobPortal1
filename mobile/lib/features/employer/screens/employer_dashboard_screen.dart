import 'package:flutter/material.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/services/job_service.dart';
import '../../jobs/screens/create_job_screen.dart';

class EmployerDashboardScreen extends StatefulWidget {
  final String token;

   const EmployerDashboardScreen({
      super.key,
      required this.token,
    });

    @override
    State<EmployerDashboardScreen> createState() =>
        _EmployerDashboardScreenState();
  }

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  final JobService jobService = JobService();

  static const Color primaryBlue = Color(0xFF001B7A);
  static const Color lightPurple = Color(0xFFF2F0FF);
  static const Color softPurple = Color(0xFFEDE9FF);
  static const Color green = Color(0xFF3BB273);
  static const Color red = Color(0xFFE74C3C);

  late Future<List<JobModel>> jobsFuture;

  @override
  void initState() {
    super.initState();
    jobsFuture = jobService.getMyJobs(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: primaryBlue),
        title: const Text(
          'RojgarKendra',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),

      body: FutureBuilder<List<JobModel>>(
        future: jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          final activeJobs = jobs
              .where((job) => job.status == 'OPEN' || job.status == 'ACTIVE')
              .length;

          final totalApplicants = jobs.fold<int>(
            0,
            (sum, job) => sum + job.applicantsCount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _welcomeCard(),
                const SizedBox(height: 20),

                _statCard(
                  icon: Icons.business_center,
                  title: 'Active Job Postings',
                  value: activeJobs.toString(),
                  badge: '${jobs.length} total jobs',
                  badgeColor: green,
                ),

                const SizedBox(height: 16),

                _statCard(
                  icon: Icons.groups,
                  title: 'Total Applicants',
                  value: totalApplicants.toString(),
                  badge: 'From all jobs',
                  badgeColor: green,
                  iconColor: Colors.orange,
                ),

                const SizedBox(height: 16),

                _statCard(
                  icon: Icons.message,
                  title: 'New Messages',
                  value: '0',
                  badge: 'No API yet',
                  badgeColor: red,
                ),

                const SizedBox(height: 24),

                const Text(
                  'My Posted Jobs',
                  style: TextStyle(
                    fontSize: 18,
                    color: primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                if (jobs.isEmpty)
                  const Text('No jobs posted yet.')
                else
                  ...jobs.map(
                    (job) => _jobCard(
                      title: job.title,
                      status: job.status,
                      applicants: job.applicantsCount,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
floatingActionButton: FloatingActionButton(
  backgroundColor: primaryBlue,
  onPressed: () async {

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateJobScreen(
          token: widget.token,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        jobsFuture = jobService.getMyJobs(widget.token);
      });
    }
  },
  child: const Icon(Icons.add, color: Colors.white),
),

    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.business, color: primaryBlue),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Welcome back,\nEmployer',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    Color iconColor = primaryBlue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              Text(
                badge,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(title),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              color: primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobCard({
    required String title,
    required String status,
    required int applicants,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.work, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$title\n$status • $applicants applicants',
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}