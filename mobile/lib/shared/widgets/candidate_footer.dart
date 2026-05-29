import 'package:flutter/material.dart';

class CandidateFooterItem {
  final IconData icon;
  final String label;

  const CandidateFooterItem({required this.icon, required this.label});
}

class CandidateFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CandidateFooterItem> items;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  const CandidateFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = const [
      CandidateFooterItem(icon: Icons.explore_outlined, label: 'Explore'),
      CandidateFooterItem(icon: Icons.bookmark_outline, label: 'Saved'),
      CandidateFooterItem(icon: Icons.check_box_outlined, label: 'Applied'),
      CandidateFooterItem(icon: Icons.person, label: 'Profile'),
    ],
    this.activeColor = const Color(0xFF000B5E),
    this.inactiveColor = const Color(0xFF6B7280),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(20),
                child: _CandidateFooterItemView(
                  icon: item.icon,
                  label: item.label,
                  isActive: isActive,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CandidateFooterItemView extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const _CandidateFooterItemView({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: isActive
              ? BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Icon(
            icon,
            color: isActive ? Colors.white : inactiveColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : inactiveColor,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
