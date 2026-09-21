import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/main.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/utils/validators.dart';

void _usePhoneSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(403 * 3, 884 * 3);
  addTearDown(tester.view.reset);
}

Future<void> _openAuth(WidgetTester tester, String buttonLabel) async {
  _usePhoneSurface(tester);
  await tester.pumpWidget(const NearSoulApp());
  await tester.tap(find.text(buttonLabel));
  await tester.pumpAndSettle();
}

Finder get _fields => find.byType(TextField);
Finder get _loginButton => find.widgetWithText(InkWell, 'Đăng nhập');

Future<void> _submitRegister(WidgetTester tester) async {
  await tester.tap(find.text('Đăng ký ngay'));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _submitLogin(WidgetTester tester) async {
  await tester.tap(_loginButton);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(MockUserStore.logout);

  group('Validators.email', () {
    test('accepts valid emails from any provider', () {
      for (final ok in [
        'nearsoul.test@gmail.com',
        'abc@outlook.com',
        'first.last@yahoo.com.vn',
        'a+tag@sub.domain.edu',
      ]) {
        expect(Validators.email(ok), isNull, reason: ok);
      }
    });

    test('rejects invalid addresses', () {
      for (final bad in [
        '',
        'fsfsfsf',
        'abc@',
        '@gmail.com',
        'abc@gmail',
        'abc@gmail.',
        'abc@@gmail.com',
        'abc def@gmail.com',
        'abc@gmail..com',
      ]) {
        expect(Validators.email(bad), isNotNull, reason: bad);
      }
    });
  });

  testWidgets('Welcome screen shows both actions', (tester) async {
    await tester.pumpWidget(const NearSoulApp());

    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Đúng người. Đúng thời điểm.'), findsOneWidget);
  });

  testWidgets('Register mode: confirm field, hints, login link at the bottom', (tester) async {
    await _openAuth(tester, 'Tạo tài khoản');

    expect(_fields, findsNWidgets(3));
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsNothing);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
    expect(find.text(Validators.emailHint), findsOneWidget);
    expect(find.text(Validators.passwordHint), findsOneWidget);
    expect(find.textContaining('Đã có tài khoản?', findRichText: true), findsOneWidget);
  });

  testWidgets('Login mode: forgot password, register link, no hints, no confirm', (tester) async {
    await _openAuth(tester, 'Đăng nhập');

    expect(_fields, findsNWidgets(2));
    expect(find.text('Xác nhận mật khẩu'), findsNothing);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text(Validators.emailHint), findsNothing);
    expect(find.text(Validators.passwordHint), findsNothing);
    expect(find.textContaining('Chưa có tài khoản?', findRichText: true), findsOneWidget);
  });

  testWidgets('Switching mode via bottom link toggles the form', (tester) async {
    await _openAuth(tester, 'Tạo tài khoản');

    await tester.tap(find.textContaining('Đã có tài khoản?', findRichText: true));
    await tester.pumpAndSettle();
    expect(_fields, findsNWidgets(2));
    expect(find.text('Quên mật khẩu?'), findsOneWidget);

    await tester.tap(find.textContaining('Chưa có tài khoản?', findRichText: true));
    await tester.pumpAndSettle();
    expect(_fields, findsNWidgets(3));
  });

  testWidgets('Typing into all three fields keeps text and focus stable', (tester) async {
    await _openAuth(tester, 'Tạo tài khoản');

    for (var round = 0; round < 10; round++) {
      for (var i = 0; i < 3; i++) {
        await tester.tap(_fields.at(i));
        await tester.pump();
        await tester.enterText(_fields.at(i), 'abcdefghij'.substring(0, round + 1));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    await tester.pump(const Duration(seconds: 2));

    for (var i = 0; i < 3; i++) {
      final editable = tester.widget<EditableText>(
        find.descendant(of: _fields.at(i), matching: find.byType(EditableText)),
      );
      expect(editable.controller.text, 'abcdefghij');
    }
    // Ô cuối cùng được bấm vẫn giữ focus, không tự nhảy.
    final last = tester.widget<EditableText>(
      find.descendant(of: _fields.at(2), matching: find.byType(EditableText)),
    );
    expect(last.focusNode.hasFocus, isTrue);
  });

  group('Register errors', () {
    testWidgets('bad email is reported only after leaving the field, not while typing', (tester) async {
      await _openAuth(tester, 'Tạo tài khoản');

      await tester.tap(_fields.at(0));
      await tester.pump();
      await tester.enterText(_fields.at(0), 'fsfsfsf');
      await tester.pump();
      expect(find.text(Validators.email('fsfsfsf')!), findsNothing);

      await tester.tap(_fields.at(1)); // rời khỏi ô email
      await tester.pumpAndSettle();
      expect(find.text(Validators.email('fsfsfsf')!), findsOneWidget);
      expect(find.text(Validators.emailHint), findsNothing); // lỗi thay cho gợi ý

      await tester.enterText(_fields.at(0), 'abcdef@gmail.com'); // sửa lại → lỗi biến mất
      await tester.pumpAndSettle();
      expect(find.text(Validators.email('fsfsfsf')!), findsNothing);
      expect(find.text(Validators.emailHint), findsOneWidget);
    });

    testWidgets('empty submit shows a single required error, not all at once', (tester) async {
      await _openAuth(tester, 'Tạo tài khoản');
      await _submitRegister(tester);

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
      expect(find.text('Vui lòng xác nhận mật khẩu'), findsNothing);
    });

    testWidgets('short password is reported once the field is done', (tester) async {
      await _openAuth(tester, 'Tạo tài khoản');

      await tester.tap(_fields.at(1));
      await tester.pump();
      await tester.enterText(_fields.at(1), '123');
      await tester.pump();
      expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsNothing);

      await tester.tap(_fields.at(2)); // rời khỏi ô mật khẩu
      await tester.pump();
      expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
    });

    testWidgets('mismatched confirm is reported on submit only', (tester) async {
      await _openAuth(tester, 'Tạo tài khoản');

      await tester.enterText(_fields.at(0), 'new.user@gmail.com');
      await tester.enterText(_fields.at(1), 'secret1');
      await tester.enterText(_fields.at(2), 'secret2');
      await tester.pump();
      expect(find.text('Mật khẩu xác nhận không khớp'), findsNothing);

      await _submitRegister(tester);
      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
      expect(find.text('Tạo hồ sơ của bạn'), findsNothing);
    });

    testWidgets('success goes to profile setup; duplicate email is rejected', (tester) async {
      await _openAuth(tester, 'Tạo tài khoản');

      await tester.enterText(_fields.at(0), 'new.user@gmail.com');
      await tester.enterText(_fields.at(1), 'secret1');
      await tester.enterText(_fields.at(2), 'secret1');
      await _submitRegister(tester);
      await tester.pumpAndSettle();
      expect(find.text('Tạo hồ sơ của bạn'), findsOneWidget);

      // Quay lại luồng Auth qua mock (chưa có nút đăng xuất ở màn hồ sơ) để thử đăng ký trùng.
      MockUserStore.logout();
      await tester.pumpWidget(const SizedBox()); // bỏ cây cũ để app dựng lại từ Welcome
      await tester.pumpWidget(const NearSoulApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo tài khoản'));
      await tester.pumpAndSettle();
      await tester.enterText(_fields.at(0), 'new.user@gmail.com');
      await tester.enterText(_fields.at(1), 'secret1');
      await tester.enterText(_fields.at(2), 'secret1');
      await _submitRegister(tester);
      expect(find.text('Email này đã được đăng ký'), findsOneWidget);
    });
  });

  group('Login errors', () {
    testWidgets('no format errors while typing or leaving a field', (tester) async {
      await _openAuth(tester, 'Đăng nhập');

      await tester.tap(_fields.at(0));
      await tester.pump();
      await tester.enterText(_fields.at(0), 'fsfsfsf');
      await tester.tap(_fields.at(1)); // rời ô email
      await tester.pump();
      await tester.enterText(_fields.at(1), '1');
      await tester.tap(_fields.at(0)); // rời ô mật khẩu
      await tester.pump();

      expect(find.textContaining('không đúng'), findsNothing);
      expect(find.textContaining('ít nhất'), findsNothing);
      expect(find.textContaining('Vui lòng'), findsNothing);
      expect(find.textContaining('định dạng'), findsNothing);
    });
    testWidgets('malformed email shows only "Email không đúng định dạng"', (tester) async {
      await _openAuth(tester, 'Đăng nhập');

      await tester.enterText(_fields.at(0), 'fsfsfsf');
      await tester.enterText(_fields.at(1), '1');
      await _submitLogin(tester);

      expect(find.text('Email không đúng định dạng'), findsOneWidget);
      expect(find.text('Mật khẩu không đúng'), findsNothing);
    });

    testWidgets('well-formed but unknown email shows only "Email không đúng"', (tester) async {
      await _openAuth(tester, 'Đăng nhập');

      await tester.enterText(_fields.at(0), 'nobody@outlook.com');
      await tester.enterText(_fields.at(1), '1');
      await _submitLogin(tester);

      expect(find.text('Email không đúng'), findsOneWidget);
      expect(find.text('Mật khẩu không đúng'), findsNothing);
    });

    testWidgets('wrong password shows only "Mật khẩu không đúng", then correct one works', (tester) async {
      await _openAuth(tester, 'Đăng nhập');

      await tester.enterText(_fields.at(0), 'nearsoul.test@gmail.com');
      await tester.enterText(_fields.at(1), 'wrong-pass');
      await _submitLogin(tester);
      expect(find.text('Mật khẩu không đúng'), findsOneWidget);
      expect(find.text('Email không đúng'), findsNothing);

      await tester.enterText(_fields.at(1), '123456');
      await tester.pump();
      expect(find.text('Mật khẩu không đúng'), findsNothing); // sửa lại → lỗi biến mất

      await _submitLogin(tester);
      await tester.pump(const Duration(milliseconds: 600));
      // Tài khoản đã có hồ sơ: vào thẳng trang kích hoạt Radar (không phải Home, không có thanh bước tạo hồ sơ).
      expect(find.text('Kích hoạt Radar'), findsWidgets);
      expect(find.textContaining('Bước'), findsNothing);
    });

    testWidgets('empty submit shows a single required error', (tester) async {
      await _openAuth(tester, 'Đăng nhập');
      await _submitLogin(tester);

      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsNothing);
    });
  });
}
