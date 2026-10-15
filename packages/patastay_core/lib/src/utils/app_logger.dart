import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal logger. Logs operation names and error types only; it never logs
/// request payloads, emails, phone numbers or tokens.
abstract final class AppLogger {
  static void info(String message) {
    if (kDebugMode) developer.log(message, name: 'patastay');
  }

  static void failure(String operation, Object failure, Object cause, StackTrace stackTrace) {
    developer.log(
      '$operation failed: ${failure.runtimeType} (cause: ${cause.runtimeType})',
      name: 'patastay',
      error: kDebugMode ? redact(cause.toString()) : null,
      stackTrace: kDebugMode ? stackTrace : null,
      level: 900,
    );
  }

  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final _phone = RegExp(r'\+?\d[\d\s-]{7,}\d');

  /// Masks emails and phone numbers in free text.
  static String redact(String text) =>
      text.replaceAll(_email, '<email>').replaceAll(_phone, '<phone>');
}
