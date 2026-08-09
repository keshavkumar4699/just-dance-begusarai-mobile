import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../models/student.dart';
import '../../models/service.dart';
import '../../database/repositories/student_repository.dart';
import '../../database/repositories/settings_repository.dart';
import '../../core/validators/input_validators.dart';
import '../../app/widgets/app_button.dart';

class EditStudentScreen extends StatefulWidget {
  final Student student;

  const EditStudentScreen({
    super.key,
    required this.student,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _altMobileController;
  late TextEditingController _fatherController;
  late TextEditingController _motherController;

  late String _gender;
  late String _category;
  DateTime? _dob;

  List<BusinessService> _availableServices = [];
  late List<String> _selectedServices;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _mobileController = TextEditingController(text: widget.student.mobile);
    _altMobileController = TextEditingController(text: widget.student.altMobile ?? '');
    _fatherController = TextEditingController(text: widget.student.fatherName ?? '');
    _motherController = TextEditingController(text: widget.student.motherName ?? '');
    _gender = widget.student.gender;
    _category = widget.student.category;
    _dob = widget.student.dob;
    _selectedServices = List<String>.from(widget.student.services);

    _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await SettingsRepository().getServices();
    if (mounted) {
      setState(() {
        _availableServices = services;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = widget.student.copyWith(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        altMobile: _altMobileController.text.trim().isNotEmpty ? _altMobileController.text.trim() : null,
        fatherName: _fatherController.text.trim().isNotEmpty ? _fatherController.text.trim() : null,
        motherName: _motherController.text.trim().isNotEmpty ? _motherController.text.trim() : null,
        gender: _gender,
        category: _category,
        dob: _dob,
        services: _selectedServices,
      );

      await StudentRepository().updateStudent(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member details update ho gayi!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update fail ho gaya. Dobara try karein.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final borderColor = isDark ? AppColors.darkHairline : AppColors.lightHairline;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.student.name}'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MEMBER DETAILS', style: AppTypography.microLabel(secondaryTextColor)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      validator: InputValidators.validateName,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _inputDecoration('Full Name*', borderColor, secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      validator: InputValidators.validateMobile,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _inputDecoration('Mobile Number*', borderColor, secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _altMobileController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _inputDecoration('Alt Mobile', borderColor, secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fatherController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _inputDecoration("Father's Name", borderColor, secondaryTextColor),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _motherController,
                      style: TextStyle(color: primaryTextColor),
                      decoration: _inputDecoration("Mother's Name", borderColor, secondaryTextColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ASSIGNED SERVICES', style: AppTypography.microLabel(secondaryTextColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _availableServices.map((svc) {
                        final isSel = _selectedServices.contains(svc.name);
                        return FilterChip(
                          label: Text(svc.name, style: const TextStyle(fontSize: 12)),
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              AppButton(
                label: 'Save Changes',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, Color borderColor, Color secondaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: secondaryColor),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.champagneGold)),
    );
  }
}
