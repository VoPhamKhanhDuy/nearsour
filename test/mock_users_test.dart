import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';

void main() {
  setUp(MockUserStore.logout);

  test('seeded accounts can log in with password 123456', () {
    for (final email in [
      'nearsoul.test@gmail.com',
      'phamkhanhduyvo@gmail.com',
      'phamkhanhduyvo@gamil.com',
      'linh.tran@gmail.com',
      'minh.nguyen@outlook.com',
      'chuacohoso@gmail.com',
    ]) {
      expect(MockUserStore.login(email, '123456').email, email, reason: email);
    }
  });

  test('login is case-insensitive on email and rejects wrong password', () {
    expect(MockUserStore.login(' PhamKhanhDuyVo@Gmail.com ', '123456').nickname, 'Duy');
    expect(
      () => MockUserStore.login('phamkhanhduyvo@gmail.com', 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });

  test('only chuacohoso has no profile yet', () {
    expect(MockUserStore.login('chuacohoso@gmail.com', '123456').nickname, isNull);
    expect(MockUserStore.login('phamkhanhduyvo@gmail.com', '123456').nickname, isNotNull);
  });
}
