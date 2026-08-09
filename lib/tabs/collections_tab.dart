import 'package:flutter/material.dart';

class CollectionsTab extends StatelessWidget {
  const CollectionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Collections Tab', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Phase 6 me reports aayenge',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}