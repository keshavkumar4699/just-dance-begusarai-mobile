/// Studio Crow Form & Input Field Validation Utility
abstract class InputValidators {
  /// Validates Aadhar number according to spec:
  /// - Optional
  /// - If entered: exactly 12 digits, digits only, cannot start with 0 or 1.
  static String? validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final clean = value.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(clean)) {
      return 'Aadhar 12 digits ka hona chahiye';
    }
    if (clean.startsWith('0') || clean.startsWith('1')) {
      return 'Aadhar 0 ya 1 se shuru nahi ho sakta';
    }
    return null;
  }

  /// Mobile number validation (10 digits)
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number zaroori hai';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) {
      return 'Sahi 10-digit mobile number darj karein';
    }
    return null;
  }

  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Naam zaroori hai';
    }
    return null;
  }
}
