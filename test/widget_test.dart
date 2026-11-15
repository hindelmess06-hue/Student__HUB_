import 'package:flutter_test/flutter_test.dart';
import 'package:student_hub/services/email_rules.dart';

void main() {
  group('EmailRules.validate', () {
    test('accepts UEMF addresses', () {
      expect(EmailRules.validate('a.student@ueuromed.org'), isNull);
      expect(EmailRules.validate('  Name.Surname@UEUROMED.ORG '), isNull);
      expect(EmailRules.validate('x@students.ueuromed.org'), isNull);
    });

    test('rejects empty and malformed input', () {
      expect(EmailRules.validate(''), isNotNull);
      expect(EmailRules.validate('not-an-email'), isNotNull);
      expect(EmailRules.validate('a@@ueuromed.org'), isNotNull);
      expect(EmailRules.validate('a..b@ueuromed.org'), isNotNull);
      expect(EmailRules.validate('.a@ueuromed.org'), isNotNull);
    });

    test('rejects other domains', () {
      expect(EmailRules.validate('me@gmail.com'), contains('Only UEMF'));
      expect(EmailRules.validate('me@evil-ueuromed.org.com'), isNotNull);
      expect(EmailRules.validate('me@notueuromed.org'), isNotNull);
    });

    test('suggests the right domain for near-misses', () {
      expect(EmailRules.validate('me@ueuromed.com'), contains('@ueuromed.org'));
      expect(EmailRules.validate('me@ueuromed.ma'), contains('@ueuromed.org'));
    });
  });
}
