# Just Dance Academy - Mobile App (Begusarai)

A luxury minimal mobile application for managing dance studio students, attendance, fee ledgers, WhatsApp notifications, biometric security, and Google Drive cloud backups.

## 🏛 File Structure

```
just_dance_academy/
├── assets/
│   ├── logo.png           # Gold dancer-in-circle logo
│   └── poster.jpg         # Studio poster (Phase 4 ID card)
├── fonts/                 # Place PlayfairDisplay & Manrope .ttf files here
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── constants.dart     # Default PIN (2026), App Info
│   ├── database/
│   │   ├── database_helper.dart  # sqflite wrapper
│   │   └── seed_data.dart        # Demo students for Phase 1
│   ├── models/
│   │   ├── student.dart          # Student data model
│   │   └── ledger_entry.dart     # Ledger data model (Phase 3)
│   ├── screens/
│   │   ├── lock_screen.dart      # Screen 0: Biometric + PIN 2026
│   │   ├── home_screen.dart      # Screen 1: Student List + Search
│   │   ├── admission_form_screen.dart # Screen 2 (Phase 2)
│   │   ├── student_details_screen.dart # Screen 3 (Phase 4)
│   │   ├── payment_dialog.dart   # Screen 4 (Phase 3)
│   │   └── settings_screen.dart  # Screen 5 (Phase 6)
│   ├── services/
│   │   ├── fee_engine.dart       # Ledger math (Phase 3)
│   │   ├── backup_service.dart   # Google Drive REST (Phase 5)
│   │   ├── settings_service.dart # Local sqflite settings wrapper
│   │   └── whatsapp_service.dart # url_launcher wa.me (Phase 4)
│   ├── theme/
│   │   ├── app_theme.dart        # Luxury minimal theme
│   │   ├── app_colors.dart       # Matte Black, Ivory, Gold, Status dots
│   │   └── app_fonts.dart
│   └── widgets/
│       ├── id_card_widget.dart   # Phase 4
│       ├── ledger_table.dart     # Phase 3
│       └── chip_input.dart       # Phase 2
├── pubspec.yaml
└── README.md
```

## 🔐 Default Security
- **Security Lock PIN**: `2026`
- **Biometric Unlock**: Supported via `local_auth`

## 🎨 Theme & Styling
- **Primary Aesthetics**: Matte Black (`#121212`), Ivory (`#FFFDF9`), Metallic Gold (`#D4AF37`)
- **Typography**: Playfair Display (Headings) & Manrope (Body/Data)
