import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class ChipInputWidget extends StatelessWidget {
  final List<String> availableOptions;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const ChipInputWidget({
    Key? key,
    required this.availableOptions,
    required this.selectedValues,
    required this.onChanged,
  }) : super(key: key);

  void _toggleSelection(String option) {
    final updated = List<String>.from(selectedValues);
    if (updated.contains(option)) {
      updated.remove(option);
    } else {
      updated.add(option);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: availableOptions.map((option) {
        final isSelected = selectedValues.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => _toggleSelection(option),
          selectedColor: AppColors.gold,
          backgroundColor: AppColors.surfaceLight,
          checkmarkColor: AppColors.background,
          labelStyle: isSelected
              ? AppFonts.bodyText(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 13)
              : AppFonts.bodyText(color: AppColors.textSecondary, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.gold : AppColors.borderSubtle,
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
