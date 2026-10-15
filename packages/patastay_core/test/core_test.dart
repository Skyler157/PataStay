import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _jwtWithRole(String role) {
  String part(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'role': role, 'iss': 'supabase'})}.signature';
}

void main() {
  group('AppConfig', () {
    test('reports missing values', () {
      const config = AppConfig(supabaseUrl: '', supabasePublishableKey: '');
      expect(config.isConfigured, isFalse);
      expect(config.problems, hasLength(2));
    });

    test('accepts a URL and publishable key', () {
      const config = AppConfig(supabaseUrl: 'http://127.0.0.1:54321', supabasePublishableKey: 'sb_publishable_abc');
      expect(config.isConfigured, isTrue);
    });

    test('rejects secret and service-role keys', () {
      expect(AppConfig.looksLikeSecretKey('sb_secret_abc'), isTrue);
      expect(AppConfig.looksLikeSecretKey(_jwtWithRole('service_role')), isTrue);
      expect(AppConfig.looksLikeSecretKey(_jwtWithRole('anon')), isFalse);
      final config = AppConfig(supabaseUrl: 'https://x.supabase.co', supabasePublishableKey: _jwtWithRole('service_role'));
      expect(config.isConfigured, isFalse);
    });
  });

  group('PhoneNumbers.normalize', () {
    test('normalises Kenyan formats to E.164', () {
      for (final input in ['0712 345 678', '0712345678', '254712345678', '+254 712 345678', '712345678']) {
        expect(PhoneNumbers.normalize(input), '+254712345678', reason: input);
      }
      expect(PhoneNumbers.normalize('0112345678'), '+254112345678');
    });

    test('rejects invalid numbers', () {
      for (final input in ['', '12345', '0812345678', '+25471234', 'abc']) {
        expect(PhoneNumbers.normalize(input), isNull, reason: input);
      }
    });

    test('keeps international numbers', () {
      expect(PhoneNumbers.normalize('+44 20 7946 0958'), '+442079460958');
    });

    test('formats for display and WhatsApp', () {
      expect(PhoneNumbers.format('+254712345678'), '+254 712 345 678');
      expect(PhoneNumbers.whatsappDigits('+254712345678'), '254712345678');
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('wanjiku@example.co.ke'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('password matches backend policy', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('lettersonly'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('Nairobi2026'), isNull);
    });

    test('confirm password', () {
      final validator = Validators.confirmPassword(() => 'Nairobi2026');
      expect(validator('Nairobi2026'), isNull);
      expect(validator('Mombasa2026'), isNotNull);
    });

    test('optional and required phone', () {
      expect(Validators.phone()(''), isNull);
      expect(Validators.phone(isRequired: true)(''), isNotNull);
      expect(Validators.phone()('0712345678'), isNull);
      expect(Validators.phone()('123'), isNotNull);
    });

    test('compose returns first error', () {
      final validator = Validators.compose([Validators.required('Required'), Validators.maxLength(3, 'Too long')]);
      expect(validator(''), 'Required');
      expect(validator('abcd'), 'Too long');
      expect(validator('abc'), isNull);
    });
  });

  group('Formatters', () {
    test('KES amounts', () {
      expect(Money.kes(3500), 'KES 3,500');
      expect(Money.kes(1250.5), 'KES 1,250.50');
      expect(Money.kesCompact(3500), 'KES 3.5K');
      expect(Money.kesCompact(12000), 'KES 12K');
      expect(Money.kesCompact(800), 'KES 800');
    });

    test('relative dates', () {
      final now = DateTime(2026, 10, 14, 12);
      expect(Dates.relative(DateTime(2026, 10, 14, 8), now: now), 'today');
      expect(Dates.relative(DateTime(2026, 10, 13), now: now), 'yesterday');
      expect(Dates.relative(DateTime(2026, 10, 10), now: now), '4 days ago');
      expect(Dates.relative(DateTime(2026, 9, 30), now: now), '2 weeks ago');
    });
  });

  group('mapToFailure', () {
    test('maps database errors to user-safe failures', () {
      expect(mapToFailure(const PostgrestException(message: 'new row violates row-level security policy', code: '42501')),
          isA<PermissionFailure>());
      final validation = mapToFailure(const PostgrestException(message: 'Check-in date cannot be in the past', code: 'P0001'));
      expect(validation, isA<ValidationFailure>());
      expect(validation.message, 'Check-in date cannot be in the past');
      expect(mapToFailure(const PostgrestException(message: 'dup', code: '23505')), isA<ConflictFailure>());
    });

    test('does not leak raw internal errors', () {
      final failure = mapToFailure(const PostgrestException(message: 'relation "secret_table" does not exist', code: '42P01'));
      expect(failure, isA<UnexpectedFailure>());
      expect(failure.message, isNot(contains('secret_table')));
    });

    test('maps auth errors', () {
      final failure = mapToFailure(const AuthException('Invalid login credentials', code: 'invalid_credentials'));
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Incorrect email or password.');
    });
  });

  group('Profile', () {
    test('parses a database row', () {
      final profile = Profile.fromJson({
        'id': 'u1',
        'full_name': 'Wanjiku Kamau',
        'email': 'w@example.com',
        'phone': '+254712345678',
        'role': 'owner',
        'account_status': 'active',
        'suspended_reason': null,
        'deletion_requested_at': null,
        'created_at': '2026-10-01T10:00:00Z',
        'updated_at': '2026-10-01T10:00:00Z',
      });
      expect(profile.role, UserRole.owner);
      expect(profile.canHost, isTrue);
      expect(profile.isAdmin, isFalse);
      expect(profile.initials, 'WK');
    });
  });

  test('enum db values match the database', () {
    expect(PropertyType.oneBedroom.dbValue, 'one_bedroom');
    expect(PropertyStatus.pendingReview.dbValue, 'pending_review');
    expect(EnquiryStatus.newEnquiry.dbValue, 'new');
  });
}
