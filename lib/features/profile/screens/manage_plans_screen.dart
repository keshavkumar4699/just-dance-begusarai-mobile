import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/plan.dart';
import '../../../database/repositories/settings_repository.dart';
import '../../../app/widgets/app_button.dart';

class ManagePlansScreen extends StatefulWidget {
  const ManagePlansScreen({super.key});

  @override
  State<ManagePlansScreen> createState() => _ManagePlansScreenState();
}

class _ManagePlansScreenState extends State<ManagePlansScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  List<Plan> _plans = [];
  double _admissionFee = 500.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final plans = await _settingsRepo.getPlans();
    final fee = await _settingsRepo.getAdmissionFeeAmount();
    if (mounted) {
      setState(() {
        _plans = plans;
        _admissionFee = fee;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAdmissionFee(double newFee) async {
    await _settingsRepo.saveAdmissionFeeAmount(newFee);
    setState(() => _admissionFee = newFee);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission fee updated!')),
      );
    }
  }

  void _showAddEditPlanDialog([Plan? plan, int? index]) {
    final nameCtrl = TextEditingController(text: plan?.name ?? '');
    final monthsCtrl = TextEditingController(text: plan != null ? plan.months.toString() : '1');
    final basePriceCtrl = TextEditingController(text: plan != null ? plan.basePrice.toStringAsFixed(0) : '1000');
    final discountCtrl = TextEditingController(text: plan != null ? plan.discount.toStringAsFixed(0) : '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plan == null ? 'Add New Plan' : 'Edit Plan', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Plan Name (e.g. Monthly)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: monthsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (Months)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: basePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Base Price (₹)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: discountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount (₹)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final months = int.tryParse(monthsCtrl.text.trim()) ?? 1;
              final base = double.tryParse(basePriceCtrl.text.trim()) ?? 1000.0;
              final disc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;

              if (name.isNotEmpty) {
                final updatedPlan = Plan(name: name, months: months, basePrice: base, discount: disc);
                final updatedList = List<Plan>.from(_plans);
                if (index != null) {
                  updatedList[index] = updatedPlan;
                } else {
                  updatedList.add(updatedPlan);
                }
                await _settingsRepo.savePlans(updatedList);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlan(int index) async {
    final updatedList = List<Plan>.from(_plans)..removeAt(index);
    await _settingsRepo.savePlans(updatedList);
    _loadData();
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
        title: const Text('Plans & Fees Management'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Admission Fee Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ADMISSION FEE', style: AppTypography.microLabel(AppColors.champagneGold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('₹${_admissionFee.toStringAsFixed(0)}', style: AppTypography.headingMedium(primaryTextColor)),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () {
                                final ctrl = TextEditingController(text: _admissionFee.toStringAsFixed(0));
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Edit Admission Fee'),
                                    content: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Admission Fee Amount (₹)'),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          final val = double.tryParse(ctrl.text.trim());
                                          if (val != null && val >= 0) {
                                            _updateAdmissionFee(val);
                                            Navigator.pop(ctx);
                                          }
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit Fee'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MEMBERSHIP PLANS', style: AppTypography.microLabel(secondaryTextColor)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.champagneGold),
                        onPressed: () => _showAddEditPlanDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryTextColor)),
                                const SizedBox(height: 2),
                                Text(
                                  'Duration: ${plan.months} mo • Base: ₹${plan.basePrice.toStringAsFixed(0)} • Disc: ₹${plan.discount.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                ),
                                Text(
                                  'Final Price: ₹${plan.finalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.champagneGold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _showAddEditPlanDialog(plan, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusExpired),
                            onPressed: () => _deletePlan(index),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  AppButton(
                    label: '+ Naya Plan Add Karein',
                    icon: Icons.add,
                    onPressed: () => _showAddEditPlanDialog(),
                  ),
                ],
              ),
      ),
    );
  }
}
