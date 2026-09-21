import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/screens/onboarding/intro_48h_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';

Future<void> _open(WidgetTester tester, {Size size = const Size(403, 884)}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.login('nearsoul.test@gmail.com', '123456');
  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const Intro48hScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the 48h card, copy and the two stats without repeating info', (tester) async {
    await _open(tester);

    expect(find.text('Bước 3 / 3'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('GIỜ'), findsOneWidget);
    expect(find.text('Kết nối sâu sắc trong 48 giờ'), findsOneWidget);
    // Mỗi bước chỉ xuất hiện một lần (không còn hàng chip lặp lại).
    for (final step in ['AI Quiz', 'Chat', 'Gặp nhau']) {
      expect(find.text(step), findsOneWidget, reason: step);
    }
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('48h'), findsNothing);
  });

  testWidgets('last setup step: no skip; start goes to the radar activation page', (tester) async {
    await _open(tester);

    expect(find.text('BỎ QUA'), findsNothing);
    await tester.tap(find.text('Bắt đầu ngay →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kích hoạt Radar'), findsWidgets);
    // Trang Radar không thuộc 3 bước tạo hồ sơ nên không còn thanh "Bước x / 3".
    expect(find.textContaining('Bước'), findsNothing);
  });

  testWidgets('fits a short screen (scrolls instead of overflowing)', (tester) async {
    await _open(tester, size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    expect(find.text('Bắt đầu ngay →'), findsOneWidget);
  });
}
