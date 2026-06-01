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
      child: Row(
        children: categories.map((category) {
          final active = category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: active,
              label: Text(category),
              onSelected: (_) => onSelected(category),
              labelStyle: TextStyle(
                color: active ? Colors.white : const Color(0xFF344054),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1D3FAF),
              side: BorderSide(
                color: active ? const Color(0xFF1D3FAF) : const Color(0xFFD8E3FF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(vertical: -2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
