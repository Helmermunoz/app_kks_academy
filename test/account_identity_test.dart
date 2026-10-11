import 'package:flutter_test/flutter_test.dart';
import 'package:app_kks_academy/account_identity.dart';

void main() {
  test('username login normalizes and preserves existing email access', () {
    expect(
      accountEmail(' Andres.Munoz '),
      'andres.munoz@users.kksacademy.invalid',
    );
    expect(accountEmail('helmer1997@hotmail.es'), 'helmer1997@hotmail.es');
    expect(validAccountLogin('andres.munoz'), isTrue);
    expect(validAccountLogin('ab'), isFalse);
    expect(validAccountLogin('andres munoz'), isFalse);
  });
}
