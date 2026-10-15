/// Phone number helpers. The database stores E.164 (e.g. +254712345678).
abstract final class PhoneNumbers {
  static final _e164 = RegExp(r'^\+[1-9]\d{7,14}$');

  /// Normalises common Kenyan formats to E.164:
  /// `0712 345 678`, `0112345678`, `254712345678`, `+254 712 345678`, `712345678`.
  /// Other international numbers are accepted when already in `+<country>` form.
  /// Returns null when the input is not a valid number.
  static String? normalize(String? input) {
    if (input == null) return null;
    final hasPlus = input.trim().startsWith('+');
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;

    String candidate;
    if (hasPlus) {
      candidate = '+$digits';
    } else if (digits.length == 10 && digits.startsWith('0') && _isKenyanMobilePrefix(digits[1])) {
      candidate = '+254${digits.substring(1)}';
    } else if (digits.length == 12 && digits.startsWith('254')) {
      candidate = '+$digits';
    } else if (digits.length == 9 && _isKenyanMobilePrefix(digits[0])) {
      candidate = '+254$digits';
    } else {
      return null;
    }

    if (candidate.startsWith('+254')) {
      final local = candidate.substring(4);
      if (local.length != 9 || !_isKenyanMobilePrefix(local[0])) return null;
    }
    return _e164.hasMatch(candidate) ? candidate : null;
  }

  static bool _isKenyanMobilePrefix(String d) => d == '7' || d == '1';

  /// `+254712345678` -> `+254 712 345 678` for display.
  static String format(String e164) {
    if (e164.startsWith('+254') && e164.length == 13) {
      final local = e164.substring(4);
      return '+254 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return e164;
  }

  /// Digits only, as required by wa.me links.
  static String whatsappDigits(String e164) => e164.replaceAll(RegExp(r'[^\d]'), '');
}
