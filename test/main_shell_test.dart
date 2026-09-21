import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/screens/main/main_shell.dart';
import 'package:nearsoul/theme/app_theme.dart';
import 'package:nearsoul/widgets/avatar_image.dart';

Future<void> _open(WidgetTester tester, {Size size = const Size(403, 900)}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.login('phamkhanhduyvo@gmail.com', '123456');
  MockUserStore.currentUser!.isScanning = false;
  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const MainShell()));
  await tester.pump(const Duration(milliseconds: 100));
}

// Radar chạy animation liên tục nên không dùng pumpAndSettle.
Future<void> _settle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 400));

void main() {
  testWidgets('Radar tab: header with logo/name, one Online badge, title and nav', (tester) async {
    await _open(tester);

    expect(find.text('NEARSOUL'), findsOneWidget);
    expect(find.byType(Image), findsWidgets); // logo ở header
    expect(find.text('Radar Discover'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing); // màn gốc, không có nút back
    for (final tab in ['Radar', 'Danh bạ', 'Cá nhân']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    // "Online" xuất hiện ở badge trạng thái và ở bộ lọc an toàn; không còn dòng "Online · Đang chờ kích hoạt".
    expect(find.text('Online'), findsNWidgets(2));
    expect(find.textContaining('Đang chờ kích hoạt'), findsNothing);
  });

  testWidgets('layout order: radar, action button, explanation, then safety filters', (tester) async {
    await _open(tester);

    final radarY = tester.getTopLeft(find.byType(AvatarImage).first).dy;
    final buttonY = tester.getTopLeft(find.text('Sẵn sàng kết nối')).dy;
    final noteY = tester.getTopLeft(find.textContaining('Hệ thống tự chọn 1 người')).dy;
    final filterY = tester.getTopLeft(find.text('Bộ lọc an toàn')).dy;
    expect(radarY < buttonY && buttonY < noteY && noteY < filterY, isTrue);
    for (final c in ['Không bị chặn', 'Dưới 200m', 'Người lạ']) {
      expect(find.text(c), findsOneWidget, reason: c);
    }
  });

  testWidgets('user avatar sits at the radar centre', (tester) async {
    await _open(tester);
    // Avatar của tài khoản mock (avatarId 4) nằm ở tâm radar.
    final avatar = tester.widget<AvatarImage>(find.byType(AvatarImage).first);
    expect(avatar.avatarId, MockUserStore.currentUser!.avatarId);
    expect(find.text('Bạn'), findsOneWidget);
  });

  testWidgets('ready button toggles scanning and remembers it on the user', (tester) async {
    await _open(tester);
    final user = MockUserStore.currentUser!;

    await tester.tap(find.text('Sẵn sàng kết nối'));
    await _settle(tester);
    expect(find.text('Dừng tìm kiếm'), findsOneWidget);
    expect(find.textContaining('Đang quét trong bán kính 200m'), findsOneWidget);
    expect(user.isScanning, isTrue);

    await tester.tap(find.text('Dừng tìm kiếm'));
    await _settle(tester);
    expect(find.text('Sẵn sàng kết nối'), findsOneWidget);
    expect(user.isScanning, isFalse);
  });

  testWidgets('bottom nav switches tabs; profile shows the profile and logout works', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Danh bạ'));
    await _settle(tester);
    expect(find.textContaining('Những người bạn đã gặp'), findsOneWidget);
    expect(find.text('Radar Discover'), findsNothing);

    await tester.tap(find.text('Cá nhân'));
    await _settle(tester);
    expect(find.text('Xin chào, Duy'), findsOneWidget);
    expect(find.text('phamkhanhduyvo@gmail.com'), findsOneWidget);
    expect(find.text('2003'), findsOneWidget);
    expect(find.text('Nam'), findsOneWidget);

    await tester.tap(find.text('Radar'));
    await _settle(tester);
    expect(find.text('Radar Discover'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await _settle(tester);
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản'), findsOneWidget); // về Welcome
    expect(MockUserStore.currentUser, isNull);
  });

  testWidgets('fits a short screen (scrolls) and radar stops when motion is reduced', (tester) async {
    await _open(tester, size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    expect(find.text('Sẵn sàng kết nối'), findsOneWidget);
  });

  testWidgets('reduced motion: nothing keeps animating', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _open(tester);
    await tester.pumpAndSettle(); // sẽ báo hết thời gian nếu radar vẫn lặp vô hạn
    expect(find.text('Radar Discover'), findsOneWidget);
  });
}
