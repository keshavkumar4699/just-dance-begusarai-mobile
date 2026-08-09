import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AddMemberTab extends StatelessWidget {
  const AddMemberTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text('Add Member', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Phase 4 me form aayega',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}