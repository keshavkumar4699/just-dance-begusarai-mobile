/// Just Dance — "Schedule": admission fee, GST, personal training defaults,
/// courses/batches/timings and plans — one grouped section. Full CRUD with
/// delete-protection for items assigned to students.
library;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../widgets/common.dart';

class CatalogScreen extends StatelessWidget {
  final AppStore store;
  const CatalogScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final c = AppColors.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('Schedule')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _admissionFeeCard(context, c),
              const SizedBox(height: 16),
              _gstCard(context, c),
              const SizedBox(height: 16),
              _ptDefaultsCard(context, c),
              const SizedBox(height: 16),
              _coursesSection(context, c),
              const SizedBox(height: 16),
              _batchesSection(context, c),
              const SizedBox(height: 16),
              _timingsSection(context, c),
              const SizedBox(height: 16),
              _plansSection(context, c),
            ],
          ),
        );
      },
    );
  }

  // ---------------- admission fee ----------------

  Widget _admissionFeeCard(BuildContext context, AppColors c) {
    final controller =
        TextEditingController(text: store.admissionFeeAmount == 0
            ? ''
            : store.admissionFeeAmount.toStringAsFixed(0));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Admission Fee'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Amount ₹', prefixText: '₹ '),
                ),
              ),
              const SizedBox(width: 10),
              GoldButton('Save', expand: false, onTap: () async {
                final v = double.tryParse(controller.text.trim()) ?? 0;
                if (v < 0) {
                  showSnack(context, 'Amount cannot be negative',
                      duration: kSnackWarn);
                  return;
                }
                await store.setAdmissionFee(v);
                if (context.mounted) {
                  showSnack(context, 'Admission fee saved',
                      duration: kSnackSuccess);
                }
              }),
              const SizedBox(width: 8),
              GhostButton('Clear', onTap: () async {
                await store.setAdmissionFee(0);
                if (context.mounted) {
                  showSnack(context, 'Admission fee cleared',
                      duration: kSnackSuccess);
                }
              }),
            ],
          ),
          const SizedBox(height: 4),
          Text('Charged once to every new member when the toggle is ON.',
              style: TextStyle(color: c.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }

  // ---------------- GST ----------------

  Widget _gstCard(BuildContext context, AppColors c) {
    final gstin =
        TextEditingController(text: store.gstin);
    final rate = TextEditingController(
        text: store.gstRate == 0 ? '' : store.gstRate.toStringAsFixed(0));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('GST (Invoices)'),
          const SizedBox(height: 8),
          TextField(
            controller: gstin,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                hintText: 'GSTIN (optional)',
                prefixText: 'GSTIN: ',
                prefixStyle: TextStyle(color: Color(0xFF8B8B93))),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: rate,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: 'GST % ',
                      prefixStyle: TextStyle(color: Color(0xFF8B8B93))),
                ),
              ),
              const SizedBox(width: 10),
              GoldButton('Save', expand: false, onTap: () async {
                final r = double.tryParse(rate.text.trim()) ?? 0;
                if (r < 0 || r > 100) {
                  showSnack(context, 'GST % must be between 0 and 100',
                      duration: kSnackWarn);
                  return;
                }
                await store.setGstInfo(gstin: gstin.text.trim(), rate: r);
                if (context.mounted) {
                  showSnack(context,
                      r > 0 ? 'GST ${r.toStringAsFixed(0)}% saved' : 'GST turned off',
                      duration: kSnackSuccess);
                }
              }),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'GSTIN + rate appear on the PDF invoice sent to members. 0% turns GST off.',
              style: TextStyle(color: c.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }

  // ---------------- personal training defaults ----------------

  Widget _ptDefaultsCard(BuildContext context, AppColors c) {
    final price = TextEditingController(
        text: store.ptDefaultSessionPrice == 0
            ? ''
            : store.ptDefaultSessionPrice.toStringAsFixed(0));
    final duration = TextEditingController(text: store.ptDefaultDuration);
    final selectedDays = <String>{
      if (store.ptDefaultDays.isNotEmpty)
        ...store.ptDefaultDays.split(',').where((e) => e.isNotEmpty)
    };
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Personal Training'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'e.g. 500', prefixText: '₹ '),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: duration,
                  decoration: const InputDecoration(
                      hintText: 'e.g. 1 hour', labelText: 'Session duration'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Days available',
              style: TextStyle(color: c.textMuted, fontSize: 11.5)),
          const SizedBox(height: 4),
          StatefulBuilder(
            builder: (context, setLocal) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in weekDays)
                  ChoiceChip(
                    label: Text(d),
                    selected: selectedDays.contains(d),
                    onSelected: (on) => setLocal(() {
                      if (on) {
                        selectedDays.add(d);
                      } else {
                        selectedDays.remove(d);
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GoldButton('Save', expand: false, onTap: () async {
            final p = double.tryParse(price.text.trim()) ?? 0;
            if (p < 0) {
              showSnack(context, 'Price cannot be negative', duration: kSnackWarn);
              return;
            }
            await store.setPtDefaults(
              sessionPrice: p,
              duration: duration.text.trim(),
              days: selectedDays.join(','),
            );
            if (context.mounted) {
              showSnack(context, 'Personal training defaults saved', duration: kSnackSuccess);
            }
          }),
          const SizedBox(height: 4),
          Text(
              'Cost per session, session duration and available days — prefilled '
              'when admitting a personal training member.',
              style: TextStyle(color: c.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }

  // ---------------- courses / batches / timings ----------------

  Widget _coursesSection(BuildContext context, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Courses',
              trailing: _addBtn(context, c, 'Course',
                  () => _courseDialog(context, null))),
          if (store.courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No courses yet',
                  style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            ),
          for (final course in store.courses) _courseTile(context, c, course),
        ],
      ),
    );
  }

  Widget _addBtn(BuildContext context, AppColors c, String what,
          VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.add, size: 15, color: c.gold),
        label: Text('Add $what',
            style: TextStyle(color: c.gold, fontSize: 12)),
      );

  Widget _courseTile(BuildContext context, AppColors c, Course course) {
    final courseBatches =
        store.batches.where((b) => b.courseId == course.id).toList();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        iconColor: c.gold,
        collapsedIconColor: c.textMuted,
        title: Text(course.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${fmtMoney(course.fee)}/month',
            style: TextStyle(color: c.gold, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editIcon(context, c, () => _courseDialog(context, course)),
            _deleteIcon(context, c, () async {
              final err = await store.deleteCourse(course);
              if (err != null && context.mounted) {
                _blockedDialog(context, 'course');
              }
            }),
            Icon(Icons.expand_more, color: c.textMuted, size: 18),
          ],
        ),
        children: [
          for (final b in courseBatches) _batchTile(context, c, b),
        ],
      ),
    );
  }

  /// All batches across courses, with add/edit/delete + student counts.
  Widget _batchesSection(BuildContext context, AppColors c) {
    final grouped = <int, List<Batch>>{};
    for (final b in store.batches) {
      grouped.putIfAbsent(b.courseId, () => []).add(b);
    }
    final courseIds = grouped.keys.toList()
      ..sort((a, b) => (store.courseById(a)?.name ?? '')
          .compareTo(store.courseById(b)?.name ?? ''));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Batches',
              trailing: _addBtn(context, c, 'Batch',
                  () => _batchDialog(context, store.courses.isEmpty ? 0 : store.courses.first.id, null))),
          if (store.batches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                  store.courses.isEmpty
                      ? 'Create a course first — batches belong to a course.'
                      : 'No batches yet — add a batch like "Weekend (Sat–Sun) · 2 hours".',
                  style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            ),
          for (final cid in courseIds) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                  '${store.courseById(cid)?.name ?? 'Course'} (${grouped[cid]!.length})',
                  style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
            ),
            for (final b in grouped[cid]!)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            [
                              if (b.daysInfo.isNotEmpty) b.daysInfo,
                              if (b.duration.isNotEmpty) b.duration,
                              _batchStudents(b),
                            ].where((e) => e.isNotEmpty).join(' · '),
                            style: TextStyle(
                                color: c.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    _editIcon(context, c, () => _batchDialog(context, b.courseId, b)),
                    _deleteIcon(context, c, () async {
                      final err = await store.deleteBatch(b);
                      if (err != null && context.mounted) {
                        _blockedDialog(context, 'batch');
                      }
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _batchStudents(Batch b) {
    final n = store.studentCourses.where((e) => e.batchId == b.id).length;
    return '$n student${n == 1 ? '' : 's'}';
  }

  /// All timings across batches, with add/edit/delete.
  Widget _timingsSection(BuildContext context, AppColors c) {
    final grouped = <int, List<BatchTiming>>{};
    for (final t in store.timings) {
      grouped.putIfAbsent(t.batchId, () => []).add(t);
    }
    final batchIds = grouped.keys.toList()
      ..sort((a, b) => (store.batchById(a)?.name ?? '')
          .compareTo(store.batchById(b)?.name ?? ''));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Timings',
              trailing: _addBtn(context, c, 'Timing',
                  () => _timingDialog(context, store.batches.isEmpty ? 0 : store.batches.first.id, null))),
          if (store.timings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                  store.batches.isEmpty
                      ? 'Create a batch first — timings belong to a batch.'
                      : 'No timings yet — add batch timings like "Morning · 06:00–07:00".',
                  style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            ),
          for (final bid in batchIds) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                  '${store.batchById(bid)?.name ?? 'Batch'} (${store.courseById(store.batchById(bid)?.courseId ?? 0)?.name ?? ''})',
                  style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
            ),
            for (final t in grouped[bid]!)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${t.label}${t.startTime.isEmpty ? '' : ' · ${t.startTime}–${t.endTime}'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    _editIcon(context, c,
                        () => _timingDialog(context, bid, t)),
                    _deleteIcon(context, c, () async {
                      final err = await store.deleteTiming(t);
                      if (err != null && context.mounted) {
                        _blockedDialog(context, 'timing');
                      }
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _batchTile(BuildContext context, AppColors c, Batch batch) {
    final batchTimings =
        store.timings.where((t) => t.batchId == batch.id).toList();
    final meta = [
      if (batch.daysInfo.isNotEmpty) batch.daysInfo,
      if (batch.duration.isNotEmpty) batch.duration,
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.hairline),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        iconColor: c.gold,
        collapsedIconColor: c.textMuted,
        title: Text(batch.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: meta.isEmpty
            ? null
            : Text(meta,
                style: TextStyle(color: c.textMuted, fontSize: 11.5)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editIcon(context, c, () => _batchDialog(context, batch.courseId, batch)),
            _deleteIcon(context, c, () async {
              final err = await store.deleteBatch(batch);
              if (err != null && context.mounted) {
                _blockedDialog(context, 'batch');
              }
            }),
            Icon(Icons.expand_more, color: c.textMuted, size: 18),
          ],
        ),
        children: [
          for (final t in batchTimings)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        '${t.label}${t.startTime.isEmpty ? '' : ' · ${t.startTime}–${t.endTime}'}',
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _editIcon(BuildContext context, AppColors c, VoidCallback onTap) =>
      Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.edit_outlined, size: 17, color: c.textMuted),
        ),
      );

  Widget _deleteIcon(BuildContext context, AppColors c, VoidCallback onTap) =>
      Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.delete_outline, size: 17, color: c.expired),
        ),
      );

  void _blockedDialog(BuildContext context, String what) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot delete'),
        content: Text(
            'This $what is assigned to at least one student. Remove it from the students first.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  // ---------------- dialogs ----------------

  Future<void> _courseDialog(BuildContext context, Course? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final fee = TextEditingController(
        text: existing == null ? '' : existing.fee.toStringAsFixed(0));
    final desc = TextEditingController(text: existing?.description ?? '');
    await showAppSheet(
      context,
      _SheetFrame(
        title: existing == null ? 'Add Course' : 'Edit Course',
        children: [
          const FieldLabel('Course name'),
          TextField(
              controller: name,
              decoration:
                  const InputDecoration(hintText: 'e.g. Strength Training')),
          const FieldLabel('Monthly fee (₹)'),
          TextField(
              controller: fee,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 500')),
          const FieldLabel('Description (optional)'),
          TextField(controller: desc),
        ],
        onSave: () async {
          if (name.text.trim().isEmpty) {
            showSnack(context, 'Name is required', duration: kSnackWarn);
            return;
          }
          final f = double.tryParse(fee.text.trim()) ?? -1;
          if (f < 0) {
            showSnack(context, 'Enter a valid fee', duration: kSnackWarn);
            return;
          }
          if (existing != null &&
              f != existing.fee &&
              store.courseInUse(existing.id)) {
            final ok = await showConfirmDialog(context,
                title: 'Change fee?',
                message:
                    'Existing students keep their paid cycles — the new fee applies only to future cycles.',
                confirmLabel: 'Change');
            if (!ok) return;
          }
          await store.saveCourse(Course(
              id: existing?.id ?? 0,
              name: name.text.trim(),
              fee: f,
              description: desc.text.trim(),
              createdAt: existing?.createdAt));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _batchDialog(
      BuildContext context, int courseId, Batch? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final days = TextEditingController(text: existing?.daysInfo ?? '');
    final duration = TextEditingController(text: existing?.duration ?? '');
    var selectedCourse = existing?.courseId ?? courseId;
    await showAppSheet(
      context,
      StatefulBuilder(
        builder: (context, setSheet) => _SheetFrame(
          title: existing == null ? 'Add Batch' : 'Edit Batch',
          children: [
            const FieldLabel('Course'),
            AppDropdown<int>(
              value: selectedCourse == 0 ? null : selectedCourse,
              hint: store.courses.isEmpty ? 'Create a course first' : 'Select course',
              items: [
                for (final course in store.courses)
                  DropdownMenuItem(
                      value: course.id,
                      child: Text(
                          '${course.name} · ${fmtMoney(course.fee)}/mo',
                          overflow: TextOverflow.ellipsis))
              ],
              onChanged: (v) => setSheet(() => selectedCourse = v ?? 0),
            ),
            const FieldLabel('Batch name'),
            TextField(
                controller: name,
                decoration: const InputDecoration(
                    hintText: 'e.g. Weekend Batch')),
            const FieldLabel('Days info (optional)'),
            TextField(
                controller: days,
                decoration: const InputDecoration(
                    hintText: 'e.g. Mon–Fri or Sat–Sun')),
            const FieldLabel('Duration (optional)'),
            TextField(
                controller: duration,
                decoration: const InputDecoration(
                    hintText: 'e.g. 1 hour or 2 hours')),
          ],
          onSave: () async {
            if (store.courses.isEmpty) {
              showSnack(context, 'Create a course first', duration: kSnackWarn);
              return;
            }
            if (selectedCourse == 0) {
              showSnack(context, 'Select a course', duration: kSnackWarn);
              return;
            }
            if (name.text.trim().isEmpty) {
              showSnack(context, 'Name is required', duration: kSnackWarn);
              return;
            }
            await store.saveBatch(Batch(
                id: existing?.id ?? 0,
                courseId: selectedCourse,
                name: name.text.trim(),
                daysInfo: days.text.trim(),
                duration: duration.text.trim()));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _timingDialog(
      BuildContext context, int batchId, BatchTiming? existing) async {
    final label = TextEditingController(text: existing?.label ?? '');
    final start = TextEditingController(text: existing?.startTime ?? '');
    final end = TextEditingController(text: existing?.endTime ?? '');
    var selectedBatch = existing?.batchId ?? batchId;

    Future<void> pick(TextEditingController ctrl) async {
      final t = await showTimePicker(
          context: context, initialTime: const TimeOfDay(hour: 6, minute: 0));
      if (t != null) {
        ctrl.text =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
    }

    await showAppSheet(
      context,
      StatefulBuilder(
        builder: (context, setSheet) => _SheetFrame(
          title: existing == null ? 'Add Timing' : 'Edit Timing',
          children: [
            const FieldLabel('Batch'),
            AppDropdown<int>(
              value: selectedBatch == 0 ? null : selectedBatch,
              hint: store.batches.isEmpty ? 'Create a batch first' : 'Select batch',
              items: [
                for (final b in store.batches)
                  DropdownMenuItem(
                      value: b.id,
                      child: Text(
                          '${store.courseById(b.courseId)?.name ?? ''} — ${b.name}',
                          overflow: TextOverflow.ellipsis))
              ],
              onChanged: (v) => setSheet(() => selectedBatch = v ?? 0),
            ),
            const FieldLabel('Label'),
            TextField(
                controller: label,
                decoration: const InputDecoration(hintText: 'e.g. Morning')),
            const FieldLabel('Start time'),
            _timeField(context, start, () => pick(start)),
            const FieldLabel('End time'),
            _timeField(context, end, () => pick(end)),
          ],
          onSave: () async {
            if (store.batches.isEmpty) {
              showSnack(context, 'Create a batch first', duration: kSnackWarn);
              return;
            }
            if (selectedBatch == 0) {
              showSnack(context, 'Select a batch', duration: kSnackWarn);
              return;
            }
            if (label.text.trim().isEmpty) {
              showSnack(context, 'Label is required', duration: kSnackWarn);
              return;
            }
            await store.saveTiming(BatchTiming(
                id: existing?.id ?? 0,
                batchId: selectedBatch,
                label: label.text.trim(),
                startTime: start.text.trim(),
                endTime: end.text.trim()));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _timeField(BuildContext context, TextEditingController ctrl,
          VoidCallback onTap) =>
      Pressable(
        onTap: onTap,
        child: IgnorePointer(
          child: TextField(
            controller: ctrl,
            decoration:
                const InputDecoration(hintText: 'HH:MM (tap to pick)'),
          ),
        ),
      );

  // ---------------- plans ----------------

  Widget _plansSection(BuildContext context, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Plans',
              trailing:
                  _addBtn(context, c, 'Plan', () => _planDialog(context, null))),
          if (store.plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No plans yet',
                  style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            ),
          for (final p in store.plans)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13.5)),
                        Text(
                            '${p.months} month${p.months == 1 ? '' : 's'}${p.discountValue > 0 ? ' · ${p.discountType == 'percent' ? '${p.discountValue.toStringAsFixed(0)}% off' : '${fmtMoney(p.discountValue)} off'}' : ''}',
                            style: TextStyle(
                                color: c.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  _editIcon(context, c, () => _planDialog(context, p)),
                  _deleteIcon(context, c, () async {
                    final err = await store.deletePlan(p);
                    if (err != null && context.mounted) {
                      _blockedDialog(context, 'plan');
                    }
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _planDialog(BuildContext context, Plan? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final months = TextEditingController(
        text: existing == null ? '1' : existing.months.toString());
    final discount = TextEditingController(
        text: existing == null || existing.discountValue == 0
            ? ''
            : existing.discountValue.toStringAsFixed(0));
    var isPercent = existing?.discountType == 'percent';
    await showAppSheet(
      context,
      StatefulBuilder(
        builder: (context, setSheet) => _SheetFrame(
          title: existing == null ? 'Add Plan' : 'Edit Plan',
          children: [
            const FieldLabel('Plan name'),
            TextField(
                controller: name,
                decoration: const InputDecoration(hintText: 'e.g. Quarterly')),
            const FieldLabel('Duration (months)'),
            TextField(
                controller: months,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 1, 3, 12')),
            const FieldLabel('Discount (optional)'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: discount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          hintText: '0',
                          prefixText: isPercent ? '' : '₹ ')),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  constraints:
                      const BoxConstraints(minWidth: 52, minHeight: 44),
                  isSelected: [!isPercent, isPercent],
                  onPressed: (i) => setSheet(() => isPercent = i == 1),
                  children: const [
                    Text('₹', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('%', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
          onSave: () async {
            if (name.text.trim().isEmpty) {
              showSnack(context, 'Name is required', duration: kSnackWarn);
              return;
            }
            final m = int.tryParse(months.text.trim()) ?? 0;
            if (m <= 0) {
              showSnack(context, 'Duration must be at least 1 month', duration: kSnackWarn);
              return;
            }
            final d = double.tryParse(discount.text.trim()) ?? 0;
            if (d < 0 || (isPercent && d > 100)) {
              showSnack(context, isPercent
                  ? 'Percent cannot exceed 100'
                  : 'Discount cannot be negative',
                  duration: kSnackWarn);
              return;
            }
            await store.savePlan(Plan(
                id: existing?.id ?? 0,
                name: name.text.trim(),
                months: m,
                discountType: d > 0 ? (isPercent ? 'percent' : 'rs') : '',
                discountValue: d));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

/// Shared sheet frame for the small catalog dialogs.
class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;
  const _SheetFrame(
      {required this.title, required this.children, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.hairline,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...children,
            const SizedBox(height: 18),
            GoldButton('Save', icon: Icons.check, onTap: onSave),
          ],
        ),
      ),
    );
  }
}
