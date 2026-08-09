# Studio Crow — Luxury Studio Management Application (Android)

**Studio Crow** is a luxury, minimalist, offline-first studio & member management application built with **Flutter** for Android physical membership-based businesses (Gyms, Dance studios, Karate academies, Yoga studios, Zumba classes, Boxing, Swimming, Music, Acting, Sports academies, etc.).

---

## 1. Setup & Installation Guide / Setup Kaise Karein

### System Requirements
* Flutter SDK: `3.0.0` or higher
* Android SDK: API Level 21 (Android 5.0) or higher
* Java Development Kit (JDK): JDK 17 / 21

### Commands / Zaroori Commands

1. **Install Dependencies / Packages download karein:**
   ```bash
   flutter pub get
   ```

2. **Run Application in Debug Mode / Test chalayein:**
   ```bash
   flutter run
   ```

3. **Build Production Release APK / Release APK banayein:**
   ```bash
   flutter build apk --release
   ```
   * Generated APK path:
     `build/app/outputs/flutter-apk/app-release.apk`

---

## 2. App Lock & Biometrics Security

Studio Crow integrates Android's native `local_auth` biometric & device security system.

* **Biometric Lock**: Uses Android fingerprint, face recognition, or system device lock.
* **System PIN Fallback**: If biometric fails, Android automatically falls back to your device PIN/pattern/password.
* **Default PIN Note**: The default reference PIN for system unlock setup is `2026`. *(Note: Studio Crow does NOT store or manage custom app passcodes locally; device security is handled securely by Android).*

---

## 3. Logo Replacement / Logo Kaise Badlein

To replace the studio logo across the entire application:

1. Replace the file at [assets/logo.png](file:///d:/Customer%20Projects/just-dance-begusarai-mobile/assets/logo.png).
2. Recommended format: Transparent PNG, high resolution (minimum 512x512 px).
3. The logo is automatically updated across:
   * Splash screen
   * App launch icon
   * Member ID cards
   * Invoice generator
   * Studio profile header

---

## 4. Fee Engine V2 (Hinglish Explanation & Examples)

Studio Crow uses a pure, unit-tested **Fee Engine** based on an append-only ledger system. Member status is **NEVER** stored directly in SQLite — it is calculated dynamically in real-time.

### Status Rules / Status Niyam:
* **PAID**: `today <= paidTill`. Note: `today == paidTill` ka matlab member **Active/Paid** hai. Expiry next day se shuru hoti hai.
* **EXPIRED**: `today > paidTill`.
* **NEAR EXPIRY**: Member active hai aur `daysLeft <= 7`.
* **INACTIVE**: Member ne पिछले 7 din se check-in nahi kiya (`today - lastVisitDate > 7`).
* **BLOCKED**: `isBlocked == true` (Priority display status).

### Calculation Examples / Udaharan:

1. **Full Payment**:
   * Monthly Plan: ₹1000
   * Paid: ₹1000
   * Result: `monthsCovered = +1`, `due = 0`.

2. **Overpayment & Advance**:
   * Monthly Plan: ₹1000
   * Paid: ₹1500
   * Result: 1 Month paid, baki ₹500 automatically `credit` balance me add ho jata hai.

3. **Auto-Credit Adjustment**:
   * Advance credit balance: ₹1000
   * Next cycle due: ₹1000
   * Engine automatically `AUTO_CREDIT_ADJUST` ledger entry create karke cycle clear kar deta hai.

---

## 5. WhatsApp Sharing & Placeholders

Studio Crow utilizes direct `wa.me` deep linking for sending receipts and reminders.

* **Manual Only**: Studio Crow **NEVER** sends automatic or background messages. The studio owner performs the final tap on WhatsApp Send.

### Editable Message Templates & Placeholders:
* `{name}` — Member full name
* `{id}` — Member JD Number (e.g. `JD-001`)
* `{plan}` — Selected plan (e.g. `Monthly`)
* `{validTill}` — Expiry date (e.g. `09 Aug 2026`)
* `{amount}` — Paid fee amount
* `{due}` — Balance due amount
* `{month}` — Current fee month label
* `{studio}` — Studio business name
* `{address}` — Studio physical address

---

## 6. Google Drive Backup & Restore

* **Storage Location**: Google Drive `appDataFolder` (Private app folder).
* **Backup Safety**: Creates a temporary verified snapshot before replacing old backups to prevent data loss.
* **Offline-First**: All studio operations (Member Add, Payments, Attendance, Ledger) work 100% offline without internet.

---

## 7. Project Architecture

```text
lib/
├── main.dart                 # Application entry point
├── app/
│   ├── app.dart              # Root MaterialApp with Theme listener
│   ├── routes.dart           # App routes definition
│   ├── theme/                # Luxury design tokens (Colors, Fonts, Sizes, Theme)
│   └── widgets/              # Reusable UI components (Nav, Buttons, Cards)
├── core/                     # Constants, Date formatters, Validators, Helpers
├── database/                 # SQLite database helper & schema definitions
├── models/                   # Domain data models (Student, LedgerEntry, Plan, etc.)
├── services/                 # AuthService, ThemeService, FeeEngine
└── features/                 # App feature screens (Splash, Lock, Home, PT, Collections, Profile)
```
