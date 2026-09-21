import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/models/match.dart';
import 'package:nearsoul/screens/main/main_shell.dart';
import 'package:nearsoul/theme/app_theme.dart';
import 'package:nearsoul/widgets/avatar_image.dart';

Future<void> _openShell(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(403 * 3, 900 * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  final user = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456');
  user
    ..isScanning = false
    ..blockedUsers.clear();
  MockUserStore.matches.clear();

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const MainShell()));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Kết thúc test: gỡ cây widget để huỷ timer "tìm người" và các animation còn chạy.
Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

/// Bật quét rồi chờ radar "tìm thấy" người và sheet trượt lên xong.
Future<void> _startAndFind(WidgetTester tester) async {
  await tester.tap(find.text('Sẵn sàng kết nối'));
  await tester.pump();
  await _waitForNextFind(tester);
}

Future<void> _waitForNextFind(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3)); // hết thời gian giả lập
  await tester.pump(const Duration(milliseconds: 500)); // sheet trượt lên
}

Future<void> _tapAndSettleSheet(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500)); // sheet đóng
}

void main() {
  group('MockUserStore radar data', () {
    setUp(() {
      MockUserStore.logout();
      MockUserStore.login('phamkhanhduyvo@gmail.com', '123456').blockedUsers.clear();
      MockUserStore.matches.clear();
    });

    test('finds people in order and honours skipped / blocked / distance filters', () {
      expect(MockUserStore.nextNearby()!.user.nickname, 'Mây Nhỏ');
      expect(MockUserStore.nextNearby(skipped: {'s1'})!.user.nickname, 'Nắng Mai');

      MockUserStore.blockUser('s1');
      expect(MockUserStore.nextNearby()!.user.nickname, 'Nắng Mai');
      expect(MockUserStore.nextNearby(skipped: {'s1', 's2', 's3'}), isNull);
      for (final p in MockUserStore.nearby) {
        expect(p.distanceMeters <= MockUserStore.radarRadiusMeters, isTrue, reason: p.user.nickname);
      }
    });

    test('blocking twice keeps a single entry; sendRequest creates a pending match', () {
      MockUserStore.blockUser('s1');
      MockUserStore.blockUser('s1');
      expect(MockUserStore.currentUser!.blockedUsers, ['s1']);

      final match = MockUserStore.sendRequest('s2');
      expect(match.status, MatchStatus.pending);
      expect(match.userA, MockUserStore.currentUser!.id);
      expect(match.userB, 's2');
      expect(MockUserStore.matches, [match]);
    });

    test('new registrations never reuse a seeded account id', () {
      const seeded = {'u1', 'u2', 'u4', 'u5', 'u6'};
      final created = MockUserStore.register('unique.id.check@gmail.com', 'secret1');
      expect(seeded.contains(created.id), isFalse);
      MockUserStore.logout();
    });
  });

  testWidgets('scanning finds a nearby person and shows the preview sheet', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);

    expect(find.text('TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN'), findsOneWidget);
    expect(find.text('Mây Nhỏ'), findsOneWidget);
    expect(find.text('21 tuổi · 120m'), findsOneWidget);
    expect(find.textContaining('quán cà phê yên tĩnh'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(find.text('Chặn ngay'), findsOneWidget);
    expect(find.text('Gửi yêu cầu kết nối'), findsOneWidget);
    expect(find.textContaining('Thông tin thật chỉ mở khi cả hai'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('header logo + NEARSOUL stay behind the blur, and one avatar widget is used everywhere', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);

    // Header (logo tròn + tên thương hiệu + Online) vẫn nằm phía sau lớp blur của sheet.
    expect(find.text('NEARSOUL'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ClipOval), matching: find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/logo.png')),
      findsOneWidget,
    );
    expect(find.text('Online'), findsWidgets);

    // Avatar ở tâm radar và trên sheet đều là AvatarImage (cùng bộ avatar hoạt hình của app).
    expect(find.byType(AvatarImage), findsNWidgets(2));
    final stranger = tester.widgetList<AvatarImage>(find.byType(AvatarImage)).map((a) => a.avatarId).toSet();
    expect(stranger, containsAll([MockUserStore.currentUser!.avatarId, 11]));
    await _dispose(tester);
  });

  testWidgets('skip closes the sheet, keeps scanning and finds the next person', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);

    await _tapAndSettleSheet(tester, 'Bỏ qua');
    expect(find.text('Mây Nhỏ'), findsNothing);
    expect(find.text('Dừng tìm kiếm'), findsOneWidget); // vẫn đang quét

    await _waitForNextFind(tester);
    expect(find.text('Nắng Mai'), findsOneWidget);
    expect(find.text('24 tuổi · 85m'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('tapping outside the sheet counts as skip', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);

    await tester.tapAt(const Offset(20, 120)); // vùng nền mờ phía trên sheet
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Mây Nhỏ'), findsNothing);

    await _waitForNextFind(tester);
    expect(find.text('Nắng Mai'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('block remembers the person, never shows them again, and tells the user', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);

    await _tapAndSettleSheet(tester, 'Chặn ngay');
    expect(MockUserStore.currentUser!.blockedUsers, ['s1']);
    expect(find.textContaining('Đã chặn Mây Nhỏ'), findsOneWidget);

    await _waitForNextFind(tester);
    expect(find.text('Mây Nhỏ'), findsNothing);
    expect(find.text('Nắng Mai'), findsOneWidget);
    await _dispose(tester);
  });

  const noConnection = 'Không tìm thấy kết nối lúc này, tiếp tục quét...';

  testWidgets('connect keeps the sheet open with a 30s countdown; accepted → Get Ready', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);

    await tester.tap(find.text('Gửi yêu cầu kết nối'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Sheet ở lại, nút chuyển sang "Đang chờ phản hồi... 30s" và đếm lùi mỗi giây.
    expect(find.text('Đang chờ phản hồi... 30s'), findsOneWidget);
    expect(find.text('Gửi yêu cầu kết nối'), findsNothing);
    final match = MockUserStore.matches.single;
    expect(match.userB, 's1');
    expect(match.status, MatchStatus.pending);
    expect(match.requestExpiresAt!.difference(match.createdAt).inSeconds, 30);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Đang chờ phản hồi... 29s'), findsOneWidget);

    // Mây Nhỏ (giả lập) đồng ý sau 3 giây → cả hai vào Get Ready.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN'), findsNothing);
    expect(find.text('Cả hai đã sẵn sàng'), findsOneWidget);
    expect(match.status, MatchStatus.quiz);
    expect(MockUserStore.currentUser!.isScanning, isFalse);
    await _dispose(tester);
  });

  testWidgets('while waiting the sheet cannot be dismissed or changed', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);
    await tester.tap(find.text('Gửi yêu cầu kết nối'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Bỏ qua'), warnIfMissed: false);
    await tester.tap(find.text('Chặn ngay'), warnIfMissed: false);
    await tester.tapAt(const Offset(20, 120)); // chạm nền mờ
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Đang chờ phản hồi'), findsOneWidget);
    expect(MockUserStore.currentUser!.blockedUsers, isEmpty);
    await _dispose(tester);
  });

  testWidgets('declined and ignored requests look exactly the same to the sender', (tester) async {
    Future<void> reachAndSend(String nickname) async {
      await _openShell(tester);
      await _startAndFind(tester);
      // Bỏ qua lần lượt cho tới khi tới đúng người cần thử.
      while (find.text(nickname).evaluate().isEmpty) {
        await _tapAndSettleSheet(tester, 'Bỏ qua');
        await _waitForNextFind(tester);
      }
      await tester.tap(find.text('Gửi yêu cầu kết nối'));
      await tester.pump(const Duration(milliseconds: 100));
    }

    String visibleSnapshot() => [
          find.text(noConnection).evaluate().isNotEmpty,
          find.text('Dừng tìm kiếm').evaluate().isNotEmpty, // radar vẫn quét
          find.text('TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN').evaluate().isNotEmpty, // sheet đã đóng
          find.textContaining('từ chối').evaluate().isNotEmpty,
          find.textContaining('Từ chối').evaluate().isNotEmpty,
        ].toString();

    // Nắng Mai từ chối sau 3 giây.
    await reachAndSend('Nắng Mai');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    final declined = visibleSnapshot();
    expect(MockUserStore.matches.last.status, MatchStatus.rejected);
    await _dispose(tester);

    // Gió Đông im lặng, yêu cầu tự hết hạn sau 30 giây.
    await reachAndSend('Gió Đông');
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 500));
    final ignored = visibleSnapshot();
    expect(MockUserStore.matches.last.status, MatchStatus.expired);
    await _dispose(tester);

    // Cả hai: sheet đóng, một dòng trung tính, radar vẫn quét, tuyệt đối không có chữ "từ chối".
    expect(declined, '[true, true, false, false, false]');
    expect(ignored, declined);
  });

  testWidgets('after a failed request the person is not shown again and the radar keeps looking', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);
    await _tapAndSettleSheet(tester, 'Bỏ qua'); // Mây Nhỏ
    await _waitForNextFind(tester);
    expect(find.text('Nắng Mai'), findsOneWidget);
    await tester.tap(find.text('Gửi yêu cầu kết nối'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500)); // Nắng Mai từ chối

    await _waitForNextFind(tester);
    expect(find.text('Nắng Mai'), findsNothing);
    expect(find.text('Gió Đông'), findsOneWidget);
    await _dispose(tester);
  });


  testWidgets('stopping before the find delay shows no sheet', (tester) async {
    await _openShell(tester);
    await tester.tap(find.text('Sẵn sàng kết nối'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Dừng tìm kiếm'));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('when everyone was skipped, radar keeps scanning and says so', (tester) async {
    await _openShell(tester);
    await _startAndFind(tester);
    for (var i = 0; i < 3; i++) {
      await _tapAndSettleSheet(tester, 'Bỏ qua');
      await _waitForNextFind(tester);
    }

    expect(find.text('TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN'), findsNothing);
    expect(find.textContaining('Chưa có ai khác phù hợp'), findsOneWidget);
    expect(find.text('Dừng tìm kiếm'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('sheet fits a short screen', (tester) async {
    await _openShell(tester);
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    await _startAndFind(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Gửi yêu cầu kết nối'), findsOneWidget);
    await _dispose(tester);
  });
}
