import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// The only error type the UI layer needs to understand. Repositories convert
/// every backend/network exception into one of these with a message that is
/// safe to show to the user.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No connection. Check your internet and try again.',
  ]);
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure([super.message = 'You do not have permission to do that.']);
}

/// A rule the server rejected (e.g. "Check-in date cannot be in the past").
class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'We could not find what you were looking for.']);
}

class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'This already exists.']);
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Something went wrong. Please try again.']);
}

/// Maps any thrown object to an [AppFailure].
AppFailure mapToFailure(Object error) {
  return switch (error) {
    AppFailure() => error,
    AuthRetryableFetchException() => const NetworkFailure(),
    AuthException(:final message, :final code) => AuthFailure(_authMessage(code, message)),
    PostgrestException(:final code, :final message) => _postgrestFailure(code, message),
    StorageException(:final statusCode, :final message) => switch (statusCode) {
      '403' || '401' => const PermissionFailure(),
      '404' => const NotFoundFailure(),
      '413' => const ValidationFailure('That photo is too large. The limit is 5 MB.'),
      _ => UnexpectedFailure(message.isEmpty ? 'Upload failed. Please try again.' : message),
    },
    http.ClientException() || TimeoutException() => const NetworkFailure(),
    _ => const UnexpectedFailure(),
  };
}

/// Runs [body], logging and converting failures to [AppFailure].
Future<T> guard<T>(String operation, Future<T> Function() body) async {
  try {
    return await body();
  } catch (error, stackTrace) {
    final failure = mapToFailure(error);
    AppLogger.failure(operation, failure, error, stackTrace);
    throw failure;
  }
}

AppFailure _postgrestFailure(String? code, String message) {
  return switch (code) {
    // insufficient_privilege / RLS violation
    '42501' => message.contains('row-level security') || message.contains('permission denied')
        ? const PermissionFailure()
        : PermissionFailure(message),
    // raise_exception from our RPCs/triggers: message is written for users.
    'P0001' => ValidationFailure(message),
    '23505' => const ConflictFailure(),
    '23503' => const NotFoundFailure(),
    '23514' || '22001' || '22023' || '22P02' =>
      const ValidationFailure('Some of the details are not valid. Please check and try again.'),
    'PGRST116' => const NotFoundFailure(),
    _ => const UnexpectedFailure(),
  };
}

String _authMessage(String? code, String message) {
  return switch (code) {
    'invalid_credentials' => 'Incorrect email or password.',
    'email_not_confirmed' => 'Please confirm your email address first. Check your inbox.',
    'user_already_exists' || 'email_exists' => 'An account with this email already exists. Try signing in.',
    'weak_password' => 'Choose a stronger password (at least 8 characters with letters and numbers).',
    'over_email_send_rate_limit' || 'over_request_rate_limit' =>
      'Too many attempts. Please wait a moment and try again.',
    'same_password' => 'Your new password must be different from the old one.',
    'user_banned' => 'This account has been suspended.',
    _ => message.isEmpty ? 'Authentication failed. Please try again.' : message,
  };
}
