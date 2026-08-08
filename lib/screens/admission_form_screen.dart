import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../models/ledger_entry.dart';
import '../widgets/chip_input.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../constants.dart';

class AdmissionFormScreen extends StatefulWidget {
  final Student? studentToEdit;

  const AdmissionFormScreen({Key? key, this.studentToEdit}) : super(key: key);

  @override
  State<AdmissionFormScreen> createState() => _AdmissionFormScreenState();
}

class _AdmissionFormScreenState extends State<AdmissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _monthlyFeeController;

  List<String> _selectedStyles = ['Contemporary'];
  String _selectedBatch = AppConstants.availableBatchTimings.first;
  DateTime _joiningDate = DateTime.now();
  int _dueDay = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.studentToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _parentPhoneController = TextEditingController(text: s?.parentPhone ?? '');
    _monthlyFeeController = TextEditingController(text: s?.monthlyFee.toInt().toString() ?? '1500');

    if (s != null) {
      _selectedStyles = List<String>.from(s.danceStyles);
      _selectedBatch = s.batchTiming;
      _dueDay = s.dueDay;
      try {
        _joiningDate = DateTime.parse(s.joiningDate);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveAdmission() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStyles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one dance style.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final monthlyFee = double.tryParse(_monthlyFeeController.text.trim()) ?? 1500.0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_joiningDate);

    final student = Student(
      id: widget.studentToEdit?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      parentPhone: _parentPhoneController.text.trim(),
      danceStyles: _selectedStyles,
      batchTiming: _selectedBatch,
      joiningDate: dateStr,
      monthlyFee: monthlyFee,
      dueDay: _dueDay,
      status: widget.studentToEdit?.status ?? 'Active',
    );

    if (widget.studentToEdit == null) {
      // New Student Admission
      final newId = await _dbHelper.insertStudent(student);

      // Create Initial Ledger Entry for Current Month
      final currentMonthStr = DateFormat('MMM yyyy').format(DateTime.now());
      await _dbHelper.insertLedgerEntry(
        LedgerEntry(
          studentId: newId,
          monthYear: currentMonthStr,
          amountDue: monthlyFee,
          amountPaid: 0.0,
          paymentDate: '',
          paymentMode: 'Cash',
          status: 'Pending',
          notes: 'Initial admission ledger entry',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student Admission successful!')),
        );
      }
    } else {
      // Update Existing Student
      await _dbHelper.updateStudent(student);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile updated successfully!')),
        );
      }
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.studentToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Student Profile' : 'New Student Admission',
          style: AppFonts.displayHeader(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STUDENT INFORMATION', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Full Name
              TextFormField(
                controller: _nameController,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.gold),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter student full name' : null,
              ),
              const SizedBox(height: 16),

              // Student Contact
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Student Mobile / WhatsApp *',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.gold),
                ),
                validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid 10-digit phone number' : null,
              ),
              const SizedBox(height: 16),

              // Parent Contact
              TextFormField(
                controller: _parentPhoneController,
                keyboardType: TextInputType.phone,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Parent / Guardian Contact',
                  prefixIcon: Icon(Icons.family_restroom_outlined, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 24),

              Text('DANCE STYLES (SELECT CHIPS)', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ChipInputWidget(
                availableOptions: AppConstants.availableDanceStyles,
                selectedValues: _selectedStyles,
                onChanged: (updated) {
                  setState(() => _selectedStyles = updated);
                },
              ),
              const SizedBox(height: 24),

              Text('BATCH & FEE CONFIGURATION', style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Batch Timing Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedBatch,
                dropdownColor: AppColors.surface,
                style: AppFonts.bodyText(),
                decoration: const InputDecoration(
                  labelText: 'Batch Timing',
                  prefixIcon: Icon(Icons.access_time, color: AppColors.gold),
                ),
                items: AppConstants.availableBatchTimings.map((batch) {
                  return DropdownMenuItem(
                    value: batch,
                    child: Text(batch, style: AppFonts.bodyText()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBatch = val);
                },
              ),
              const SizedBox(height: 16),

              // Monthly Fee & Due Day Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _monthlyFeeController,
                      keyboardType: TextInputType.number,
                      style: AppFonts.bodyText(),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Fee (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee, color: AppColors.gold),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter monthly fee' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      initialValue: _dueDay,
                      dropdownColor: AppColors.surface,
                      style: AppFonts.bodyText(),
                      decoration: const InputDecoration(
                        labelText: 'Due Day',
                      ),
                      items: [1, 5, 10, 15, 20, 25].map((day) {
                        return DropdownMenuItem(
                          value: day,
                          child: Text("${day}th", style: AppFonts.bodyText()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _dueDay = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAdmission,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: AppColors.background)
                      : Text(
                          isEditing ? 'UPDATE STUDENT PROFILE' : 'COMPLETE ADMISSION',
                          style: AppFonts.bodyText(fontWeight: FontWeight.bold, color: AppColors.background, fontSize: 16),
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
