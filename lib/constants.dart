import 'package:flutter/material.dart';

/// App-wide constants for Studio Crow.
class AppInfo {
  static const String name = 'Studio Crow';
  static const String version = '1.0.0';
  static const String backupFileName = 'studio_crow_backup.json';
  static const String snapshotFileName = 'studio_crow_snapshot.json';
  static const String driveAppFolder = 'appDataFolder';
  static const String driveScope = 'https://www.googleapis.com/auth/drive.appdata';

  /// OAuth client id for Google Drive backup (Google Cloud Console -> OAuth 2.0 Client IDs -> Web application).
  /// Leave empty to skip sign-in setup; README explains how to fill this.
  static const String googleWebClientId = '';

  /// OAuth client secret of the same Web application client (kept local, never uploaded).
  /// Only needed on the rare case where Android returns an auth code instead of a token.
  static const String googleWebClientSecret = '';
}

/// Color system - Instagram-like, champagne gold accent.
class AppColors {
  static const Color gold = Color(0xFFC8A24A);
  static const Color darkBg = Color(0xFF0E0E10);
  static const Color darkText = Color(0xFFF5F1E8);
  static const Color darkHairline = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color darkCard = Color(0xFF161618);

  static const Color lightBg = Color(0xFFFAF8F4);
  static const Color lightText = Color(0xFF141414);
  static const Color lightHairline = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color lightCard = Color(0xFFFFFFFF);

  // State colors.
  static const Color active = Color(0xFF46A758);
  static const Color nearExpiry = Color(0xFFFFB224);
  static const Color expired = Color(0xFFE5484D);
  static const Color inactive = Color(0xFF8B8B93);
  static const Color blocked = Color(0xFF55555B);

  static const Color greyIcon = Color(0xFF8B8B93);
}

/// Status of a student (NEVER stored - always computed).
enum MemberStatus {
  active,
  nearExpiry,
  expired,
  due,
  inactive,
  blocked;

  Color get color => switch (this) {
        MemberStatus.active => AppColors.active,
        MemberStatus.nearExpiry => AppColors.nearExpiry,
        MemberStatus.expired => AppColors.expired,
        MemberStatus.due => AppColors.expired,
        MemberStatus.inactive => AppColors.inactive,
        MemberStatus.blocked => AppColors.blocked,
      };

  String get label => switch (this) {
        MemberStatus.active => 'Active',
        MemberStatus.nearExpiry => 'Near expiry',
        MemberStatus.expired => 'Expired',
        MemberStatus.due => 'Due',
        MemberStatus.inactive => 'Inactive',
        MemberStatus.blocked => 'Blocked',
      };
}

/// Ledger entry types.
class LedgerType {
  static const String payment = 'PAYMENT';
  static const String admissionFeePaid = 'ADMISSION_FEE_PAID';
  static const String autoCreditAdjust = 'AUTO_CREDIT_ADJUST';
  static const String ptPayment = 'PT_PAYMENT';
  static const String planChange = 'PLAN_CHANGE';
  static const String note = 'NOTE';
}

/// Settings keys (sqflite settings table).
class SettingsKeys {
  static const String theme = 'theme';
  static const String deviceLockOn = 'deviceLockOn';
  static const String backupMeta = 'backupMeta';
  static const String dailyBackupOn = 'dailyBackupOn';
  static const String wifiOnlyBackup = 'wifiOnlyBackup';
  static const String admissionFeeAmount = 'admissionFeeAmount';
  static const String waTemplatesJson = 'waTemplatesJSON';
  static const String studioInfoJson = 'studioInfoJSON';
}

/// WhatsApp template keys.
class TemplateKeys {
  static const String welcome = 'WELCOME';
  static const String feeCollected = 'FEE_COLLECTED';
  static const String feesDue = 'FEES_DUE';
  static const String idCard = 'SEND_ID_CARD';

  static const Map<String, String> defaults = {
    welcome:
        'Welcome {name}! So glad to have you at {studio}. Your ID is {id}. Plan: {plan}. Valid till: {validTill}. - {studio}',
    feeCollected: '{name}, fees {amount} received. Valid till {validTill}. Thank you! - {studio}',
    feesDue:
        'Hi {name}! Friendly reminder from {studio}: {month} fees of {due} are due. Please pay soon. Thank you! - {studio} ({address})',
    idCard: '{name}, here is your {studio} ID card. - {studio}',
  };
}

/// Religion options for the admission form.
const List<String> kReligions = [
  'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Parsi', 'Jewish', 'Other',
];

/// Settings key for studio info JSON fields.
class StudioInfoFields {
  static const String name = 'name';
  static const String director = 'director';
  static const String contact = 'contact';
  static const String socials = 'socials';
  static const String address = 'address';
  static const String logoPath = 'logoPath';
}

/// Bottom nav tab indices.
enum TabIndex { home, attendance, collections, profile }

/// Placeholder tokens usable in WhatsApp templates.
const List<String> kTemplatePlaceholders = [
  '{name}', '{id}', '{plan}', '{course}', '{validTill}', '{amount}', '{due}', '{month}', '{studio}', '{address}',
];
