import 'package:flutter/material.dart';

class PersonalTrainingTab extends StatelessWidget {
  const PersonalTrainingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Training')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_outlined, size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Personal Training Tab',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Phase 5 me PT list aayega',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}