import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/screens/onboarding/gps_intro_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';

Future<void> _openGps(WidgetTester tester, {bool reduceMotion = false}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(403 * 3, 884 * 3);
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  MockUserStore.logout();
  MockUserStore.login('nearsoul.test@gmail.com', '123456');
  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const GpsIntroScreen()));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows step, radar copy, feature pills and actions', (tester) async {
    await _openGps(tester);

    expect(find.text('Bước 2 / 3'), findsOneWidget);
    expect(find.text('Kết nối với người gần bạn'), findsOneWidget);
    expect(find.textContaining('bán kính 200m'), findsWidgets);
    expect(find.text('12 người gần bạn'), findsOneWidget);
    for (final pill in ['GPS 200M', 'ẨN DANH', 'REAL-TIME']) {
      expect(find.text(pill), findsOneWidget, reason: pill);
    }
    expect(find.text('Tiếp theo →'), findsOneWidget);
    expect(find.text('BỎ QUA'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing); // màn gốc nên không có nút back
  });

  testWidgets('skip goes to the radar activation page, next goes to the 48h step', (tester) async {
    await _openGps(tester);
    await tester.tap(find.text('BỎ QUA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kích hoạt Radar'), findsWidgets); // trang kích hoạt Radar, không có thanh bước
    expect(find.textContaining('Bước'), findsNothing);

    await _openGps(tester);
    await tester.tap(find.text('Tiếp theo →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kết nối sâu sắc trong 48 giờ'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget); // được mở từ GPS nên có nút quay lại
  });


  testWidgets('radar stops animating when the system reduces motion', (tester) async {
    await _openGps(tester, reduceMotion: true);
    // Nếu radar vẫn lặp vô hạn thì pumpAndSettle sẽ báo hết thời gian.
    await tester.pumpAndSettle();
    expect(find.text('Kết nối với người gần bạn'), findsOneWidget);
  });

  testWidgets('fits a short screen without overflow', (tester) async {
    await _openGps(tester);
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
