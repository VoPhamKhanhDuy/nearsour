import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/models/match.dart';
import 'package:nearsoul/models/user.dart';
import 'package:nearsoul/screens/main/main_shell.dart';
import 'package:nearsoul/theme/app_theme.dart';

late AppUser _me;

/// Tạo một cuộc trò chuyện với người ở gần thứ [index], mở [hoursLeft] giờ nữa thì hết hạn.
Match _chatWith(int index, {int hoursLeft = 40}) {
  final partner = MockUserStore.nearby[index].user;
  final match = MockUserStore.quizMatchWith(partner.id);
  MockUserStore.completeQuiz(
    match,
    userId: _me.id,
    partnerId: partner.id,
    myAnswers: const [0, 0, 0],
    partnerAnswers: const [0, 0, 0],
    myTexts: const ['mình thích cà phê yên tĩnh buổi sáng.'],
    partnerTexts: const ['mình thích đi dạo cùng gió buổi chiều.'],
    freeTextQuestions: const ['Một điều nhỏ khiến bạn vui gần đây?'],
    score: 3,
    matched: true,
  );
  match.chatExpiresAt = DateTime.now().add(Duration(hours: hoursLeft, minutes: 30));
  return match;
}

Future<void> _openContacts(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(403 * 3, 900 * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const MainShell()));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text('Danh bạ'));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  setUp(() {
    MockUserStore.logout();
    MockUserStore.clearHidden();
    MockUserStore.matches.clear();
    MockUserStore.messages.clear();
    _me = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456')..isScanning = false;
  });

  testWidgets('with no chat, the contacts tab explains what will show up', (tester) async {
    await _openContacts(tester);
    expect(find.text('Danh bạ'), findsWidgets);
    expect(find.text('Chưa có cuộc trò chuyện nào'), findsOneWidget);
    expect(find.textContaining('ĐANG TRÒ CHUYỆN'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('lists open 48h chats with the person, last message and time left', (tester) async {
    _chatWith(0, hoursLeft: 40);
    final other = _chatWith(1, hoursLeft: 10);
    MockUserStore.addMessage(matchId: other.id, senderId: MockUserStore.nearby[1].user.id, text: 'Chào bạn nhé');

    await _openContacts(tester);
    expect(find.text('ĐANG TRÒ CHUYỆN (2)'), findsOneWidget);
    expect(find.text('Mây Nhỏ'), findsOneWidget);
    expect(find.text('Nắng Mai'), findsOneWidget);
    expect(find.text('Chào bạn nhé'), findsOneWidget); // tin gần nhất
    expect(find.text('Hãy bắt đầu cuộc trò chuyện'), findsOneWidget); // chưa có tin nào
    expect(find.text('còn 40 giờ'), findsOneWidget);
    expect(find.text('còn 10 giờ'), findsOneWidget);
    // Cuộc trò chuyện sắp hết hạn thì xếp sau (mới mở, còn nhiều giờ nhất, lên trước).
    expect(tester.getTopLeft(find.text('Mây Nhỏ')).dy < tester.getTopLeft(find.text('Nắng Mai')).dy, isTrue);
    await _dispose(tester);
  });

  testWidgets('expired or cancelled chats are not listed', (tester) async {
    _chatWith(0, hoursLeft: -1); // đã hết hạn
    final cancelled = _chatWith(1);
    MockUserStore.cancelMatchResult(cancelled.id); // người dùng đã bỏ qua kết nối
    _chatWith(2, hoursLeft: 5);

    await _openContacts(tester);
    expect(find.text('ĐANG TRÒ CHUYỆN (1)'), findsOneWidget);
    expect(find.text('Gió Đông'), findsOneWidget);
    expect(find.text('Mây Nhỏ'), findsNothing);
    expect(find.text('Nắng Mai'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('tapping a chat reopens the room; back returns to the list showing the new message', (tester) async {
    final match = _chatWith(0);
    await _openContacts(tester);

    await tester.tap(find.text('Mây Nhỏ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Nhập tin nhắn...'), findsOneWidget);
    expect(find.text('CHỦ ĐỀ MỞ LỜI'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hẹn gặp lại nhé');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send')));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back)); // rời phòng, người kia chưa kịp trả lời
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ĐANG TRÒ CHUYỆN (1)'), findsOneWidget);
    expect(find.text('Hẹn gặp lại nhé'), findsOneWidget); // tin mới nhất hiện ở danh sách
    expect(MockUserStore.messagesFor(match.id), hasLength(1));
    await _dispose(tester);
  });
}
