import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../models/whatsapp_template.dart';
import '../../../database/repositories/settings_repository.dart';

class ManageTemplatesScreen extends StatefulWidget {
  const ManageTemplatesScreen({super.key});

  @override
  State<ManageTemplatesScreen> createState() => _ManageTemplatesScreenState();
}

class _ManageTemplatesScreenState extends State<ManageTemplatesScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  List<WhatsAppTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final loaded = await _settingsRepo.getWhatsAppTemplates();
    if (mounted) {
      setState(() {
        _templates = loaded;
        _isLoading = false;
      });
    }
  }

  void _editTemplate(WhatsAppTemplate template, int index) {
    final ctrl = TextEditingController(text: template.templateText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${template.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Placeholders:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.champagneGold)),
              const SizedBox(height: 4),
              const Text(
                '{name}, {id}, {plan}, {validTill}, {amount}, {due}, {month}, {studio}, {address}',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newText = ctrl.text.trim();
              if (newText.isNotEmpty) {
                final updated = WhatsAppTemplate(key: template.key, title: template.title, templateText: newText);
                final updatedList = List<WhatsAppTemplate>.from(_templates);
                updatedList[index] = updated;
                await _settingsRepo.saveWhatsAppTemplates(updatedList);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTemplates();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selfTestWhatsApp(WhatsAppTemplate template) async {
    final testText = template.templateText
        .replaceAll('{name}', 'Demo Student')
        .replaceAll('{id}', 'JD-001')
        .replaceAll('{plan}', 'Monthly')
        .replaceAll('{validTill}', '09 Aug 2026')
        .replaceAll('{amount}', '1000')
        .replaceAll('{due}', '0')
        .replaceAll('{month}', 'August')
        .replaceAll('{studio}', 'Studio Crow')
        .replaceAll('{address}', 'Begusarai, Bihar');

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(testText)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: const Text('WhatsApp Templates'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.champagneGold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('WHATSAPP MESSAGE TEMPLATES', style: AppTypography.microLabel(secondaryTextColor)),
                  const SizedBox(height: 12),

                  ..._templates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tmpl = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tmpl.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primaryTextColor)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _editTemplate(tmpl, index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send_outlined, size: 18, color: AppColors.statusActive),
                                    onPressed: () => _selfTestWhatsApp(tmpl),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(tmpl.templateText, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGoldMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.champagneGold, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Self-Test button WhatsApp open karta hai. Studio Crow kabhi automatic messages nahi bhejta.',
                            style: TextStyle(fontSize: 11, color: AppColors.champagneGold, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
