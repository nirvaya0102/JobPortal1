import 'package:flutter/material.dart';

class CandidateCategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CandidateCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((category) {
          final active = category == selected;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: active,
              showCheckmark: false,
              avatar: Icon(
                _categoryIcon(category),
                size: 16,
                color: active ? Colors.white : const Color(0xFF1D3FAF),
              ),
              label: Text(category),
              onSelected: (_) => onSelected(category),
              labelStyle: TextStyle(
                color: active ? Colors.white : const Color(0xFF344054),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1D3FAF),
              side: BorderSide(
                color:
                    active ? const Color(0xFF1D3FAF) : const Color(0xFFD8E3FF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'remote':
        return Icons.language_rounded;
      case 'full time':
        return Icons.schedule_rounded;
      case 'internship':
        return Icons.school_outlined;
      case 'design':
        return Icons.draw_outlined;
      case 'development':
        return Icons.code_rounded;
      case 'marketing':
        return Icons.campaign_outlined;
      case 'engineering':
        return Icons.engineering_outlined;
      case 'finance':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.apps_rounded;
    }
  }
}
