/// Just Dance — app-wide constants.
library;

const kAppName = 'Just Dance';

/// Champagne gold accent — used for primary actions + hairlines only.
const kGoldHex = 0xFFC8A24A;

/// Default WhatsApp templates (owner can edit in Profile).
const kTemplateWelcome = 'welcome';
const kTemplateFeeCollected = 'feeCollected';
const kTemplateFeesDue = 'feesDue';
const kTemplateSendId = 'sendId';

const kDefaultTemplates = <String, String>{
  kTemplateWelcome:
      'Welcome {name}! So glad to have you at {studio}. Your ID is {id}. Plan: {plan}. Valid till: {validTill}. – {studio}',
  kTemplateFeeCollected:
      '{name}, fees {amount} received. Valid till {validTill}. Thank you! – {studio}',
  kTemplateFeesDue:
      'Hi {name}! Friendly reminder from {studio}: {month} fees of {due} are due. Please pay soon. Thank you! – {studio} ({address})',
  kTemplateSendId: '{name}, here is your {studio} ID card. – {studio}',
};

/// Placeholders available inside templates.
const kTemplatePlaceholders = [
  '{name}',
  '{id}',
  '{plan}',
  '{course}',
  '{validTill}',
  '{amount}',
  '{due}',
  '{month}',
  '{studio}',
  '{address}',
];

/// Ledger entry types (immutable log).
const kLedgerPayment = 'PAYMENT';
const kLedgerAdmissionFee = 'ADMISSION_FEE_PAID';
const kLedgerAutoCredit = 'AUTO_CREDIT_ADJUST';
const kLedgerPtPayment = 'PT_PAYMENT';
const kLedgerPlanChange = 'PLAN_CHANGE';
const kLedgerNote = 'NOTE';

/// Payment modes.
const kModeCash = 'Cash';
const kModeUpi = 'UPI';

/// Settings keys stored in the settings table.
const kPrefTheme = 'theme'; // 'dark' | 'light'
const kPrefDeviceLock = 'deviceLockOn'; // '1' | '0'
const kPrefBackupMeta = 'backupMeta'; // JSON
const kPrefDailyBackup = 'dailyBackupOn';
const kPrefWifiOnly = 'wifiOnlyBackup';
const kPrefAdmissionFee = 'admissionFeeAmount';
const kPrefGstin = 'gstin';
const kPrefGstRate = 'gstRate'; // percent, '0' = off
const kPrefPtSessionPrice = 'ptSessionPrice'; // studio default ₹/session
const kPrefPtDuration = 'ptDuration'; // e.g. "1 hour"
const kPrefPtDays = 'ptDays'; // e.g. "Mon,Wed,Fri"
const kPrefTemplates = 'waTemplatesJSON';
const kPrefStudio = 'studioInfoJSON';
const kPrefBackupPending = 'backupPending';
const kPrefRestoreSnapshot = 'restoreSnapshotJSON';

const kBackupFileName = 'studio_crow_backup.json';

/// India country code used for wa.me links (numbers stored as 10 digits).
const kCountryCode = '91';
