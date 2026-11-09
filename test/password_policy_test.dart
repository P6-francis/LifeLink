import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/widgets/password_requirements.dart';

void main() {
  group('PasswordPolicy', () {
    test('accepts a password that meets every requirement', () {
      expect(PasswordPolicy.isValid('StrongPass1!'), isTrue);
    });

    test('rejects passwords missing each required character type', () {
      expect(PasswordPolicy.isValid('short1!'), isFalse);
      expect(PasswordPolicy.isValid('strongpass1!'), isFalse);
      expect(PasswordPolicy.isValid('STRONGPASS1!'), isFalse);
      expect(PasswordPolicy.isValid('StrongPass!'), isFalse);
      expect(PasswordPolicy.isValid('StrongPass1'), isFalse);
    });
  });
}
