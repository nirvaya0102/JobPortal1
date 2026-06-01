import 'package:flutter/material.dart';

import '../models/job_model.dart';

class CandidateFeaturedJobCarousel extends StatefulWidget {
  final List<JobModel> jobs;
  final ValueChanged<JobModel> onJobTap;

  const CandidateFeaturedJobCarousel({
    super.key,
    required this.jobs,
    required this.onJobTap,
  });

  @override
  State<CandidateFeaturedJobCarousel> createState() =>
      _CandidateFeaturedJobCarouselState();
}

class _CandidateFeaturedJobCarouselState
    extends State<CandidateFeaturedJobCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.jobs.isEmpty) {
      return Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE7FF)),
        ),
        alignment: Alignment.center,
        child: Text(
          'No featured jobs available',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 182,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.jobs.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final job = widget.jobs[index];
              return Padding(
                padding: EdgeInsets.only(right: index == widget.jobs.length - 1 ? 0 : 10),
                child: _FeaturedCard(
                  job: job,
                  onTap: () => widget.onJobTap(job),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.jobs.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF1D3FAF)
                    : const Color(0xFFD3DCFF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _FeaturedCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = job.title;
    final company = (job.companyName?.trim().isNotEmpty ?? false)
        ? job.companyName!
        : 'Confidential Company';
    final salary = (job.salary?.trim().isNotEmpty ?? false)
        ? job.salary!
        : 'Competitive Pay';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C3FA7), Color(0xFF2E5ED1)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E5ED1).withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: job.companyLogo != null
                          ? NetworkImage(job.companyLogo!)
                          : null,
                      child: job.companyLogo == null
                          ? const Icon(Icons.business, color: Colors.white)
                          : null,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$company • $salary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE1E9FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
