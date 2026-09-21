import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/models/user.dart';
import 'package:nearsoul/screens/match/get_ready_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';
import 'package:nearsoul/widgets/avatar_image.dart';

late AppUser _me;
late AppUser _partner;

/// Mở Get Ready như một route được đẩy lên trên một trang gốc (giống luồng thật).
Future<void> _open(WidgetTester tester, {Size size = const Size(403, 900), bool reduceMotion = false}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  MockUserStore.logout();
  _me = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456');
  _partner = MockUserStore.nearby.first.user;

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => GetReadyScreen(me: _me, partner: _partner)),
            ),
            child: const Text('mở'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400)); // route trượt vào xong
}

/// Kết thúc test: gỡ cây widget để huỷ timer đếm ngược và animation.
Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

/// Đi tới thời điểm [ms] tính từ lúc mở màn (mỗi nhịp đếm cần thêm 1 frame để chữ cũ mờ hẳn).
Future<void> _elapse(WidgetTester tester, int ms) => tester.pump(Duration(milliseconds: ms));

void main() {
  testWidgets('shows header, both players with nicknames, status and privacy note', (tester) async {
    await _open(tester);

    // Header chuẩn: logo tròn + tên NEARSOUL, và trạng thái "Đã kết nối" chỉ ở một chỗ.
    expect(find.text('NEARSOUL'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/logo.png'),
      findsOneWidget,
    );
    expect(find.text('Đã kết nối'), findsOneWidget);

    // Hai avatar hoạt hình thật (không còn icon placeholder) kèm biệt danh.
    final avatars = tester.widgetList<AvatarImage>(find.byType(AvatarImage)).map((a) => a.avatarId).toList();
    expect(avatars, [_me.avatarId, _partner.avatarId]);
    expect(find.text(_me.nickname!), findsOneWidget);
    expect(find.text(_partner.nickname!), findsOneWidget);
    expect(find.byIcon(Icons.cloud), findsNothing);

    expect(find.text('Cả hai đã sẵn sàng'), findsOneWidget);
    expect(find.text('Chuẩn bị bắt đầu AI Quiz'), findsOneWidget);
    expect(find.text('Đáp án của bạn sẽ được ẩn với đối phương.'), findsOneWidget);
    // Không lặp lại thông tin: số đếm ngược không kèm dòng "Tự động bắt đầu sau 3 giây" hay dòng đồng bộ riêng.
    expect(find.textContaining('Tự động bắt đầu'), findsNothing);
    expect(find.textContaining('Đồng bộ'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('countdown runs 3 → 2 → 1 → "Bắt đầu!" then opens the AI Quiz by itself', (tester) async {
    await _open(tester);
    expect(find.text('3'), findsOneWidget);

    await _elapse(tester, 1000); // t=1s: nhịp 1
    await _elapse(tester, 400);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);

    await _elapse(tester, 600); // t=2s: nhịp 2
    await _elapse(tester, 400);
    expect(find.text('1'), findsOneWidget);

    await _elapse(tester, 600); // t=3s: nhịp 3 → "Bắt đầu!"
    await _elapse(tester, 400);
    expect(find.text('Bắt đầu!'), findsOneWidget);
    expect(find.text('AI Quiz'), findsNothing); // đang giữ chữ "Bắt đầu!" một lúc

    await _elapse(tester, 500); // hết thời gian giữ → tự vào Quiz
    await _elapse(tester, 400);
    expect(find.text('AI Quiz'), findsOneWidget);
    expect(find.textContaining('Mây Nhỏ'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('cannot be dismissed with back while counting down', (tester) async {
    await _open(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('mở'), findsNothing); // vẫn ở Get Ready, không quay về trang gốc
    expect(find.text('Cả hai đã sẵn sàng'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    await _dispose(tester);
  });

  testWidgets('leaving the screen mid-countdown cancels the timers', (tester) async {
    await _open(tester);
    await _elapse(tester, 1500);
    await _dispose(tester); // nếu timer còn sống, test sẽ báo "Timer is still pending"
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('reduced motion: effects stop but the countdown still works', (tester) async {
    await _open(tester, reduceMotion: true);
    expect(find.text('3'), findsOneWidget);
    await _elapse(tester, 1000);
    await _elapse(tester, 400);
    expect(find.text('2'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('fits a narrow, short screen', (tester) async {
    await _open(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    expect(find.text('3'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('quiz placeholder returns to the Radar tab', (tester) async {
    await _open(tester);
    await _elapse(tester, 3000);
    await _elapse(tester, 1000);
    await _elapse(tester, 400);
    expect(find.text('AI Quiz'), findsOneWidget);

    await tester.tap(find.text('Về Radar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Radar Discover'), findsOneWidget);
    await _dispose(tester);
  });
}
