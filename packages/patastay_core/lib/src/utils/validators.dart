import 'phone_numbers.dart';

typedef FieldValidator = String? Function(String? value);

/// Reusable form validators. Server-side constraints mirror these rules; the
/// client checks exist for fast feedback, never as the only line of defence.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static FieldValidator required([String message = 'This field is required']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email address';
    if (v.length > 254 || !_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Matches the Supabase Auth policy: 8+ characters with letters and digits.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (v.length > 72) return 'Use at most 72 characters';
    if (!RegExp('[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use both letters and numbers';
    }
    return null;
  }

  static FieldValidator confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return 'Confirm your password';
      return value == original() ? null : 'Passwords do not match';
    };
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Enter your name';
    if (v.length > 120) return 'Name is too long';
    return null;
  }

  static FieldValidator phone({bool isRequired = false}) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return isRequired ? 'Enter a phone number' : null;
      return PhoneNumbers.normalize(v) == null
          ? 'Enter a valid phone number, e.g. 0712 345 678'
          : null;
    };
  }

  static FieldValidator maxLength(int max, [String? message]) {
    return (value) => (value != null && value.length > max)
        ? (message ?? 'Use at most $max characters')
        : null;
  }

  /// Runs validators in order and returns the first error.
  static FieldValidator compose(List<FieldValidator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
