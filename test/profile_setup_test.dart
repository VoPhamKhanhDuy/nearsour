import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/models/avatar.dart';
import 'package:nearsoul/widgets/avatar_image.dart';
import 'package:nearsoul/screens/profile/profile_setup_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';

var _emailCounter = 0;

Future<void> _openProfile(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(403 * 3, 1400 * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.register('profile.test${_emailCounter++}@gmail.com', 'secret1');
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const ProfileSetupScreen()));
  await tester.pumpAndSettle();
}

Future<void> _pickYear(WidgetTester tester, int year) async {
  await tester.tap(find.byType(DropdownButton<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$year').last);
  await tester.pumpAndSettle();
}

Future<void> _tapContinue(WidgetTester tester) async {
  await tester.tap(find.text('Tiếp tục →'));
  await tester.pumpAndSettle();
}

void main() {
  avatarAssetTests();
  testWidgets('shows title, step, nine avatars and the three fields', (tester) async {
    await _openProfile(tester);

    expect(find.text('Tạo hồ sơ của bạn'), findsOneWidget);
    expect(find.text('Bước 1 / 3'), findsOneWidget);
    expect(find.text('Thông tin này sẽ được ẩn danh hoàn toàn'), findsOneWidget);
    for (var id = 1; id <= avatarKeys.length; id++) {
      expect(find.byKey(ValueKey('avatar_$id')), findsOneWidget, reason: 'avatar_$id');
    }
    expect(avatarKeys.length, 12);
    expect(find.text('Biệt danh'), findsOneWidget);
    expect(find.text('Năm sinh'), findsOneWidget);
    for (final g in ['Nam', 'Nữ', 'Khác']) {
      expect(find.text(g), findsOneWidget);
    }
    // Không có gì để quay lại sau khi đăng ký nên không hiện nút back.
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('reports one error at a time, in field order', (tester) async {
    await _openProfile(tester);

    await _tapContinue(tester);
    expect(find.text('Vui lòng nhập biệt danh'), findsOneWidget);
    expect(find.text('Vui lòng chọn năm sinh'), findsNothing);
    expect(find.text('Vui lòng chọn giới tính'), findsNothing);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    expect(find.text('Vui lòng nhập biệt danh'), findsNothing); // sửa ô nào, lỗi ô đó biến mất
    await _tapContinue(tester);
    expect(find.text('Biệt danh phải từ 2 đến 20 ký tự'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sao Bang');
    await _tapContinue(tester);
    expect(find.text('Vui lòng chọn năm sinh'), findsOneWidget);
    expect(find.text('Vui lòng chọn giới tính'), findsNothing);

    await _pickYear(tester, 2005);
    await _tapContinue(tester);
    expect(find.text('Vui lòng chọn giới tính'), findsOneWidget);
    expect(find.text('Vui lòng chọn năm sinh'), findsNothing);
  });

  testWidgets('only offers birth years for users aged 18+', (tester) async {
    await _openProfile(tester);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    expect(find.text('${DateTime.now().year - 18}'), findsWidgets);
    expect(find.text('${DateTime.now().year - 17}'), findsNothing);
  });

  testWidgets('saves the profile and continues to the GPS step, then Home', (tester) async {
    await _openProfile(tester);

    await tester.tap(find.byKey(const ValueKey('avatar_12')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  Sao Bang ');
    await _pickYear(tester, 2005);
    await tester.tap(find.text('Nữ'));
    await tester.pump();
    // Màn GPS có radar chạy liên tục nên không dùng pumpAndSettle.
    await tester.tap(find.text('Tiếp tục →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final user = MockUserStore.currentUser!;
    expect(user.nickname, 'Sao Bang');
    expect(user.birthYear, 2005);
    expect(user.gender, 'female');
    expect(user.avatarId, 12);
    expect(find.text('Kết nối với người gần bạn'), findsOneWidget);
    expect(find.text('Bước 2 / 3'), findsOneWidget);

    await tester.tap(find.text('Tiếp theo →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kết nối sâu sắc trong 48 giờ'), findsOneWidget);
    expect(find.text('Bước 3 / 3'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu ngay →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kích hoạt Radar'), findsWidgets); // trang Radar nằm sau 3 bước hồ sơ, không có thanh bước
    expect(find.textContaining('Bước'), findsNothing);

    await tester.tap(find.text('BỎ QUA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Radar Discover'), findsOneWidget);
    await tester.tap(find.text('Cá nhân'));
    await tester.pump();
    expect(find.text('Sao Bang'), findsOneWidget);
    expect(find.byType(AvatarImage), findsOneWidget);
  });
}

void avatarAssetTests() {
  test('every avatar key has an image file and ids map to assets', () {
    for (final key in avatarKeys) {
      expect(File('assets/images/$key.png').existsSync(), isTrue, reason: key);
    }
    expect(avatarAsset(1), 'assets/images/bear.png');
    expect(avatarAsset(12), 'assets/images/shark.png');
    expect(avatarAsset(0), isNull);
    expect(avatarAsset(13), isNull);
    expect(avatarAsset(null), isNull);
  });
}
