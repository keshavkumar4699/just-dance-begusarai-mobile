import 'dart:convert';
import '../database_helper.dart';
import '../../models/plan.dart';
import '../../models/service.dart';
import '../../models/timing.dart';
import '../../models/studio_info.dart';
import '../../models/whatsapp_template.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper;

  SettingsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // Hobbies
  Future<List<String>> getHobbies() async {
    final raw = await _dbHelper.getSetting('hobbiesJSON');
    if (raw == null || raw.isEmpty) {
      return List<String>.from(AppConstants.defaultHobbies);
    }
    final list = jsonDecode(raw) as List;
    return list.cast<String>();
  }

  Future<void> saveHobbies(List<String> hobbies) async {
    final encoded = jsonEncode(hobbies);
    await _dbHelper.setSetting('hobbiesJSON', encoded);
  }

  // Plans
  Future<List<Plan>> getPlans() async {
    final raw = await _dbHelper.getSetting('plansJSON');
    if (raw == null || raw.isEmpty) {
      return Plan.defaults;
    }
    final list = jsonDecode(raw) as List;
    return list.map((item) => Plan.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> savePlans(List<Plan> plans) async {
    final encoded = jsonEncode(plans.map((p) => p.toMap()).toList());
    await _dbHelper.setSetting('plansJSON', encoded);
  }

  // Generic Services
  Future<List<BusinessService>> getServices() async {
    final raw = await _dbHelper.getSetting('servicesJSON');
    if (raw == null || raw.isEmpty) {
      return [
        const BusinessService(id: 1, name: 'Bollywood'),
        const BusinessService(id: 2, name: 'Hip Hop'),
        const BusinessService(id: 3, name: 'Zumba Fitness'),
        const BusinessService(id: 4, name: 'Yoga'),
        const BusinessService(id: 5, name: 'Gym Membership'),
        const BusinessService(id: 6, name: 'Personal Training'),
        const BusinessService(id: 7, name: 'Home Tuition'),
      ];
    }
    final list = jsonDecode(raw) as List;
    return list.map((item) => BusinessService.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> saveServices(List<BusinessService> services) async {
    final encoded = jsonEncode(services.map((s) => s.toMap()).toList());
    await _dbHelper.setSetting('servicesJSON', encoded);
  }

  // Timings
  Future<List<Timing>> getTimings() async {
    final raw = await _dbHelper.getSetting('timingsJSON');
    if (raw == null || raw.isEmpty) {
      return [
        const Timing(id: 1, name: 'Morning Batch', days: 'Mon–Sat', hours: '6 to 7 AM'),
        const Timing(id: 2, name: 'Weekdays Batch', days: 'Mon–Fri', hours: '1 hr'),
        const Timing(id: 3, name: 'Weekend Batch', days: 'Sat–Sun', hours: '2 hr'),
      ];
    }
    final list = jsonDecode(raw) as List;
    return list.map((item) => Timing.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> saveTimings(List<Timing> timings) async {
    final encoded = jsonEncode(timings.map((t) => t.toMap()).toList());
    await _dbHelper.setSetting('timingsJSON', encoded);
  }

  // Studio Info
  Future<StudioInfo> getStudioInfo() async {
    final raw = await _dbHelper.getSetting('studioInfoJSON');
    if (raw == null || raw.isEmpty) {
      return StudioInfo.defaultInfo;
    }
    return StudioInfo.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStudioInfo(StudioInfo info) async {
    final encoded = jsonEncode(info.toMap());
    await _dbHelper.setSetting('studioInfoJSON', encoded);
  }

  // WhatsApp Templates
  Future<List<WhatsAppTemplate>> getWhatsAppTemplates() async {
    final raw = await _dbHelper.getSetting('waTemplatesJSON');
    if (raw == null || raw.isEmpty) {
      return WhatsAppTemplate.defaultTemplates;
    }
    final list = jsonDecode(raw) as List;
    return list.map((item) => WhatsAppTemplate.fromMap(item as Map<String, dynamic>)).toList();
  }

  Future<void> saveWhatsAppTemplates(List<WhatsAppTemplate> templates) async {
    final encoded = jsonEncode(templates.map((t) => t.toMap()).toList());
    await _dbHelper.setSetting('waTemplatesJSON', encoded);
  }

  // Admission Fee Amount Setting
  Future<double> getAdmissionFeeAmount() async {
    final raw = await _dbHelper.getSetting('admissionFeeAmount');
    if (raw == null || raw.isEmpty) return 500.0;
    return double.tryParse(raw) ?? 500.0;
  }

  Future<void> saveAdmissionFeeAmount(double amount) async {
    await _dbHelper.setSetting('admissionFeeAmount', amount.toString());
  }
}
