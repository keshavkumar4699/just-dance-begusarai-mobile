/// Just Dance — TAB 3: ＋ ADD MEMBER.
/// Photo sheet (Camera / Gallery / Photo Later) -> square crop -> ADD DETAILS
/// form -> save -> ledger -> backup -> WELCOME KIT sheet -> Home (card pulses).
/// Also used in edit mode (existing student -> skips the photo sheet).
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/fee_engine.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../services/card_images.dart';
import '../../services/invoice_pdf.dart';
import '../../services/photo_service.dart';
import '../../services/share_service.dart';
import '../../services/whatsapp_service.dart';
import '../home_shell.dart';
import '../widgets/common.dart';
import 'crop_screen.dart';

/// Entry point from the center ＋ button (or Edit on a student).
/// New members: ONE continuous bottom sheet (photo -> crop -> details form),
/// then Home switches + scrolls to the pulsing new card, and a reliable
/// "New member created" full-width bottom sheet offers WhatsApp welcome /
/// ID / invoice actions.
Future<void> showAddMemberFlow(BuildContext context, AppStore store,
    {Student? existing, HomeShellState? shell}) async {
  if (existing != null) {
    await Navigator.push(
        context, fadeSlideRoute(AddDetailsPage(store: store, existing: existing)));
    return;
  }

  final newStudent = await showAppSheet<Student>(
    context,
    _AdmissionSheet(store: store),
  );
  if (newStudent == null || !context.mounted) return;

  // Let the admission sheet's close animation finish before showing popup.
  await Future.delayed(const Duration(milliseconds: 300));
  if (!context.mounted) return;

  // Home first: switch to Home tab so the new card is visible behind the dialog.
  final shellState = shell ?? HomeShell.of(context);
  store.pulseStudentId = newStudent.id;
  shellState?.goTo(0);

  // Then the "New member created" popup with WhatsApp/invoice actions.
  await showAppSheet<void>(
    context,
    _WelcomeSheet(store: store, studentId: newStudent.id),
    isDismissible: false,
  );

  // Scroll to the new student card once the dialog is completed.
  if (context.mounted) {
    shellState?.scrollToStudent(newStudent.id);
  }
}

/// The continuous admission sheet: photo choice -> crop -> details form.
class _AdmissionSheet extends StatefulWidget {
  final AppStore store;
  const _AdmissionSheet({required this.store});

  @override
  State<_AdmissionSheet> createState() => _AdmissionSheetState();
}

class _AdmissionSheetState extends State<_AdmissionSheet> {
  int _step = 0; // 0 photo, 1 crop, 2 form
  Uint8List? _bytes;
  String _photoPath = '';

  AppStore get store => widget.store;

  Future<void> _pick(ImageSource source) async {
    store.suppressLock = true;
    XFile? picked;
    try {
      picked = await PhotoService.instance.pick(source);
    } finally {
      store.suppressLock = false;
    }
    if (!mounted) return;
    if (picked == null) {
      showSnack(context, 'No photo selected — you can add it later',
          duration: kSnackInfo);
      setState(() => _step = 2);
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _step = 1;
    });
  }

  Future<void> _cropDone(ui.Rect? crop) async {
    final bytes = _bytes;
    if (bytes != null) {
      final saved = await PhotoService.instance.saveCompressed(bytes, crop: crop);
      _photoPath = saved;
    }
    if (mounted) setState(() => _step = 2);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.hairline, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: switch (_step) {
                0 => _photoStep(c),
                1 => CropView(bytes: _bytes!, onDone: _cropDone),
                _ => AddDetailsPage(
                    store: store,
                    photoPath: _photoPath,
                    embedded: true,
                    onSaved: (s) => Navigator.pop(context, s),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoStep(AppColors c) {
    Widget option(IconData icon, String label, ImageSource? source) =>
        Pressable(
          onTap: () {
            if (source == null) {
              setState(() => _step = 2);
            } else {
              _pick(source);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: c.gold, size: 22),
                const SizedBox(width: 14),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        );
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          option(Icons.photo_camera_outlined, 'Camera', ImageSource.camera),
          option(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery),
          option(Icons.person_outline, 'Photo Later', null),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PhotoChoice {
  final ImageSource? source; // null => Photo Later
  const _PhotoChoice(this.source);
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget option(IconData icon, String label, ImageSource? source) =>
        Pressable(
          onTap: () => Navigator.pop(context, _PhotoChoice(source)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: c.gold, size: 22),
                const SizedBox(width: 14),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: c.hairline, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          option(Icons.photo_camera_outlined, 'Camera', ImageSource.camera),
          option(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery),
          option(Icons.person_outline, 'Photo Later', null),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CourseSel {
  int courseId;
  int batchId;
  Set<int> selectedInterests;
  bool isPrimary;
  _CourseSel({
    this.courseId = 0,
    this.batchId = 0,
    Set<int>? selectedInterests,
    this.isPrimary = false,
  }) : selectedInterests = selectedInterests ?? {};

  String get interestsCsv => selectedInterests.join(',');
}

class AddDetailsPage extends StatefulWidget {
  final AppStore store;
  final String photoPath;
  final Student? existing;
  /// When true the form renders inside the admission sheet (no Scaffold);
  /// [onSaved] receives the created student instead of popping a route.
  final bool embedded;
  final ValueChanged<Student>? onSaved;
  const AddDetailsPage(
      {super.key,
      required this.store,
      this.photoPath = '',
      this.existing,
      this.embedded = false,
      this.onSaved});

  @override
  State<AddDetailsPage> createState() => _AddDetailsPageState();
}

class _AddDetailsPageState extends State<AddDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Membership type
  late bool _ptMode;
  late final TextEditingController _ptTiming;
  late String _ptDays;
  late final TextEditingController _ptPrice;
  late final TextEditingController _ptRecharge;

  // Personal
  late final TextEditingController _name;
  late final TextEditingController _father;
  late final TextEditingController _mother;
  late String _photoPath;
  // Address
  late final TextEditingController _permVillage;
  late final TextEditingController _permPO;
  late final TextEditingController _permDist;
  late final TextEditingController _permPin;
  late bool _corrSame;
  late final TextEditingController _corrVillage;
  late final TextEditingController _corrPO;
  late final TextEditingController _corrDist;
  late final TextEditingController _corrPin;
  // Identity
  late final TextEditingController _aadhar;
  DateTime? _dob;
  late String _gender;
  late String _religion;
  late final TextEditingController _nationality;
  late String _marital;
  // Contact
  late final TextEditingController _mobile;
  late final TextEditingController _altMobile;
  // Courses
  late List<_CourseSel> _courses;
  // Fees
  late bool _admissionFeeEnabled;
  bool _admissionFeePrepaid = false;
  int? _planId;
  late final TextEditingController _firstPayment;
  String _mode = kModeCash;
  late final TextEditingController _discount;
  bool _discountPercent = false;
  late DateTime _admissionDate;

  AppStore get store => widget.store;
  bool get isEdit => widget.existing != null;
  bool get isEmbedded => widget.embedded;

  static const religions = [
    'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Parsi',
    'Jewish', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _ptMode = e?.ptEnabled ?? false;
    _ptTiming = TextEditingController(text: e?.ptTiming ?? '');
    _ptDays = e?.ptDays.isNotEmpty == true
        ? e!.ptDays
        : (store.ptDefaultDays.isNotEmpty ? store.ptDefaultDays : '');
    _ptPrice = TextEditingController(
        text: (e?.ptSessionPrice ?? store.ptDefaultSessionPrice) == 0
            ? ''
            : (e?.ptSessionPrice ?? store.ptDefaultSessionPrice)
                .toStringAsFixed(0));
    _ptRecharge = TextEditingController();
    _admissionFeeEnabled = e?.admissionFeeEnabled ?? true;
    _name = TextEditingController(text: e?.name ?? '');
    _father = TextEditingController(text: e?.fatherName ?? '');
    _mother = TextEditingController(text: e?.motherName ?? '');
    _photoPath = e?.photoPath ?? widget.photoPath;
    _permVillage = TextEditingController(text: e?.permVillage ?? '');
    _permPO = TextEditingController(text: e?.permPO ?? '');
    _permDist = TextEditingController(text: e?.permDist ?? '');
    _permPin = TextEditingController(text: e?.permPin ?? '');
    _corrSame = e?.corrSame ?? true;
    _corrVillage = TextEditingController(text: e?.corrVillage ?? '');
    _corrPO = TextEditingController(text: e?.corrPO ?? '');
    _corrDist = TextEditingController(text: e?.corrDist ?? '');
    _corrPin = TextEditingController(text: e?.corrPin ?? '');
    _aadhar = TextEditingController(text: e?.aadhar ?? '');
    _dob = e?.dob;
    _gender = e?.gender ?? '';
    _religion = e?.religion ?? '';
    _nationality = TextEditingController(text: e?.nationality ?? 'Indian');
    _marital = e?.maritalStatus ?? '';
    _mobile = TextEditingController(text: e?.mobile ?? '');
    _altMobile = TextEditingController(text: e?.altMobile ?? '');
    _planId = e?.planId ?? (store.plans.isEmpty ? null : store.plans.first.id);
    if (_planId != null && !store.plans.any((p) => p.id == _planId)) {
      _planId = null;
    }
    _firstPayment = TextEditingController();
    _discount = TextEditingController();
    _admissionDate = e?.admissionDate ?? DateTime.now();
    if (e != null) {
      final scs = store.coursesOf(e.id);
      _courses = scs
          .map((sc) => _CourseSel(
                courseId: sc.courseId,
                batchId: sc.batchId,
                selectedInterests: sc.interests.isNotEmpty
                    ? sc.interests
                        .split(',')
                        .map((x) => int.tryParse(x.trim()))
                        .whereType<int>()
                        .toSet()
                    : <int>{},
                isPrimary: sc.isPrimary,
              ))
          .toList();
      for (final sel in _courses) {
        if (!store.courses.any((x) => x.id == sel.courseId)) {
          sel.courseId = 0;
          sel.batchId = 0;
          sel.selectedInterests.clear();
        }
      }
      if (_courses.isEmpty) _courses = [_CourseSel(isPrimary: true)];
    } else {
      _courses = [_CourseSel(isPrimary: true)];
    }
  }

  @override
  void dispose() {
    for (final c in [
      _ptTiming, _ptPrice, _ptRecharge,
      _name, _father, _mother, _permVillage, _permPO, _permDist, _permPin,
      _corrVillage, _corrPO, _corrDist, _corrPin, _aadhar, _nationality,
      _mobile, _altMobile, _firstPayment, _discount,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _cyclePrice {
    var sum = 0.0;
    for (final sel in _courses) {
      sum += store.courseById(sel.courseId)?.fee ?? 0;
    }
    return sum;
  }

  double get _ptPriceVal => double.tryParse(_ptPrice.text.trim()) ?? 0;

  double get _ptRechargeVal => double.tryParse(_ptRecharge.text.trim()) ?? 0;

  /// Sessions the submitted recharge allocates at the current session price.
  int get _ptAllocatedSessions =>
      _ptPriceVal > 0 ? (_ptRechargeVal / _ptPriceVal).floor() : 0;

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _togglePtDay(String day) {
    final days = _ptDays.isEmpty
        ? <String>[]
        : _ptDays.split(',').where((e) => e.isNotEmpty).toList();
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    setState(() => _ptDays = days.join(','));
  }

  double get _planGross =>
      (store.planById(_planId)?.months ?? 1) * _cyclePrice;

  double get _discountValue {
    final raw = double.tryParse(_discount.text.trim()) ?? 0;
    if (raw <= 0) return 0;
    final d = _discountPercent ? _planGross * raw / 100 : raw;
    return d.clamp(0.0, _planGross);
  }

  PlanFeeCalc get _planCalc => FeeEngine.calculatePlanFee(
        monthlyFee: _cyclePrice,
        planMonths: store.planById(_planId)?.months ?? 1,
        discountType: store.planById(_planId)?.discountType ?? '',
        discountValue: store.planById(_planId)?.discountValue ?? 0,
        manualDiscount: _discountValue,
      );

  double get _totalCommitted {
    final plan = store.planById(_planId);
    final months = plan?.months ?? 1;
    final gross = _cyclePrice * months;
    final calc = FeeEngine.calculatePlanFee(
      monthlyFee: _cyclePrice,
      planMonths: months,
      discountType: plan?.discountType ?? '',
      discountValue: plan?.discountValue ?? 0,
      manualDiscount: 0,
    );
    final adm = (_admissionFeeEnabled && !_admissionFeePrepaid) ? store.admissionFeeAmount : 0.0;
    return (gross - calc.multipleMonthsDiscount + adm).clamp(0.0, double.infinity);
  }

  Future<void> _retakePhoto() async {
    final choice = await showAppSheet<_PhotoChoice>(
        context, const _PhotoSourceSheet(),
        isScrollControlled: false);
    if (choice == null || choice.source == null || !mounted) return;
    widget.store.suppressLock = true;
    XFile? picked;
    try {
      picked = await PhotoService.instance.pick(choice.source!);
    } finally {
      widget.store.suppressLock = false;
    }
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final crop = await CropScreen.push(context, bytes);
    final saved = await PhotoService.instance
        .saveCompressed(bytes, crop: crop, fallbackPath: picked.path);
    setState(() => _photoPath = saved);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_dob != null && validateDob(_dob) != null) {
      showSnack(context, validateDob(_dob)!, duration: kSnackWarn);
      return;
    }
    setState(() => _saving = true);
    try {
      if (isEdit) {
        await _saveEdit();
        return;
      }
      final s = Student(
        name: _name.text.trim(),
        fatherName: _father.text.trim(),
        motherName: _mother.text.trim(),
        photoPath: _photoPath,
        permVillage: _permVillage.text.trim(),
        permPO: _permPO.text.trim(),
        permDist: _permDist.text.trim(),
        permPin: _permPin.text.trim(),
        corrSame: _corrSame,
        corrVillage: _corrSame ? '' : _corrVillage.text.trim(),
        corrPO: _corrSame ? '' : _corrPO.text.trim(),
        corrDist: _corrSame ? '' : _corrDist.text.trim(),
        corrPin: _corrSame ? '' : _corrPin.text.trim(),
        aadhar: _aadhar.text.trim(),
        dob: _dob,
        gender: _gender,
        religion: _religion,
        nationality: _nationality.text.trim().isEmpty
            ? 'Indian'
            : _nationality.text.trim(),
        maritalStatus: _marital,
        mobile: normalizeMobile(_mobile.text),
        altMobile: normalizeMobile(_altMobile.text),
        admissionDate: _admissionDate,
        planId: _ptMode ? null : _planId,
        admissionFeeEnabled: _admissionFeeEnabled,
        admissionFeeAmount: store.admissionFeeAmount,
        ptEnabled: _ptMode,
        ptTiming: _ptMode ? _ptTiming.text.trim() : '',
        ptDays: _ptMode ? _ptDays : '',
        ptSessionPrice: _ptMode ? _ptPriceVal : 0,
        ptSessions: _ptMode ? _ptAllocatedSessions : 0,
      );
      final scs = _ptMode
          ? <StudentCourse>[]
          : _courses
              .where((e) => e.courseId != 0)
              .map((e) => StudentCourse(
                  courseId: e.courseId,
                  batchId: e.batchId,
                  interests: e.interestsCsv,
                  isPrimary: e.isPrimary))
              .toList();
      await store.addStudent(s, scs);

      if (_ptMode) {
        // Recharge: the submitted amount allocates sessions immediately.
        final recharge = _ptRechargeVal;
        if (recharge > 0) {
          await store.recordPtPayment(s, recharge, _mode);
        }
      } else {
        // 1. If admission fee was already paid earlier on back-date, record it dated on admission date:
        if (_admissionFeeEnabled && _admissionFeePrepaid) {
          await store.markAdmissionFeePaid(s, date: _admissionDate, mode: _mode);
        }

        // 2. Snapshot the initial plan term:
        if (_planId != null) {
          final plan = store.planById(_planId);
          final planMonths = plan?.months ?? 1;
          final calc = FeeEngine.calculatePlanFee(
            monthlyFee: _cyclePrice,
            planMonths: planMonths,
            discountType: plan?.discountType ?? '',
            discountValue: plan?.discountValue ?? 0,
            manualDiscount: _discountValue,
          );
          await store.addPlanTerm(
            s: s,
            months: planMonths,
            cyclePrice: _cyclePrice,
            discount: calc.multipleMonthsDiscount,
            date: _admissionDate,
            note: plan?.name ?? '',
          );
        }

        // 3. First payment + manual discount:
        final first = double.tryParse(_firstPayment.text.trim()) ?? 0;
        if (first > 0 || _discountValue > 0) {
          await store.addPayment(
            s: s,
            amount: first,
            planId: _planId,
            manualDiscount: _discountValue,
            mode: _mode,
            note: 'Admission',
            date: _admissionDate,
          );
        }
      }

      if (!mounted) return;
      if (isEmbedded) {
        widget.onSaved?.call(s);
      } else {
        Navigator.pop(context, s);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEdit() async {
    final e = widget.existing!;
    e.name = _name.text.trim();
    e.fatherName = _father.text.trim();
    e.motherName = _mother.text.trim();
    e.photoPath = _photoPath;
    e.permVillage = _permVillage.text.trim();
    e.permPO = _permPO.text.trim();
    e.permDist = _permDist.text.trim();
    e.permPin = _permPin.text.trim();
    e.corrSame = _corrSame;
    e.corrVillage = _corrSame ? '' : _corrVillage.text.trim();
    e.corrPO = _corrSame ? '' : _corrPO.text.trim();
    e.corrDist = _corrSame ? '' : _corrDist.text.trim();
    e.corrPin = _corrSame ? '' : _corrPin.text.trim();
    e.aadhar = _aadhar.text.trim();
    e.dob = _dob;
    e.gender = _gender;
    e.religion = _religion;
    e.nationality =
        _nationality.text.trim().isEmpty ? 'Indian' : _nationality.text.trim();
    e.maritalStatus = _marital;
    e.mobile = normalizeMobile(_mobile.text);
    e.altMobile = normalizeMobile(_altMobile.text);
    e.admissionDate = _admissionDate;
    if (_planId != e.planId && _planId != null) {
      await store.changePlan(e, _planId!);
    }
    e.admissionFeeEnabled = _admissionFeeEnabled;
    e.ptEnabled = _ptMode;
    e.ptTiming = _ptMode ? _ptTiming.text.trim() : '';
    e.ptDays = _ptMode ? _ptDays : '';
    e.ptSessionPrice = _ptMode ? _ptPriceVal : 0;
    final scs = _courses
        .where((x) => x.courseId != 0)
        .map((x) => StudentCourse(
            courseId: x.courseId,
            batchId: x.batchId,
            interests: x.interestsCsv,
            isPrimary: x.isPrimary))
        .toList();
    await store.updateStudent(e, sc: scs);
    if (mounted) {
      Navigator.pop(context);
      showSnack(context, '${e.name} updated', duration: kSnackSuccess);
    }
  }



  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final form = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: isEmbedded
              ? const EdgeInsets.fromLTRB(20, 4, 20, 32)
              : const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (isEmbedded) ...[
              Row(
                children: [
                  Expanded(
                    child: Text('Add Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            _photoHeader(c),
            _membershipTypeSection(c),
            const SectionLabel('Personal Details'),
              const FieldLabel('Name *'),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  controller: _name,
                  validator: validateName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Full name')),
              const FieldLabel("Father's Name"),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  controller: _father,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: "Father's name")),
              const FieldLabel("Mother's Name"),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  controller: _mother,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: "Mother's name")),
              const FieldLabel('Mobile *'),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                controller: _mobile,
                validator: validateMobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    hintText: '10-digit mobile', counterText: ''),
              ),
              if (_mobile.text.trim().length == 10 &&
                  store.mobileExists(normalizeMobile(_mobile.text),
                      exceptId: widget.existing?.id))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.nearExpiry.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠ Another member already has this number',
                      style: TextStyle(color: c.nearExpiry, fontSize: 12),
                    ),
                  ),
                ),
              const FieldLabel('Alternate Mobile'),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                controller: _altMobile,
                validator: (v) => validateMobile(v, required: false),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                    hintText: 'Optional', counterText: ''),
              ),
              const FieldLabel('Permanent Address'),
              _addressFields(_permVillage, _permPO, _permDist, _permPin),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: c.gold,
                checkColor: Colors.black,
                title: const Text('Correspondence address is same',
                    style: TextStyle(fontSize: 13.5)),
                value: _corrSame,
                onChanged: (v) => setState(() => _corrSame = v ?? true),
              ),
              if (!_corrSame) ...[
                const FieldLabel('Correspondence Address'),
                _addressFields(_corrVillage, _corrPO, _corrDist, _corrPin),
              ],
              const SizedBox(height: 12),
              const SectionLabel('Identity & Personal Info'),
              const FieldLabel('Aadhar (optional)'),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                controller: _aadhar,
                validator: validateAadhar,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: const InputDecoration(
                    hintText: '12-digit Aadhar', counterText: ''),
              ),
              const FieldLabel('Date of Birth'),
              DateField(
                value: _dob,
                hint: 'Pick date of birth',
                lastDate: DateTime.now(),
                onPicked: (d) => setState(() => _dob = d),
              ),
              if (_dob != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip(c, 'Age ${ageFromDob(_dob)}'),
                    const SizedBox(width: 8),
                    _infoChip(c, categoryFor(_dob, _gender)),
                  ],
                ),
              ],
              const FieldLabel('Gender'),
              Row(
                children: [
                  for (final g in const ['Male', 'Female'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: _gender == g,
                        onSelected: (_) => setState(() => _gender = g),
                      ),
                    ),
                ],
              ),
              const FieldLabel('Religion'),
              AppDropdown<String>(
                value: _religion.isEmpty ? null : _religion,
                hint: 'Select religion',
                items: [
                  for (final r in religions)
                    DropdownMenuItem(value: r, child: Text(r))
                ],
                onChanged: (v) => setState(() => _religion = v ?? ''),
              ),
              const FieldLabel('Nationality'),
              TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                  controller: _nationality,
                  decoration: const InputDecoration(hintText: 'Indian')),
              const FieldLabel('Marital Status'),
              Row(
                children: [
                  for (final m in const ['Married', 'Unmarried'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m),
                        selected: _marital == m,
                        onSelected: (_) => setState(() => _marital = m),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_ptMode) _ptSection(c) else _coursesSection(c),
              const SizedBox(height: 12),
              _feesSection(c),
              const SizedBox(height: 24),
              GoldButton(
                isEdit ? 'Save Changes' : 'Add Member',
                icon: Icons.check,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      );
    if (isEmbedded) return form;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Member' : 'Add Member')),
      body: form,
    );
  }

  Widget _photoHeader(AppColors c) {
    return Center(
      child: Pressable(
        onTap: _retakePhoto,
        child: Stack(
          children: [
            SquircleAvatar(
                photoPath: _photoPath, name: _name.text, size: 96, radius: 28),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: c.gold, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera_outlined,
                    size: 14, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Course vs Personal Training — seamless switch at admission.
  Widget _membershipTypeSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Membership Type'),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final (label, v) in const [
              ('Course', false),
              ('Personal Training', true),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: _ptMode == v,
                  onSelected: (_) => setState(() => _ptMode = v),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// PT fields: timing, days, charge/session (Schedule default prefill) and
  /// the recharge amount that allocates sessions immediately.
  Widget _ptSection(AppColors c) {
    final sessions = _ptAllocatedSessions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Personal Training'),
        const FieldLabel('Session timing'),
        TextFormField(
          controller: _ptTiming,
          scrollPadding: const EdgeInsets.only(bottom: 200),
          decoration: const InputDecoration(hintText: 'e.g. 7–8 AM'),
        ),
        const FieldLabel('Days'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final day in _weekDays)
              ChoiceChip(
                label: Text(day),
                selected: _ptDays.split(',').contains(day),
                onSelected: (_) => _togglePtDay(day),
              ),
          ],
        ),
        if (store.ptDefaultDuration.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Session duration: ${store.ptDefaultDuration}',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ),
        const FieldLabel('Charge per session (₹)'),
        TextFormField(
          controller: _ptPrice,
          scrollPadding: const EdgeInsets.only(bottom: 200),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. 500'),
        ),
        const FieldLabel('Recharge amount (₹)'),
        TextFormField(
          controller: _ptRecharge,
          scrollPadding: const EdgeInsets.only(bottom: 200),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. 5000'),
        ),
        if (_ptPriceVal > 0 && _ptRechargeVal > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$sessions session${sessions == 1 ? '' : 's'} will be allocated from this recharge',
              style: TextStyle(
                  color: c.gold, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _infoChip(AppColors c, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: c.goldSoft, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: c.gold, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _addressFields(TextEditingController village, TextEditingController po,
      TextEditingController dist, TextEditingController pin) {
    return Column(
      children: [
        TextField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
            controller: village,
            decoration: const InputDecoration(hintText: 'Village / Town')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: TextField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                    controller: po,
                    decoration: const InputDecoration(hintText: 'P.O'))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
                    controller: dist,
                    decoration: const InputDecoration(hintText: 'District'))),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 200),
            controller: pin,
            validator: validatePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration:
                const InputDecoration(hintText: 'PIN', counterText: '')),
      ],
    );
  }

  Widget _coursesSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Courses & Batch',
            trailing: TextButton.icon(
              onPressed: () => setState(() => _courses.add(_CourseSel())),
              icon: Icon(Icons.add, size: 16, color: c.gold),
              label: Text('Add course',
                  style: TextStyle(color: c.gold, fontSize: 12)),
            )),
        if (store.courses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No courses yet — create them in Profile → Courses, Batches, Timings & Plans.',
              style: TextStyle(color: c.nearExpiry, fontSize: 12),
            ),
          ),
        for (var i = 0; i < _courses.length; i++) _courseRow(c, i),
      ],
    );
  }

  Widget _courseRow(AppColors c, int i) {
    final sel = _courses[i];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppDropdown<int>(
                  value: store.courses.any((x) => x.id == sel.courseId)
                      ? sel.courseId
                      : null,
                  hint: 'Course',
                  items: [
                    for (final course in store.courses)
                      DropdownMenuItem(
                          value: course.id,
                          child: Text(
                              '${course.name} · ${fmtMoney(course.fee)}/mo',
                              overflow: TextOverflow.ellipsis))
                  ],
                  onChanged: (v) => setState(() {
                    sel.courseId = v ?? 0;
                    sel.batchId = 0;
                    sel.selectedInterests.clear();
                    if (_courses.every((e) => !e.isPrimary)) {
                      sel.isPrimary = true;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () => setState(() {
                  for (final e in _courses) {
                    e.isPrimary = false;
                  }
                  sel.isPrimary = true;
                }),
                child: Icon(
                  sel.isPrimary ? Icons.star : Icons.star_outline,
                  color: sel.isPrimary ? c.gold : c.textMuted,
                  size: 22,
                ),
              ),
              if (_courses.length > 1)
                Pressable(
                  onTap: () => setState(() {
                    final wasPrimary = sel.isPrimary;
                    _courses.removeAt(i);
                    if (wasPrimary && _courses.isNotEmpty) {
                      _courses.first.isPrimary = true;
                    }
                  }),
                  child: Icon(Icons.close, color: c.textMuted, size: 20),
                ),
            ],
          ),
          if (sel.courseId != 0) ...[
            const SizedBox(height: 8),
            AppDropdown<int>(
              value: (sel.batchId == kBatchWeekend || sel.batchId == kBatchWeekdays)
                  ? sel.batchId
                  : null,
              hint: 'Batch',
              items: const [
                DropdownMenuItem(
                    value: kBatchWeekend,
                    child: Text('Weekend (Sat–Sun, 2 hours)')),
                DropdownMenuItem(
                    value: kBatchWeekdays,
                    child: Text('Weekdays (Mon–Fri, 1 hour)')),
              ],
              onChanged: (v) => setState(() {
                sel.batchId = v ?? 0;
              }),
            ),
            Builder(builder: (_) {
              final availableInterests = store.interestsOf(sel.courseId);
              if (availableInterests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Interests', style: TextStyle(color: c.textMuted, fontSize: 11.5)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final interest in availableInterests)
                        FilterChip(
                          label: Text(interest.name),
                          selected: sel.selectedInterests.contains(interest.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              sel.selectedInterests.add(interest.id);
                            } else {
                              sel.selectedInterests.remove(interest.id);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _feesSection(AppColors c) {
    final cycles = FeeEngine.cyclesStarted(_admissionDate, DateTime.now());
    final isBackDated = dateOnly(_admissionDate).isBefore(dateOnly(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Admission & Fee Options'),
        const FieldLabel('Date of Admission'),
        DateField(
          value: _admissionDate,
          hint: 'Pick date',
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          onPicked: (d) => setState(() => _admissionDate = d),
        ),
        if (isBackDated && !_ptMode && _cyclePrice > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.nearExpiry.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.nearExpiry.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Back-dated Admission: $cycles billing ${cycles == 1 ? 'cycle' : 'cycles'} elapsed',
                    style: TextStyle(
                      color: c.nearExpiry,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admission Date: ${fmtDate(_admissionDate, forceYear: true)} · Total cycle fees till today: ${fmtMoney(cycles * _cyclePrice)}',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: c.gold,
          title: Text(
              'Admission Fee ${store.admissionFeeAmount > 0 ? '(${fmtMoney(store.admissionFeeAmount)})' : ''}',
              style: const TextStyle(fontSize: 14)),
          subtitle: store.admissionFeeAmount <= 0
              ? Text('Set the amount in Profile first',
                  style: TextStyle(color: c.nearExpiry, fontSize: 11.5))
              : Text('Charged only when the toggle is ON',
                  style: TextStyle(color: c.textMuted, fontSize: 11.5)),
          value: _admissionFeeEnabled,
          onChanged: (v) => setState(() => _admissionFeeEnabled = v),
        ),
        if (isBackDated && _admissionFeeEnabled && !isEdit) ...[
          const SizedBox(height: 4),
          const FieldLabel('Admission fee already paid?'),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Not paid'),
                selected: !_admissionFeePrepaid,
                onSelected: (_) => setState(() => _admissionFeePrepaid = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Paid earlier (back-date)'),
                selected: _admissionFeePrepaid,
                onSelected: (_) => setState(() => _admissionFeePrepaid = true),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        if (_ptMode) ...[
          if (!isEdit) ...[
            const FieldLabel('Recharge mode'),
            Row(
              children: [
                for (final m in const [kModeCash, kModeUpi])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m),
                      selected: _mode == m,
                      onSelected: (_) => setState(() => _mode = m),
                    ),
                  ),
              ],
            ),
          ],
        ] else ...[
          const FieldLabel('Plan'),
          AppDropdown<int>(
            value: _planId != null && store.plans.any((p) => p.id == _planId)
                ? _planId
                : null,
            hint:
                store.plans.isEmpty ? 'Create plans in Profile' : 'Select plan',
            items: [
              for (final p in store.plans)
                DropdownMenuItem(
                    value: p.id,
                    child: Text(
                        '${p.name} · ${p.months}mo${p.discountValue > 0 ? ' · off ${p.discountType == 'percent' ? '${p.discountValue.toStringAsFixed(0)}%' : fmtMoney(p.discountValue)}' : ''}'))
            ],
            onChanged: (v) => setState(() => _planId = v),
          ),
          if (_cyclePrice > 0 && _planId != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Commitment: ${store.planById(_planId)?.name ?? ''} (${store.planById(_planId)?.months ?? 1}mo)',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fmtMoney(_cyclePrice)}/mo × ${store.planById(_planId)?.months ?? 1} = ${fmtMoney(_planGross)}'
                    '${_planCalc.multipleMonthsDiscount > 0 ? ' − ${fmtMoney(_planCalc.multipleMonthsDiscount)} (plan disc)' : ''}'
                    '${_admissionFeeEnabled && !_admissionFeePrepaid ? ' + ${fmtMoney(store.admissionFeeAmount)} (admission)' : ''}'
                    ' = Total ${fmtMoney(_totalCommitted)} (due if unpaid)',
                    style: TextStyle(
                        color: c.textMuted, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          if (!isEdit) ...[
            const FieldLabel('First payment (₹)'),
            TextFormField(
              scrollPadding: const EdgeInsets.only(bottom: 200),
              controller: _firstPayment,
              validator: (v) => validateAmount(v, required: false),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
            ),
            if (!_ptMode && _cyclePrice > 0) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: Text(
                      'Full Plan (${fmtMoney(_totalCommitted)})',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => setState(() {
                      _firstPayment.text = _totalCommitted.round().toString();
                    }),
                  ),
                  if (isBackDated && cycles > 1)
                    ActionChip(
                      label: Text(
                        'All $cycles cycles (${fmtMoney(cycles * _cyclePrice + (_admissionFeeEnabled && !_admissionFeePrepaid ? store.admissionFeeAmount : 0))})',
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => setState(() {
                        final total = (cycles * _cyclePrice +
                                (_admissionFeeEnabled && !_admissionFeePrepaid
                                    ? store.admissionFeeAmount
                                    : 0))
                            .round();
                        _firstPayment.text = total.toString();
                      }),
                    ),
                  ActionChip(
                    label: Text(
                      '1 Month (${fmtMoney(_cyclePrice + (_admissionFeeEnabled && !_admissionFeePrepaid ? store.admissionFeeAmount : 0))})',
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => setState(() {
                      final total = (_cyclePrice +
                              (_admissionFeeEnabled && !_admissionFeePrepaid
                                  ? store.admissionFeeAmount
                                  : 0))
                          .round();
                      _firstPayment.text = total.toString();
                    }),
                  ),
                ],
              ),
            ],
            const FieldLabel('Mode'),
            Row(
              children: [
                for (final m in const [kModeCash, kModeUpi])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m),
                      selected: _mode == m,
                      onSelected: (_) => setState(() => _mode = m),
                    ),
                  ),
              ],
            ),
            const FieldLabel('Discount at admission'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 200),
                    controller: _discount,
                    validator: (v) => validateDiscount(v,
                        isPercent: _discountPercent, due: _planGross),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                        hintText: '0',
                        prefixText: _discountPercent ? '' : '₹ '),
                  ),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  constraints:
                      const BoxConstraints(minWidth: 52, minHeight: 44),
                  isSelected: [!_discountPercent, _discountPercent],
                  onPressed: (i) =>
                      setState(() => _discountPercent = i == 1),
                  children: const [
                    Text('₹', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('%', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// WELCOME SHEET shown right after saving a new member.
/// Full-width bottom sheet: WhatsApp welcome / ID / invoice actions.
/// Sending a message/ID/invoice opens WhatsApp; the sheet stays until Done.
class _WelcomeSheet extends StatefulWidget {
  final AppStore store;
  final int studentId;
  const _WelcomeSheet({required this.store, required this.studentId});

  @override
  State<_WelcomeSheet> createState() => _WelcomeSheetState();
}

class _WelcomeSheetState extends State<_WelcomeSheet> {
  AppStore get store => widget.store;
  Student? get _student => store.students.cast<Student?>().firstWhere(
        (e) => e?.id == widget.studentId,
        orElse: () => null,
      );

  Future<void> _welcome() async {
    final s = _student;
    if (s == null) return;
    final msg = WhatsAppService.instance.build(kTemplateWelcome, store, s);
    final ok = await WhatsAppService.instance.openChat(s.mobile, msg);
    if (!ok && mounted) {
      showSnack(context, 'No WhatsApp on this number', duration: kSnackWarn);
    }
  }

  Future<void> _sendId() async {
    final s = _student;
    if (s == null) return;
    try {
      final file = await CardImages.instance
          .generateIdCard(store: store, s: s, status: store.statusOf(s));
      final text = WhatsAppService.instance.build(kTemplateSendId, store, s);
      var ok = await ShareService.instance
          .imageToWhatsApp(mobile: s.mobile, imagePath: file.path, text: text);
      if (!ok) {
        await ShareService.instance.shareImage(file.path, text: text);
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not create the ID card',
            duration: kSnackError);
      }
    }
  }

  Future<void> _sendInvoice() async {
    final s = _student;
    if (s == null) return;
    final st = store.statusOf(s);
    final txn = store.lastPaymentTransactionOf(s.id);
    final txnDate = txn.isNotEmpty ? txn.first.date : s.admissionDate;
    final paidTotal = txn.fold(0.0, (a, e) => a + e.paidAmount);
    final discount = txn.fold(0.0, (a, e) => a + e.discount);
    try {
      final File file;
      if (s.ptEnabled) {
        file = await InvoicePdf.instance.generatePtInvoice(
          store: store,
          s: s,
          date: txnDate,
          sessionsAllocated: InvoiceMath.sessionsAllocated(
              paidTotal, s.ptSessionPrice),
          sessionPrice: s.ptSessionPrice,
          discount: discount,
          paid: paidTotal,
          balance: store.ptRechargeNeed(s),
        );
      } else {
        final plan = store.planById(s.planId);
        final admissionFee = txn
            .where((e) => e.type == kLedgerAdmissionFee)
            .fold(0.0, (a, e) => a + e.paidAmount);
        final months = plan?.months ?? 1;
        final coursePaid = (paidTotal - admissionFee).clamp(0.0, double.infinity);
        final courseGross = coursePaid + discount;
        file = await InvoicePdf.instance.generateCourseInvoice(
          store: store,
          s: s,
          date: txnDate,
          courseLine: store.primaryCourseLine(s),
          planName: plan?.name ?? '',
          monthsAllocated: months,
          validTill: st.paidTill,
          admissionFee: admissionFee,
          planPrice: courseGross,
          discount: discount,
          paid: paidTotal,
          balance: st.due,
        );
      }
      final ok = await ShareService.instance.documentToWhatsApp(
          mobile: s.mobile,
          path: file.path,
          text: '${s.name}, here is your receipt (PDF). – ${store.studio.name}');
      if (!ok) {
        await ShareService.instance
            .shareImage(file.path, text: 'Receipt – ${store.studio.name}');
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not create the invoice PDF',
            duration: kSnackError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _student;
    if (s == null) return const SizedBox.shrink();
    final c = AppColors.of(context);
    Widget btn(Widget icon, String label, Future<void> Function() onTap,
            {bool isPrimary = true}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isPrimary
              ? GoldButton(label, leading: icon, onTap: () => onTap())
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: c.hairline),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => onTap(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Text(label,
                          style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
        );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: c.hairline, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: c.gold, size: 36),
              ),
              const SizedBox(height: 10),
              Text('New member created 🎉', textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('${s.name} · ${s.jdNo} · ${s.mobile}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted, fontSize: 13.5)),
              const SizedBox(height: 20),
              btn(const WhatsAppIcon(size: 18, color: Colors.black),
                  'Send WhatsApp Welcome', _welcome,
                  isPrimary: true),
              btn(Icon(Icons.badge_outlined, size: 18, color: c.gold),
                  'Send ID Card', _sendId,
                  isPrimary: false),
              btn(Icon(Icons.receipt_long_outlined, size: 18, color: c.gold),
                  'Send Invoice', _sendInvoice,
                  isPrimary: false),
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: c.hairline)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done',
                      style: TextStyle(
                          color: c.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
