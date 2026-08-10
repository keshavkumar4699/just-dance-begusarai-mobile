import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants.dart';
import '../../models/models.dart';
import '../../services/fee_engine.dart';
import '../../services/photo_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common.dart';
import 'crop_screen.dart';
import 'welcome_kit_sheet.dart';

/// Searchable picker (used for course/batch/timing dropdowns).
Future<int?> pickSearchableItem(
  BuildContext context, {
  required String title,
  required List<String> items,
}) async {
  if (items.isEmpty) return null;
  final controller = TextEditingController();
  final result = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final q = controller.text.trim().toLowerCase();
        final filtered = [
          for (var i = 0; i < items.length; i++)
            if (q.isEmpty || items[i].toLowerCase().contains(q)) i,
        ];
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(title, style: wt(Theme.of(ctx).textTheme.titleMedium, weight: 700)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(message: 'Nothing matches', icon: Icons.search_off)
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final idx = filtered[i];
                          return ListTile(
                            title: Text(items[idx],
                                style: wt(Theme.of(ctx).textTheme.bodyMedium, weight: 500)),
                            onTap: () => Navigator.of(ctx).pop(idx),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return result;
}

/// ADD DETAILS FORM - used for both new members and editing.
/// Sections: Personal Details | Identity | Courses & Batch | Fee Options.
class AddDetailsForm extends StatefulWidget {
  final String? photoPath;
  final Student? existing;

  const AddDetailsForm({super.key, this.photoPath, this.existing});

  @override
  State<AddDetailsForm> createState() => _AddDetailsFormState();
}

class _AddDetailsFormState extends State<AddDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final AppState _state = AppState.instance;
  final _scroller = ScrollController();

  // ---- personal ----
  late String _name;
  late String _father;
  late String _mother;
  late String _photo;
  late String _pVillage, _pPO, _pDist, _pPin;
  late bool _corrSame;
  late String _cVillage, _cPO, _cDist, _cPin;

  // ---- identity ----
  late String _aadhar;
  late DateTime? _dob;
  late String _gender;
  late String _religion;
  late String _nationality;
  late String _marital;

  // ---- contact ----
  late String _mobile;
  late String _altMobile;

  // ---- courses ----
  final List<_CourseRow> _courseRows = [];
  bool _courseError = false;

  // ---- fee ----
  late bool _admFeeEnabled;
  late bool _admFeePaid;
  late int? _planId;
  late int _firstPaid;
  late String _mode;
  late String _discountType;
  late int _discountValue;
  late DateTime _admissionDate;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = e?.name ?? '';
    _father = e?.fatherName ?? '';
    _mother = e?.motherName ?? '';
    _photo = widget.photoPath ?? e?.photoPath ?? '';
    _pVillage = e?.permVillage ?? '';
    _pPO = e?.permPO ?? '';
    _pDist = e?.permDist ?? '';
    _pPin = e?.permPin ?? '';
    _corrSame = e?.corrSame ?? true;
    _cVillage = e?.corrVillage ?? '';
    _cPO = e?.corrPO ?? '';
    _cDist = e?.corrDist ?? '';
    _cPin = e?.corrPin ?? '';
    _aadhar = e?.aadhar ?? '';
    _dob = e?.dob.isNotEmpty == true ? Dates.parse(e!.dob) : null;
    _gender = e?.gender ?? '';
    _religion = e?.religion ?? 'Hindu';
    _nationality = e?.nationality ?? 'Indian';
    _marital = e?.maritalStatus ?? 'Unmarried';
    _mobile = e?.mobile ?? '';
    _altMobile = e?.altMobile ?? '';
    _admFeeEnabled = e?.admissionFeeEnabled ?? _state.admissionFeeAmount > 0;
    _admFeePaid = e?.admissionFeePaid ?? false;
    _planId = e?.planId;
    _firstPaid = 0;
    _mode = 'Cash';
    _discountType = '%';
    _discountValue = 0;
    _admissionDate = e != null ? Dates.parse(e.admissionDate) : DateTime.now();

    // Course rows.
    if (e != null) {
      final scs = _state.coursesOf(e);
      for (final sc in scs) {
        _courseRows.add(_CourseRow(courseId: sc.courseId, batchId: sc.batchId, timingId: sc.timingId));
      }
      if (_courseRows.isEmpty) _courseRows.add(_CourseRow());
    } else {
      _courseRows.add(_CourseRow());
    }
  }

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  // ---- derived --------------------------------------------------------------

  int get _cyclePrice {
    var t = 0;
    for (final r in _courseRows) {
      final c = _state.courseById(r.courseId);
      if (c != null) t += c.fee;
    }
    return t;
  }

  String get _categoryChip {
    if (_dob == null) return '';
    return categoryFor(dob: _dob);
  }

  int get _planMonths => _state.planById(_planId)?.months ?? 1;

  /// Admission summary used for the invoice.
  ({int base, int discount, int admissionDue, int total, int paid, int balance}) get _summary {
    final base = _cyclePrice * _planMonths;
    final discount = FeeEngine.applyDiscount(base, _discountType, _discountValue);
    final admissionDue = _admFeeEnabled ? _state.admissionFeeAmount : 0;
    final total = base - discount + admissionDue;
    final paid = _firstPaid + (_admFeePaid && _admFeeEnabled ? _state.admissionFeeAmount : 0);
    final balance = paid - total;
    return (base: base, discount: discount, admissionDue: admissionDue, total: total, paid: paid, balance: balance);
  }

  // ---- photo -----------------------------------------------------------------

  Future<void> _retakePhoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Camera', style: wt(Theme.of(ctx).textTheme.bodyMedium, weight: 600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Gallery', style: wt(Theme.of(ctx).textTheme.bodyMedium, weight: 600)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src == null || !mounted) return;
    final raw = await PhotoService.pick(src);
    if (raw == null || !mounted) return;
    final compressed = await PhotoService.compress(raw);
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CropScreen(imagePath: compressed)),
    );
    if (!mounted) return;
    setState(() => _photo = cropped ?? compressed);
  }

  // ---- save --------------------------------------------------------------------

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_courseRows.any((r) => r.courseId == null)) {
      setState(() => _courseError = true);
      _snack('Select a course for every row');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final jdNo = _isEdit ? widget.existing!.jdNo : await _state.nextJdNo();
    final now = Dates.todayStr();

    final student = Student(
      id: widget.existing?.id,
      jdNo: jdNo,
      name: _name.trim(),
      fatherName: _father.trim(),
      motherName: _mother.trim(),
      photoPath: _photo,
      permVillage: _pVillage.trim(),
      permPO: _pPO.trim(),
      permDist: _pDist.trim(),
      permPin: _pPin.trim(),
      corrSame: _corrSame,
      corrVillage: _corrSame ? '' : _cVillage.trim(),
      corrPO: _corrSame ? '' : _cPO.trim(),
      corrDist: _corrSame ? '' : _cDist.trim(),
      corrPin: _corrSame ? '' : _cPin.trim(),
      aadhar: _aadhar.trim(),
      dob: _dob != null ? Dates.fmt(_dob!) : '',
      gender: _gender,
      religion: _religion,
      nationality: _nationality,
      maritalStatus: _marital,
      mobile: _mobile.trim(),
      altMobile: _altMobile.trim(),
      admissionDate: Dates.fmt(_admissionDate),
      planId: _planId,
      admissionFeeEnabled: _admFeeEnabled,
      admissionFeePaid: _admFeeEnabled && _admFeePaid,
      isBlocked: widget.existing?.isBlocked ?? false,
      ptEnabled: widget.existing?.ptEnabled ?? false,
      ptSessions: widget.existing?.ptSessions ?? 0,
      ptSessionsDone: widget.existing?.ptSessionsDone ?? 0,
      ptSessionPrice: widget.existing?.ptSessionPrice ?? 0,
      ptPaid: widget.existing?.ptPaid ?? 0,
      ptTiming: widget.existing?.ptTiming ?? '',
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final scs = <StudentCourse>[];
    for (var i = 0; i < _courseRows.length; i++) {
      final r = _courseRows[i];
      final c = _state.courseById(r.courseId);
      scs.add(StudentCourse(
        studentId: student.id ?? 0,
        courseId: r.courseId!,
        batchId: r.batchId ?? 0,
        timingId: r.timingId ?? 0,
        isPrimary: i == 0,
        feeSnapshot: c?.fee ?? 0,
      ));
    }

    if (_isEdit) {
      final oldPlan = widget.existing!.planId;
      await _state.updateStudent(student, scs: scs);
      if (oldPlan != _planId && _planId != null) {
        await _state.recordPlanChange(student, oldPlan, _planId!);
      }
    } else {
      // Admission fee paid at admission?
      final initialLedger = <LedgerEntry>[];
      if (_admFeeEnabled && _admFeePaid && _state.admissionFeeAmount > 0) {
        initialLedger.add(LedgerEntry(
          studentId: 0,
          date: Dates.fmt(_admissionDate),
          type: LedgerType.admissionFeePaid,
          dueAmount: _state.admissionFeeAmount,
          paidAmount: _state.admissionFeeAmount,
          balanceOrCredit: 0,
          mode: _mode,
          note: 'Admission fee',
        ));
      }
      final saved = await _state.addStudent(student: student, scs: scs, initialLedger: initialLedger);

      // First membership payment (reuses the fee engine).
      if (_firstPaid > 0) {
        await _state.recordPayment(
          saved,
          months: _planMonths,
          discountType: _discountType,
          discountValue: _discountValue,
          paid: _firstPaid,
          mode: _mode,
          date: Dates.fmt(_admissionDate),
          note: 'First payment',
          withAdmission: false,
        );
      }
      if (!mounted) return;
      _state.requestPulse(saved.id!);
      // Welcome Kit.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => WelcomeKitSheet(
          student: saved,
          summary: _summary,
          planName: _state.planNameOf(saved),
          courseLine: _state.primaryCourseLine(saved),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    _snack('Saved');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- UI ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Member' : 'Add Details',
            style: wt(Theme.of(context).textTheme.titleMedium, weight: 700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scroller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _section('Personal Details'),
            _labelField('Name *', _name, (v) => _name = v,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
            _labelField('Father\'s Name', _father, (v) => _father = v),
            _labelField('Mother\'s Name', _mother, (v) => _mother = v),
            // Photo (retake)
            Row(
              children: [
                Avatar(photoPath: _photo.isEmpty ? null : _photo, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.gold),
                    label: Text('Retake photo',
                        style: wt(Theme.of(context).textTheme.labelMedium,
                            weight: 600, color: AppColors.gold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _labelField('Village', _pVillage, (v) => _pVillage = v),
            _labelField('P.O', _pPO, (v) => _pPO = v),
            Row(
              children: [
                Expanded(child: _labelField('District', _pDist, (v) => _pDist = v)),
                const SizedBox(width: 10),
                Expanded(
                  child: _labelField('PIN', _pPin, (v) => _pPin = v,
                      digits: true, maxLen: 6),
                ),
              ],
            ),
            // Correspondence address
            CheckboxListTile(
              value: _corrSame,
              activeColor: AppColors.gold,
              onChanged: (v) => setState(() => _corrSame = v ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('Correspondence address is same',
                  style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500)),
            ),
            if (!_corrSame) ...[
              _labelField('C. Village', _cVillage, (v) => _cVillage = v),
              _labelField('C. P.O', _cPO, (v) => _cPO = v),
              Row(
                children: [
                  Expanded(child: _labelField('C. District', _cDist, (v) => _cDist = v)),
                  const SizedBox(width: 10),
                  Expanded(child: _labelField('C. PIN', _cPin, (v) => _cPin = v, digits: true, maxLen: 6)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _section('Identity & Personal Info'),
            _labelField('Aadhar (optional)', _aadhar, (v) => _aadhar = v,
                digits: true,
                maxLen: 12,
                validator: (v) => Aadhar.valid(v ?? '') ? null : 'Aadhar must be 12 digits, not starting 0 or 1'),
            Row(
              children: [
                Expanded(child: _dobPicker()),
                const SizedBox(width: 10),
                Expanded(child: _genderPicker()),
              ],
            ),
            // Category AUTO chip (realtime)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text('Category: ', style: wt(Theme.of(context).textTheme.bodySmall, weight: 500)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(_categoryChip.isEmpty ? 'Auto from DOB' : _categoryChip,
                        style: wt(Theme.of(context).textTheme.labelMedium,
                            weight: 800, color: AppColors.gold)),
                  ),
                ],
              ),
            ),
            _labelField('Mobile *', _mobile, (v) => _mobile = v,
                digits: true,
                maxLen: 10,
                keyboard: TextInputType.phone,
                validator: (v) => Phones.valid(v ?? '') ? null : 'Enter a valid 10-digit mobile'),
            _labelField('Alt Mobile', _altMobile, (v) => _altMobile = v, digits: true, maxLen: 10),
            Row(
              children: [
                Expanded(child: _religionPicker()),
                const SizedBox(width: 10),
                Expanded(
                  child: _labelField('Nationality', _nationality, (v) => _nationality = v),
                ),
              ],
            ),
            _maritalPicker(),
            const SizedBox(height: 8),
            _section('Courses & Batch'),
            for (var i = 0; i < _courseRows.length; i++) _courseRow(i),
            if (_courseError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Select a course for every row',
                    style: wt(Theme.of(context).textTheme.bodySmall,
                        weight: 600, color: AppColors.expired)),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _courseRows.add(_CourseRow());
                  _courseError = false;
                }),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.gold),
                label: Text('Add another course',
                    style: wt(Theme.of(context).textTheme.labelMedium,
                        weight: 700, color: AppColors.gold)),
              ),
            ),
            const SizedBox(height: 8),
            _section('Fee Options'),
            // Admission fee
            if (_state.admissionFeeAmount > 0)
              Row(
                children: [
                  Checkbox(
                    value: _admFeeEnabled,
                    activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _admFeeEnabled = v ?? false),
                  ),
                  Expanded(
                    child: Text('Admission Fee ${Money.fmt(_state.admissionFeeAmount)}',
                        style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500)),
                  ),
                  if (_admFeeEnabled)
                    DropdownButton<String>(
                      value: _admFeePaid ? 'Yes' : 'No',
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'No', child: Text('Paid? No')),
                        DropdownMenuItem(value: 'Yes', child: Text('Paid? Yes')),
                      ],
                      onChanged: (v) => setState(() => _admFeePaid = v == 'Yes'),
                    ),
                ],
              ),
            // Plan
            _planPicker(),
            Row(
              children: [
                Expanded(
                  child: _labelField('First payment', _firstPaid == 0 ? '' : '$_firstPaid',
                      (v) => _firstPaid = int.tryParse(v) ?? 0,
                      digits: true,
                      hint: '₹ ${Money.fmt(_cyclePrice * _planMonths)}'),
                ),
                const SizedBox(width: 10),
                Expanded(child: _modeDropdown()),
              ],
            ),
            // Discount
            Row(
              children: [
                Text('Discount', style: wt(Theme.of(context).textTheme.labelMedium, weight: 600)),
                const SizedBox(width: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '₹', label: Text('₹')),
                    ButtonSegment(value: '%', label: Text('%')),
                  ],
                  selected: {_discountType},
                  onSelectionChanged: (s) => setState(() => _discountType = s.first),
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedForegroundColor: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _labelField('Value', _discountValue == 0 ? '' : '$_discountValue',
                      (v) => setState(() {
                        _discountValue = int.tryParse(v) ?? 0;
                        if (_discountType == '%' && _discountValue > 100) _discountValue = 100;
                      }),
                      digits: true,
                      hint: '0'),
                ),
              ],
            ),
            // Admission date
            Row(
              children: [
                Expanded(child: _admissionDatePicker()),
                const SizedBox(width: 10),
                // Live summary chip
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DUE NOW',
                            style: wt(Theme.of(context).textTheme.labelSmall,
                                weight: 700, color: AppColors.gold)),
                        const SizedBox(height: 2),
                        Text(Money.fmt(_summary.total),
                            style: wt(Theme.of(context).textTheme.titleMedium,
                                weight: 800, color: AppColors.gold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Save
            SizedBox(
              width: double.infinity,
              child: ScaleTap(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _saving ? AppColors.gold.withValues(alpha: 0.5) : AppColors.gold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBg),
                        )
                      : Text(_isEdit ? 'Save Changes' : 'Save & Continue',
                          style: wt(Theme.of(context).textTheme.labelLarge,
                              weight: 800, color: AppColors.darkBg)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- field builders ----------------------------------------------------------

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: SectionLabel(title),
    );
  }

  Widget _labelField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    String? Function(String?)? validator,
    bool digits = false,
    int? maxLen,
    TextInputType? keyboard,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: value,
        validator: validator,
        onChanged: onChanged,
        keyboardType: keyboard ?? (digits ? TextInputType.number : TextInputType.text),
        inputFormatters: [
          if (digits) FilteringTextInputFormatter.digitsOnly,
          if (maxLen != null) LengthLimitingTextInputFormatter(maxLen),
        ],
        decoration: InputDecoration(isDense: true, labelText: label, hintText: hint),
      ),
    );
  }

  Widget _dobPicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime(2005),
          firstDate: DateTime(1940),
          lastDate: DateTime.now(), // DOB not future
          helpText: 'Select date of birth',
        );
        if (picked != null) setState(() => _dob = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(isDense: true, labelText: 'DOB'),
        child: Text(
          _dob == null ? 'Select' : Dates.display(Dates.fmt(_dob!)),
          style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500),
        ),
      ),
    );
  }

  Widget _genderPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _gender.isEmpty ? null : _gender,
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
      ],
      onChanged: (v) => setState(() => _gender = v ?? ''),
      decoration: const InputDecoration(isDense: true, labelText: 'Gender'),
    );
  }

  Widget _religionPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _religion,
      items: [for (final r in kReligions) DropdownMenuItem(value: r, child: Text(r))],
      onChanged: (v) => setState(() => _religion = v ?? 'Hindu'),
      decoration: const InputDecoration(isDense: true, labelText: 'Religion'),
    );
  }

  Widget _maritalPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _marital,
      items: const [
        DropdownMenuItem(value: 'Unmarried', child: Text('Unmarried')),
        DropdownMenuItem(value: 'Married', child: Text('Married')),
      ],
      onChanged: (v) => setState(() => _marital = v ?? 'Unmarried'),
      decoration: const InputDecoration(isDense: true, labelText: 'Marital Status'),
    );
  }

  Widget _planPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<int?>(
        initialValue: _planId,
        items: [
          const DropdownMenuItem(value: null, child: Text('No plan')),
          for (final p in _state.plans)
            DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.months} mo${p.months == 1 ? '' : 's'}${p.discountValue > 0 ? ', ${p.discountValue}${p.discountType} off' : ''})')),
        ],
        onChanged: (v) => setState(() {
          _planId = v;
          final p = _state.planById(v);
          if (p != null && _discountValue == 0) {
            _discountType = p.discountType;
            _discountValue = p.discountValue;
          }
        }),
        decoration: const InputDecoration(isDense: true, labelText: 'Plan'),
      ),
    );
  }

  Widget _modeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _mode,
      items: const [
        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
      ],
      onChanged: (v) => setState(() => _mode = v ?? 'Cash'),
      decoration: const InputDecoration(isDense: true, labelText: 'Mode'),
    );
  }

  Widget _admissionDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _admissionDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          helpText: 'Date of admission',
        );
        if (picked != null) setState(() => _admissionDate = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(isDense: true, labelText: 'Admission Date'),
        child: Text(Dates.display(Dates.fmt(_admissionDate)),
            style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500)),
      ),
    );
  }

  Widget _courseRow(int index) {
    final r = _courseRows[index];
    final state = _state;
    final courses = state.courses;
    final batches = state.batches.where((b) => b.courseId == r.courseId).toList();
    final timings = state.timings.where((t) => t.batchId == r.batchId).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Course ${index + 1}${index == 0 ? ' (primary)' : ''}',
                  style: wt(Theme.of(context).textTheme.labelSmall,
                      weight: 700, color: index == 0 ? AppColors.gold : AppColors.greyIcon)),
              const Spacer(),
              if (_courseRows.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.greyIcon),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _courseRows.removeAt(index)),
                ),
            ],
          ),
          // Course dropdown
          InkWell(
            onTap: () async {
              final idx = await pickSearchableItem(
                context,
                title: 'Select Course',
                items: [for (final c in courses) '${c.name}  •  ${Money.fmt(c.fee)}/mo'],
              );
              if (idx != null) {
                setState(() {
                  r.courseId = courses[idx].id;
                  r.batchId = null;
                  r.timingId = null;
                  _courseError = false;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(isDense: true, labelText: 'Course'),
              child: Text(
                r.courseId == null
                    ? 'Select'
                    : '${state.courseById(r.courseId)?.name ?? ''}  •  ${Money.fmt(state.courseById(r.courseId)?.fee ?? 0)}/mo',
                style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Batch dropdown
              Expanded(
                child: InkWell(
                  onTap: r.courseId == null
                      ? null
                      : () async {
                          final idx = await pickSearchableItem(
                            context,
                            title: 'Select Batch',
                            items: [
                              for (final b in batches) b.daysInfo.isEmpty ? b.name : '${b.name}  •  ${b.daysInfo}',
                            ],
                          );
                          if (idx != null) {
                            setState(() {
                              r.batchId = batches[idx].id;
                              r.timingId = null;
                            });
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Batch',
                      enabled: r.courseId != null,
                    ),
                    child: Text(
                      r.batchId == null ? 'Select' : state.batchById(r.batchId)?.name ?? '',
                      style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Timing dropdown
              Expanded(
                child: InkWell(
                  onTap: r.batchId == null
                      ? null
                      : () async {
                          final idx = await pickSearchableItem(
                            context,
                            title: 'Select Timing',
                            items: [
                              for (final t in timings)
                                t.startTime.isNotEmpty
                                    ? '${t.label}  •  ${t.startTime}-${t.endTime}'
                                    : t.label,
                            ],
                          );
                          if (idx != null) {
                            setState(() => r.timingId = timings[idx].id);
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Timing',
                      enabled: r.batchId != null,
                    ),
                    child: Text(
                      r.timingId == null ? 'Select' : state.timingById(r.timingId)?.label ?? '',
                      style: wt(Theme.of(context).textTheme.bodyMedium, weight: 500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseRow {
  int? courseId;
  int? batchId;
  int? timingId;
  _CourseRow({this.courseId, this.batchId, this.timingId});
}
