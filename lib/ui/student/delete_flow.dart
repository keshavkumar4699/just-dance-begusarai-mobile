/// Just Dance — delete student flow: type-the-name confirm, cascade delete,
/// 5s Undo snackbar (re-inserts rows + replays the ledger), photo file
/// cleanup when the undo window expires.
library;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/store.dart';
import '../../data/models.dart';
import '../widgets/common.dart';

Future<void> confirmAndDeleteStudent(
    BuildContext context, AppStore store, Student s) async {
  final c = AppColors.of(context);
  final controller = TextEditingController();
  final confirmed = await showAppSheet<bool>(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delete ${s.name}?',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: c.expired)),
          const SizedBox(height: 8),
          Text(
            'This removes the member, their fee ledger and attendance. Type the name to confirm.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: s.name),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: GhostButton('Cancel',
                      onTap: () => Navigator.pop(context, false))),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, v, __) => GoldButton(
                    'Delete forever',
                    onTap: v.text.trim().toLowerCase() ==
                            s.name.trim().toLowerCase()
                        ? () => Navigator.pop(context, true)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  // Close detail screen if we are on it (pop until the shell).
  final snap = await store.deleteStudent(s);
  if (!context.mounted) return;
  showSnack(
    context,
    '${s.name} deleted',
    duration: kSnackLong,
    action: SnackBarAction(
      label: 'Undo',
      textColor: c.gold,
      onPressed: () => store.undoDelete(snap),
    ),
  );
  // After the snackbar window, delete the photo file for good.
  Future.delayed(const Duration(milliseconds: 8500), () {
    store.finalizeDelete(snap);
  });
}
