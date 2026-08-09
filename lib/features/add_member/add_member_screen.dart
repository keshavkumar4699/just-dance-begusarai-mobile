import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/student.dart';
import '../../models/plan.dart';
import '../../models/service.dart';
import '../../models/timing.dart';
import '../../core/validators/input_validators.dart';
import '../../core/date/date_formatter.dart';
import '../../database/repositories/student_repository.dart';
import '../../database/repositories/settings_repository.dart';
import '../../app/widgets/app_button.dart';
import 'welcome_kit_sheet.dart';

class AddMemberScreen extends StatefulWidget {
  final String? photoPath;

  const AddMemberScreen({
    super.key,
    this.photoPath,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherController = TextEditingController();
  final TextEditingController _motherController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _altMobileController = TextEditingController();

  // Address Controllers
  final TextEditingController _permVillageController = TextEditingController();
  final TextEditingController _permPOController = TextEditingController();
  final TextEditingController _permDistController = TextEditingController();
  final TextEditingController _permPinController = TextEditingController();

  bool _corrSame = true;
  final TextEditingController _corrVillageController = TextEditingController();
  final TextEditingController _corrPOController = TextEditingController();
  final TextEditingController _corrDistController = TextEditingController();
  final TextEditingController _corrPinController = TextEditingController();

  // Identity & Info
  final TextEditingController _aadharController = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';
  String _category = 'MALE';
  String _religion = 'Hindu';
  final String _nationality = 'Indian';
  String _maritalStatus = 'Unmarried';

  // Profile-Managed Read-Only Lists
  List<String> _availableHobbies = [];
  final List<String> _selectedHobbies = [];

  List<BusinessService> _availableServices = [];
  final List<String> _selectedServices = [];

  List<Timing> _availableTimings = [];
  Timing? _selectedTiming;

  double _admissionFeeAmount = 500.0;
  bool _admissionFeeEnabled = true;
  bool _admissionFeePaid = true;

  List<Plan> _availablePlans = Plan.defaults;
  Plan _selectedPlan = Plan.defaults.first;
  final TextEditingController _firstPaidController = TextEditingController(text: '1000');
  String _paymentMode = 'Cash'; // Cash, UPI
  final DateTime _admissionDate = DateTime.now();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    final services = await SettingsRepository().getServices();
    final timings = await SettingsRepository().getTimings();
    final plans = await SettingsRepository().getPlans();
    final hobbies = await SettingsRepository().getHobbies();
    final admissionFee = await SettingsRepository().getAdmissionFeeAmount();

    if (mounted) {
      setState(() {
        _availableServices = services;
        if (services.isNotEmpty) {
          _selectedServices.add(services.first.name);
        }
        _availableTimings = timings;
        if (timings.isNotEmpty) {
          _selectedTiming = timings.first;
        }
        _availablePlans = plans;
        if (plans.isNotEmpty) {
          _selectedPlan = plans.first;
          _firstPaidController.text = _selectedPlan.finalPrice.toStringAsFixed(0);
        }
        _availableHobbies = hobbies;
        _admissionFeeAmount = admissionFee;
      });
    }
  }

  void _onDobSelected(DateTime date) {
    setState(() {
      _dob = date;
      _category = DateFormatter.calculateCategory(date, _gender);
    });
  }

  void _onGenderChanged(String gender) {
    setState(() {
      _gender = gender;
      if (_dob != null) {
        _category = DateFormatter.calculateCategory(_dob, gender);
      }
    });
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kam se kam ek service select karein')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final initialPaid = double.tryParse(_firstPaidController.text.trim()) ?? 0.0;

      final student = Student(
        jdNo: 'AUTO',
        name: _nameController.text.trim(),
        fatherName: _fatherController.text.trim().isNotEmpty ? _fatherController.text.trim() : null,
        motherName: _motherController.text.trim().isNotEmpty ? _motherController.text.trim() : null,
        photoPath: widget.photoPath,
        permVillage: _permVillageController.text.trim().isNotEmpty ? _permVillageController.text.trim() : null,
        permPO: _permPOController.text.trim().isNotEmpty ? _permPOController.text.trim() : null,
        permDist: _permDistController.text.trim().isNotEmpty ? _permDistController.text.trim() : null,
        permPin: _permPinController.text.trim().isNotEmpty ? _permPinController.text.trim() : null,
        corrSame: _corrSame,
        corrVillage: !_corrSame && _corrVillageController.text.trim().isNotEmpty ? _corrVillageController.text.trim() : null,
        corrPO: !_corrSame && _corrPOController.text.trim().isNotEmpty ? _corrPOController.text.trim() : null,
        corrDist: !_corrSame && _corrDistController.text.trim().isNotEmpty ? _corrDistController.text.trim() : null,
        corrPin: !_corrSame && _corrPinController.text.trim().isNotEmpty ? _corrPinController.text.trim() : null,
        aadhar: _aadharController.text.trim().isNotEmpty ? _aadharController.text.trim() : null,
        dob: _dob,
        gender: _gender,
        category: _category,
        religion: _religion,
        nationality: _nationality,
        maritalStatus: _maritalStatus,
        hobbies: _selectedHobbies,
        services: _selectedServices,
        timingId: _selectedTiming?.id,
        mobile: _mobileController.text.trim(),
        altMobile: _altMobileController.text.trim().isNotEmpty ? _altMobileController.text.trim() : null,
        admissionDate: _admissionDate,
        plan: _selectedPlan.name,
        admissionFeeEnabled: _admissionFeeEnabled,
        admissionFeePaid: _admissionFeePaid,
      );

      final savedStudent = await StudentRepository().insertStudent(
        student,
        initialPaid: initialPaid,
        paymentMode: _paymentMode,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => WelcomeKitSheet(
            student: savedStudent,
            initialPaid: initialPaid,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member save nahi ho saka. Dobara try karein.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Member'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Photo Header Preview
              if (widget.photoPath != null && File(widget.photoPath!).existsSync()) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.photoPath!),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Personal Details Section
              _buildSectionCard(
                title: 'PERSONAL DETAILS',
                isDark: isDark,
                children: [
                  TextFormField(
                    controller: _nameController,
                    validator: InputValidators.validateName,
                    style: TextStyle(fontSize: 14, color: primaryTextColor),
                    decoration: _inputDecoration('Member Full Name*', 'e.g. Rahul Kumar', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          validator: InputValidators.validateMobile,
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration('Mobile Number*', '10 digits', borderColor, secondaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _altMobileController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration('Alt Mobile', 'Optional', borderColor, secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fatherController,
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration("Father's Name", 'Optional', borderColor, secondaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _motherController,
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration("Mother's Name", 'Optional', borderColor, secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Identity & Category Section
              _buildSectionCard(
                title: 'IDENTITY & CATEGORY',
                isDark: isDark,
                children: [
                  TextFormField(
                    controller: _aadharController,
                    keyboardType: TextInputType.number,
                    validator: InputValidators.validateAadhar,
                    style: TextStyle(fontSize: 14, color: primaryTextColor),
                    decoration: _inputDecoration('Aadhar Number (Optional)', '12 digits, digits only', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dob ?? DateTime(2005, 1, 1),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) _onDobSelected(picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dob != null ? DateFormatter.formatIndian(_dob) : 'Select DOB',
                                  style: TextStyle(fontSize: 13, color: _dob != null ? primaryTextColor : secondaryTextColor),
                                ),
                                Icon(Icons.calendar_today, size: 16, color: secondaryTextColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.champagneGoldMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.champagneGold),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Auto Category', style: TextStyle(fontSize: 10, color: AppColors.champagneGold, fontWeight: FontWeight.w700)),
                              Text(_category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.champagneGold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Gender: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryTextColor)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Male'),
                        selected: _gender == 'Male',
                        onSelected: (_) => _onGenderChanged('Male'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Female'),
                        selected: _gender == 'Female',
                        onSelected: (_) => _onGenderChanged('Female'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _religion,
                          items: ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Parsi', 'Jewish', 'Other'].map((r) {
                            return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) => setState(() => _religion = val ?? 'Hindu'),
                          decoration: _inputDecoration('Religion', '', borderColor, secondaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _maritalStatus,
                          items: ['Unmarried', 'Married'].map((m) {
                            return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (val) => setState(() => _maritalStatus = val ?? 'Unmarried'),
                          decoration: _inputDecoration('Marital Status', '', borderColor, secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Address Details Section
              _buildSectionCard(
                title: 'ADDRESS DETAILS',
                isDark: isDark,
                children: [
                  TextFormField(
                    controller: _permVillageController,
                    style: TextStyle(fontSize: 14, color: primaryTextColor),
                    decoration: _inputDecoration('Village / Locality', 'Permanent Address', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _permPOController,
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration('Post Office (P.O)', 'Optional', borderColor, secondaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _permDistController,
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration('District', 'Optional', borderColor, secondaryTextColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _permPinController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 14, color: primaryTextColor),
                    decoration: _inputDecoration('Pincode', 'Optional', borderColor, secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Correspondence Address Same As Permanent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _corrSame,
                    activeColor: AppColors.champagneGold,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() => _corrSame = val ?? true),
                  ),
                  if (!_corrSame) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _corrVillageController,
                      style: TextStyle(fontSize: 14, color: primaryTextColor),
                      decoration: _inputDecoration('Correspondence Village', 'Present Address', borderColor, secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _corrPOController,
                            style: TextStyle(fontSize: 14, color: primaryTextColor),
                            decoration: _inputDecoration('P.O', 'Optional', borderColor, secondaryTextColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _corrDistController,
                            style: TextStyle(fontSize: 14, color: primaryTextColor),
                            decoration: _inputDecoration('District', 'Optional', borderColor, secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // 4. Hobbies Selector (Read from Profile Settings)
              _buildSectionCard(
                title: 'HOBBIES (PROFILE MANAGED)',
                isDark: isDark,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableHobbies.map((hobby) {
                      final isSel = _selectedHobbies.contains(hobby);
                      return FilterChip(
                        label: Text(hobby, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: AppColors.champagneGold,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedHobbies.add(hobby);
                            } else {
                              _selectedHobbies.remove(hobby);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Services & Timings (Read from Profile Settings)
              _buildSectionCard(
                title: 'SERVICES & TIMINGS (PROFILE MANAGED)',
                isDark: isDark,
                children: [
                  Text('Services*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableServices.map((svc) {
                      final isSel = _selectedServices.contains(svc.name);
                      return FilterChip(
                        label: Text(svc.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        selected: isSel,
                        selectedColor: AppColors.champagneGold,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(svc.name);
                            } else {
                              _selectedServices.remove(svc.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Batch Timing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Timing>(
                    initialValue: _selectedTiming,
                    items: _availableTimings.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.name} (${t.days} ${t.hours})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedTiming = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 6. Fee Options & Plan Setup (Read from Profile Settings)
              _buildSectionCard(
                title: 'FEE SETUP & PLAN (PROFILE MANAGED)',
                isDark: isDark,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Admission Fee (₹${_admissionFeeAmount.toStringAsFixed(0)})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(_admissionFeeEnabled ? 'Admission fee enabled' : 'No admission fee', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                    value: _admissionFeeEnabled,
                    activeTrackColor: AppColors.champagneGold,
                    onChanged: (val) => setState(() => _admissionFeeEnabled = val),
                  ),
                  if (_admissionFeeEnabled) ...[
                    Row(
                      children: [
                        Text('Admission Fee Paid?', style: TextStyle(fontSize: 13, color: primaryTextColor)),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Yes'),
                          selected: _admissionFeePaid,
                          onSelected: (_) => setState(() => _admissionFeePaid = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('No'),
                          selected: !_admissionFeePaid,
                          onSelected: (_) => setState(() => _admissionFeePaid = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text('Select Plan*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryTextColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Plan>(
                    initialValue: _selectedPlan,
                    items: _availablePlans.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} — ₹${p.finalPrice.toStringAsFixed(0)}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPlan = val;
                          _firstPaidController.text = val.finalPrice.toStringAsFixed(0);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstPaidController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 14, color: primaryTextColor),
                          decoration: _inputDecoration('First Payment (₹)', 'Amount', borderColor, secondaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mode', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                            const SizedBox(height: 4),
                            Row(
                              children: ['Cash', 'UPI'].map((m) {
                                final isSel = _paymentMode == m;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _paymentMode = m),
                                    child: Container(
                                      margin: EdgeInsets.only(right: m == 'Cash' ? 4 : 0),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.champagneGold : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: isSel ? AppColors.champagneGold : borderColor),
                                      ),
                                      child: Text(m, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? AppColors.darkBackground : primaryTextColor)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Save Member',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _saveMember,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.microLabel(secondaryTextColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, Color borderColor, Color secondaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 13, color: secondaryColor),
      hintStyle: TextStyle(fontSize: 12, color: secondaryColor.withValues(alpha: 0.5)),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.champagneGold)),
    );
  }
}
