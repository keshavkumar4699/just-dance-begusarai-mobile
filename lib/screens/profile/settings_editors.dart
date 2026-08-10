import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Generic dialog shell with title + confirm.
class EditorDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final String saveLabel;
  final VoidCallback onSave;

  const EditorDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.saveLabel = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
              const SizedBox(height: 14),
              child,
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ScaleTap(
                  onTap: onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Text(saveLabel,
                          style: wt(Theme.of(context).textTheme.labelLarge,
                              weight: 800, color: AppColors.darkBg)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool digits;
  final int? maxLen;

  const _Field({required this.label, required this.controller, this.digits = false, this.maxLen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: digits ? TextInputType.number : TextInputType.text,
        inputFormatters: [
          if (digits) FilteringTextInputFormatter.digitsOnly,
          if (maxLen != null) LengthLimitingTextInputFormatter(maxLen),
        ],
        decoration: InputDecoration(isDense: true, labelText: label),
      ),
    );
  }
}

/// Course editor (name + monthly fee + description).
class CourseEditor extends StatefulWidget {
  final Course? course;

  const CourseEditor({super.key, this.course});

  @override
  State<CourseEditor> createState() => _CourseEditorState();
}

class _CourseEditorState extends State<CourseEditor> {
  late final _name = TextEditingController(text: widget.course?.name ?? '');
  late final _fee = TextEditingController(text: widget.course?.fee == 0 ? '' : '${widget.course!.fee}');
  late final _desc = TextEditingController(text: widget.course?.description ?? '');

  @override
  void dispose() {
    _name.dispose();
    _fee.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialog(
      title: widget.course == null ? 'Add Course' : 'Edit Course',
      onSave: () {
        if (_name.text.trim().isEmpty) return;
        Navigator.of(context).pop(Course(
          id: widget.course?.id,
          name: _name.text.trim(),
          fee: int.tryParse(_fee.text) ?? 0,
          description: _desc.text.trim(),
        ));
      },
      child: Column(
        children: [
          _Field(label: 'Course name *', controller: _name),
          _Field(label: 'Monthly fee (₹)', controller: _fee, digits: true),
          _Field(label: 'Description (optional)', controller: _desc),
          Text('Note: fee edits apply to new students only',
              style: wt(Theme.of(context).textTheme.labelSmall,
                  weight: 500, color: AppColors.greyIcon)),
        ],
      ),
    );
  }
}

/// Batch editor (name + days info, per course).
class BatchEditor extends StatefulWidget {
  final Batch? batch;

  const BatchEditor({super.key, this.batch});

  @override
  State<BatchEditor> createState() => _BatchEditorState();
}

class _BatchEditorState extends State<BatchEditor> {
  late final _name = TextEditingController(text: widget.batch?.name ?? '');
  late final _days = TextEditingController(text: widget.batch?.daysInfo ?? '');
  int? _courseId;

  @override
  void initState() {
    super.initState();
    _courseId = widget.batch?.courseId;
  }

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return EditorDialog(
      title: widget.batch == null ? 'Add Batch' : 'Edit Batch',
      onSave: () {
        if (_name.text.trim().isEmpty || _courseId == null) return;
        Navigator.of(context).pop(Batch(
          id: widget.batch?.id,
          courseId: _courseId!,
          name: _name.text.trim(),
          daysInfo: _days.text.trim(),
        ));
      },
      child: Column(
        children: [
          DropdownButtonFormField<int?>(
            initialValue: _courseId,
            items: [
              for (final c in state.courses) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _courseId = v),
            decoration: const InputDecoration(isDense: true, labelText: 'Course *'),
          ),
          const SizedBox(height: 10),
          _Field(label: 'Batch name * (e.g. Weekend Batch)', controller: _name),
          _Field(label: 'Days info (e.g. Sat-Sun)', controller: _days),
        ],
      ),
    );
  }
}

/// Timing editor (label + start/end, per batch).
class TimingEditor extends StatefulWidget {
  final Timing? timing;

  const TimingEditor({super.key, this.timing});

  @override
  State<TimingEditor> createState() => _TimingEditorState();
}

class _TimingEditorState extends State<TimingEditor> {
  late final _label = TextEditingController(text: widget.timing?.label ?? '');
  late final _start = TextEditingController(text: widget.timing?.startTime ?? '');
  late final _end = TextEditingController(text: widget.timing?.endTime ?? '');
  int? _batchId;

  @override
  void initState() {
    super.initState();
    _batchId = widget.timing?.batchId;
  }

  @override
  void dispose() {
    _label.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return EditorDialog(
      title: widget.timing == null ? 'Add Timing' : 'Edit Timing',
      onSave: () {
        if (_label.text.trim().isEmpty || _batchId == null) return;
        Navigator.of(context).pop(Timing(
          id: widget.timing?.id,
          batchId: _batchId!,
          label: _label.text.trim(),
          startTime: _start.text.trim(),
          endTime: _end.text.trim(),
        ));
      },
      child: Column(
        children: [
          DropdownButtonFormField<int?>(
            initialValue: _batchId,
            items: [
              for (final b in state.batches) DropdownMenuItem(value: b.id, child: Text(b.name)),
            ],
            onChanged: (v) => setState(() => _batchId = v),
            decoration: const InputDecoration(isDense: true, labelText: 'Batch *'),
          ),
          const SizedBox(height: 10),
          _Field(label: 'Timing label * (e.g. 6-7 AM)', controller: _label),
          Row(
            children: [
              Expanded(child: _Field(label: 'Start (e.g. 6:00 AM)', controller: _start)),
              const SizedBox(width: 8),
              Expanded(child: _Field(label: 'End (e.g. 7:00 AM)', controller: _end)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plan editor (name + duration months + discount ₹/%).
class PlanEditor extends StatefulWidget {
  final Plan? plan;

  const PlanEditor({super.key, this.plan});

  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  late final _name = TextEditingController(text: widget.plan?.name ?? '');
  late final _months = TextEditingController(
      text: widget.plan?.months == 0 ? '' : '${widget.plan?.months ?? 1}');
  late final _discount = TextEditingController(
      text: widget.plan?.discountValue == 0 ? '' : '${widget.plan?.discountValue}');
  late String _type = widget.plan?.discountType ?? '%';

  @override
  void dispose() {
    _name.dispose();
    _months.dispose();
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialog(
      title: widget.plan == null ? 'Add Plan' : 'Edit Plan',
      onSave: () {
        if (_name.text.trim().isEmpty) return;
        final months = int.tryParse(_months.text) ?? 1;
        Navigator.of(context).pop(Plan(
          id: widget.plan?.id,
          name: _name.text.trim(),
          months: months < 1 ? 1 : months,
          discountType: _type,
          discountValue: int.tryParse(_discount.text) ?? 0,
        ));
      },
      child: Column(
        children: [
          _Field(label: 'Plan name * (e.g. Monthly)', controller: _name),
          _Field(label: 'Duration (months)', controller: _months, digits: true),
          Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '₹', label: Text('₹')),
                  ButtonSegment(value: '%', label: Text('%')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedForegroundColor: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _Field(label: 'Discount', controller: _discount, digits: true)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Studio info editor (name, director, contact, socials, address).
class StudioInfoEditor extends StatefulWidget {
  const StudioInfoEditor({super.key});

  @override
  State<StudioInfoEditor> createState() => _StudioInfoEditorState();
}

class _StudioInfoEditorState extends State<StudioInfoEditor> {
  late final _name = TextEditingController(text: AppState.instance.studio.name);
  late final _director = TextEditingController(text: AppState.instance.studio.director);
  late final _contact = TextEditingController(text: AppState.instance.studio.contact);
  late final _socials = TextEditingController(text: AppState.instance.studio.socials);
  late final _address = TextEditingController(text: AppState.instance.studio.address);

  @override
  void dispose() {
    _name.dispose();
    _director.dispose();
    _contact.dispose();
    _socials.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorDialog(
      title: 'Edit Studio Info',
      onSave: () {
        Navigator.of(context).pop(StudioInfo(
          name: _name.text.trim().isEmpty ? 'Studio Crow' : _name.text.trim(),
          director: _director.text.trim(),
          contact: _contact.text.trim(),
          socials: _socials.text.trim(),
          address: _address.text.trim(),
          logoPath: AppState.instance.studio.logoPath,
        ));
      },
      child: Column(
        children: [
          _Field(label: 'Studio name *', controller: _name),
          _Field(label: 'Director', controller: _director),
          _Field(label: 'Contact (mobile)', controller: _contact, digits: true, maxLen: 10),
          _Field(label: 'Socials (Instagram / Facebook)', controller: _socials),
          _Field(label: 'Address', controller: _address),
        ],
      ),
    );
  }
}

