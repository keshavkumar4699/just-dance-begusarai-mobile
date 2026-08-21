/// Just Dance — "Schedule": admission fee, personal training defaults,
/// courses/interests and plans — one grouped section. Full CRUD with
/// delete-protection for items assigned to students.
library;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
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
              _ptDefaultsCard(context, c),
              const SizedBox(height: 16),
              _coursesSection(context, c),
              const SizedBox(height: 16),
              _interestsSection(context, c),
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

  // ---------------- courses ----------------

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
          _fixedBatchTile(c, kBatchWeekendFullLabel),
          _fixedBatchTile(c, kBatchWeekdaysFullLabel),
        ],
      ),
    );
  }

  Widget _fixedBatchTile(AppColors c, String label) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.hairline),
      ),
      child: Text(label,
          style: TextStyle(color: c.textMuted, fontSize: 12.5, fontWeight: FontWeight.w500)),
    );
  }

  // ---------------- interests ----------------

  Widget _interestsSection(BuildContext context, AppColors c) {
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
          const SectionLabel('Course Interests'),
          if (store.courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Create a course first to add interests.',
                  style: TextStyle(color: c.textMuted, fontSize: 12.5)),
            ),
          for (final course in store.courses) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(course.name,
                    style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                TextButton.icon(
                  onPressed: () => _addInterestDialog(context, course.id),
                  icon: Icon(Icons.add, size: 15, color: c.gold),
                  label: Text('Add Interest',
                      style: TextStyle(color: c.gold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Builder(builder: (_) {
              final courseInterests = store.interestsOf(course.id);
              if (courseInterests.isEmpty) {
                return Text('No interests added yet (e.g. Hip Hop, Kathak).',
                    style: TextStyle(color: c.textMuted, fontSize: 11.5));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ci in courseInterests)
                    Chip(
                      label: Text(ci.name, style: const TextStyle(fontSize: 12)),
                      backgroundColor: c.surface2,
                      side: BorderSide(color: c.hairline),
                      deleteIcon: Icon(Icons.close, size: 14, color: c.expired),
                      onDeleted: () async {
                        final err = await store.deleteCourseInterest(ci);
                        if (err != null && context.mounted) {
                          _blockedDialog(context, 'interest');
                        }
                      },
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _addInterestDialog(BuildContext context, int courseId) async {
    final controller = TextEditingController();
    await showAppSheet(
      context,
      _SheetFrame(
        title: 'Add Interest',
        children: [
          const FieldLabel('Interest Name'),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
                hintText: 'e.g. Hip Hop, Kathak, Salsa, Beat Boxing'),
          ),
        ],
        onSave: () async {
          final text = controller.text.trim();
          if (text.isEmpty) {
            showSnack(context, 'Interest name is required', duration: kSnackWarn);
            return;
          }
          await store.saveCourseInterest(
              CourseInterest(courseId: courseId, name: text));
          if (context.mounted) Navigator.pop(context);
        },
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
                decoration:
                    const InputDecoration(hintText: 'e.g. Quarterly Plan')),
            const FieldLabel('Duration (months)'),
            TextField(
                controller: months,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 3')),
            const FieldLabel('Discount (optional)'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: discount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: isPercent ? '' : '₹ ',
                    ),
                  ),
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
              showSnack(context, 'Duration must be at least 1 month',
                  duration: kSnackWarn);
              return;
            }
            final disc = double.tryParse(discount.text.trim()) ?? 0;
            await store.savePlan(Plan(
              id: existing?.id ?? 0,
              name: name.text.trim(),
              months: m,
              discountType: disc > 0 ? (isPercent ? 'percent' : 'rs') : '',
              discountValue: disc > 0 ? disc : 0,
            ));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: c.hairline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 18),
          GoldButton('Save', onTap: onSave),
        ],
      ),
    );
  }
}
