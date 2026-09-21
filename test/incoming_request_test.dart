import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/models/match.dart';
import 'package:nearsoul/screens/main/radar_discover_tab.dart';
import 'package:nearsoul/theme/app_theme.dart';

/// Mở tab Radar với "người gửi yêu cầu đến" xuất hiện sau 2 giây quét; tắt việc tự tìm người để chỉ thử yêu cầu đến.
Future<void> _openTab(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(403 * 3, 900 * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.login('phamkhanhduyvo@gmail.com', '123456')
    ..isScanning = false
    ..blockedUsers.clear();
  MockUserStore.matches.clear();

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: RadarDiscoverTab(findDelay: Duration(minutes: 10), incomingDelay: Duration(seconds: 2)),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

/// Bật quét và chờ yêu cầu đến hiện lên.
Future<void> _receive(WidgetTester tester) async {
  await tester.tap(find.text('Sẵn sàng kết nối'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapSheet(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('MockUserStore request lifecycle', () {
    setUp(() {
      MockUserStore.logout();
      MockUserStore.login('phamkhanhduyvo@gmail.com', '123456');
      MockUserStore.matches.clear();
    });

    test('a received request is addressed to me and expires in 30s', () {
      final match = MockUserStore.receiveRequest('s4');
      expect(match.userA, 's4');
      expect(match.userB, MockUserStore.currentUser!.id);
      expect(match.status, MatchStatus.pending);
      expect(match.requestExpiresAt!.difference(match.createdAt), MockUserStore.requestTimeout);
      expect(MockUserStore.requestTimeout, const Duration(seconds: 30));
    });

    test('only a pending request can be accepted, declined or expired (first outcome wins)', () {
      final a = MockUserStore.sendRequest('s1')..status = MatchStatus.pending;
      MockUserStore.declineRequest(a.id);
      MockUserStore.acceptRequest(a.id);
      MockUserStore.expireRequest(a.id);
      expect(a.status, MatchStatus.rejected);

      final b = MockUserStore.sendRequest('s2');
      MockUserStore.expireRequest(b.id);
      MockUserStore.acceptRequest(b.id);
      expect(b.status, MatchStatus.expired);

      final c = MockUserStore.sendRequest('s3');
      MockUserStore.acceptRequest(c.id);
      expect(c.status, MatchStatus.quiz);
    });

    test('mock people answer differently: accept, decline, ignore', () {
      final byId = {for (final p in MockUserStore.nearby) p.user.id: p.response};
      expect(byId, {'s1': MockResponse.accept, 's2': MockResponse.decline, 's3': MockResponse.ignore});
    });
  });

  testWidgets('incoming request shows who wants to connect, with Accept / Decline / Block and a countdown', (tester) async {
    await _openTab(tester);
    await _receive(tester);

    expect(find.text('TRĂNG NON MUỐN KẾT NỐI VỚI BẠN'), findsOneWidget);
    expect(find.text('Trăng Non'), findsOneWidget);
    expect(find.textContaining('tuổi · 60m'), findsOneWidget);
    expect(find.text('Chấp nhận'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Chặn ngay'), findsOneWidget);
    expect(find.text('Yêu cầu hết hạn sau 30s...'), findsOneWidget);
    expect(find.text('Gửi yêu cầu kết nối'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Yêu cầu hết hạn sau 25s...'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('accept sends both people to Get Ready', (tester) async {
    await _openTab(tester);
    await _receive(tester);

    await _tapSheet(tester, 'Chấp nhận');
    expect(find.text('Cả hai đã sẵn sàng'), findsOneWidget);
    expect(find.text('Trăng Non'), findsOneWidget); // người gửi hiện ở Get Ready
    expect(MockUserStore.matches.single.status, MatchStatus.quiz);
    expect(MockUserStore.matches.single.userA, 's4');
    expect(MockUserStore.currentUser!.isScanning, isFalse);
    await _dispose(tester);
  });

  testWidgets('decline just closes the sheet: no message, radar keeps scanning', (tester) async {
    await _openTab(tester);
    await _receive(tester);

    await _tapSheet(tester, 'Từ chối');
    expect(find.text('TRĂNG NON MUỐN KẾT NỐI VỚI BẠN'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Dừng tìm kiếm'), findsOneWidget);
    expect(MockUserStore.matches.single.status, MatchStatus.rejected);
    await _dispose(tester);
  });

  testWidgets('block closes the sheet and remembers the sender', (tester) async {
    await _openTab(tester);
    await _receive(tester);

    await _tapSheet(tester, 'Chặn ngay');
    expect(MockUserStore.currentUser!.blockedUsers, ['s4']);
    expect(MockUserStore.matches.single.status, MatchStatus.rejected);
    expect(find.textContaining('Đã chặn Trăng Non'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('an unanswered request expires after 30s and closes by itself', (tester) async {
    await _openTab(tester);
    await _receive(tester);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TRĂNG NON MUỐN KẾT NỐI VỚI BẠN'), findsNothing);
    expect(MockUserStore.matches.single.status, MatchStatus.expired);
    expect(find.text('Dừng tìm kiếm'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('the receiver must choose: tapping outside does not dismiss the request', (tester) async {
    await _openTab(tester);
    await _receive(tester);

    await tester.tapAt(const Offset(20, 120));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TRĂNG NON MUỐN KẾT NỐI VỚI BẠN'), findsOneWidget);
    expect(MockUserStore.matches.single.status, MatchStatus.pending);
    await _dispose(tester);
  });

  testWidgets('an incoming request arrives only once per session', (tester) async {
    await _openTab(tester);
    await _receive(tester);
    await _tapSheet(tester, 'Từ chối');

    await tester.pump(const Duration(seconds: 30));
    expect(find.text('TRĂNG NON MUỐN KẾT NỐI VỚI BẠN'), findsNothing);
    expect(MockUserStore.matches, hasLength(1));
    await _dispose(tester);
  });

  testWidgets('stopping the radar cancels the pending incoming request', (tester) async {
    await _openTab(tester);
    await tester.tap(find.text('Sẵn sàng kết nối'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Dừng tìm kiếm'));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('TRĂNG NON MUỐN KẾT NỐI VỚI BẠN'), findsNothing);
    expect(MockUserStore.matches, isEmpty);
    await _dispose(tester);
  });

  testWidgets('sheet fits a short screen', (tester) async {
    await _openTab(tester);
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    await _receive(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Chấp nhận'), findsOneWidget);
    await _dispose(tester);
  });
}
