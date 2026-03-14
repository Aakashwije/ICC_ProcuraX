import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/services/auth_service.dart';

void main() {
  /* ═══════════════════════════════════════════════════════════════════ */
  /*  PasswordResetException                                            */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('PasswordResetException', () {
    test('factory fromResponse parses all fields', () {
      final exc = PasswordResetException.fromResponse(400, {
        'code': 'WEAK_PASSWORD',
        'message': 'Password too weak',
        'attemptsRemaining': 3,
        'retryAfter': 60,
        'requirements': ['uppercase', 'digit', 'special'],
      });

      expect(exc.code, equals('WEAK_PASSWORD'));
      expect(exc.message, equals('Password too weak'));
      expect(exc.statusCode, equals(400));
      expect(exc.attemptsRemaining, equals(3));
      expect(exc.retryAfter, equals(60));
      expect(
        exc.requirements,
        orderedEquals(['uppercase', 'digit', 'special']),
      );
    });

    test('factory defaults code to UNKNOWN when missing', () {
      final exc = PasswordResetException.fromResponse(500, {});
      expect(exc.code, equals('UNKNOWN'));
      expect(exc.message, equals('Something went wrong'));
    });

    test('factory defaults message when missing', () {
      final exc = PasswordResetException.fromResponse(500, {'code': 'ERR'});
      expect(exc.message, equals('Something went wrong'));
    });

    test('nullable fields default to null', () {
      final exc = PasswordResetException.fromResponse(400, {
        'code': 'X',
        'message': 'Y',
      });
      expect(exc.attemptsRemaining, isNull);
      expect(exc.retryAfter, isNull);
      expect(exc.requirements, isNull);
    });

    // Boolean helper getters
    test('isLocked returns true for ACCOUNT_LOCKED', () {
      final exc = PasswordResetException(
        code: 'ACCOUNT_LOCKED',
        message: '',
        statusCode: 403,
      );
      expect(exc.isLocked, isTrue);
      expect(exc.isRateLimited, isFalse);
    });

    test('isRateLimited returns true for RATE_LIMITED', () {
      final exc = PasswordResetException(
        code: 'RATE_LIMITED',
        message: '',
        statusCode: 429,
      );
      expect(exc.isRateLimited, isTrue);
      expect(exc.isLocked, isFalse);
    });

    test('isExpired returns true for OTP_EXPIRED', () {
      final exc = PasswordResetException(
        code: 'OTP_EXPIRED',
        message: '',
        statusCode: 400,
      );
      expect(exc.isExpired, isTrue);
    });

    test('isInvalidOTP returns true for INVALID_OTP', () {
      final exc = PasswordResetException(
        code: 'INVALID_OTP',
        message: '',
        statusCode: 400,
      );
      expect(exc.isInvalidOTP, isTrue);
    });

    test('isWeakPassword returns true for WEAK_PASSWORD', () {
      final exc = PasswordResetException(
        code: 'WEAK_PASSWORD',
        message: '',
        statusCode: 400,
      );
      expect(exc.isWeakPassword, isTrue);
    });

    test('isSamePassword returns true for SAME_PASSWORD', () {
      final exc = PasswordResetException(
        code: 'SAME_PASSWORD',
        message: '',
        statusCode: 400,
      );
      expect(exc.isSamePassword, isTrue);
    });

    test('toString returns the message', () {
      final exc = PasswordResetException(
        code: 'X',
        message: 'Human-readable error',
        statusCode: 400,
      );
      expect(exc.toString(), equals('Human-readable error'));
    });

    test('all boolean helpers are false for unknown code', () {
      final exc = PasswordResetException(
        code: 'SOMETHING_ELSE',
        message: '',
        statusCode: 400,
      );
      expect(exc.isLocked, isFalse);
      expect(exc.isRateLimited, isFalse);
      expect(exc.isExpired, isFalse);
      expect(exc.isInvalidOTP, isFalse);
      expect(exc.isWeakPassword, isFalse);
      expect(exc.isSamePassword, isFalse);
    });
  });
}
