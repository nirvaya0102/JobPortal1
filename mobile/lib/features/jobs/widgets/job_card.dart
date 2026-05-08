import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../screens/job_detail_screen.dart';

class JobCard extends StatelessWidget {
  final JobModel job;

  const JobCard({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    
    return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            jobId: job.id,
          ),
        ),
      );
    },

    

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: job.companyLogo != null
                  ? NetworkImage(job.companyLogo!)
                  : null,
              child: job.companyLogo == null
                  ? const Icon(Icons.business)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    job.companyName ?? 'Unknown Company',
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  if (job.location != null)
                    Text('📍 ${job.location}'),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (job.salary != null)
                        Chip(label: Text(job.salary!)),

                      if (job.type != null)
                        Chip(label: Text(job.type!)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}