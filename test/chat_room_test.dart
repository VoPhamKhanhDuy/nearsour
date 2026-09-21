import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/mock/mock_questions.dart';
import 'package:nearsoul/models/match.dart';
import 'package:nearsoul/models/user.dart';
import 'package:nearsoul/screens/chat/chat_room_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';
import 'package:nearsoul/utils/message_rules.dart';
import 'package:nearsoul/widgets/glow_card.dart';

late AppUser _me;
late AppUser _partner;
late Match _match;
late DateTime _clock;

final _questions = [for (final q in kFreeTextBank.take(2)) q.text];
const _myTexts = ['Mình thích những buổi chiều yên tĩnh bên cửa sổ.', 'Một cuộc trò chuyện dài với người bạn cũ hôm qua.'];
final _partnerTexts = const QuizBehavior().textAnswers;

/// Tạo một match đang chat rồi mở phòng chat. Đồng hồ của phòng chat là [_clock] nên test chủ động tua được.
Future<void> _open(
  WidgetTester tester, {
  Duration lifetime = const Duration(hours: 48),
  bool withIcebreaker = true,
  bool pushed = false,
  Size size = const Size(403, 900),
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.clearHidden();
  MockUserStore.matches.clear();
  MockUserStore.messages.clear();
  _me = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456')
    ..isScanning = false
    ..blockedUsers.clear();
  _partner = MockUserStore.nearby.first.user;
  _match = MockUserStore.quizMatchWith(_partner.id);
  MockUserStore.completeQuiz(
    _match,
    userId: _me.id,
    partnerId: _partner.id,
    myAnswers: const [0, 0, 0],
    partnerAnswers: const [0, 0, 0],
    myTexts: _myTexts,
    partnerTexts: _partnerTexts,
    freeTextQuestions: withIcebreaker ? _questions : const [],
    score: 3,
    matched: true,
  );
  _clock = DateTime(2026, 9, 21, 14, 30);
  _match.chatExpiresAt = _clock.add(lifetime);

  final chat = ChatRoomScreen(match: _match, partner: _partner, now: () => _clock);

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: pushed
          ? Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => chat)),
                  child: const Text('mở chat'),
                ),
              ),
            )
          : chat,
    ),
  );
  if (pushed) {
    await tester.tap(find.text('mở chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tapSend(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('send')));
  await tester.pump();
}

/// Độ đậm của nút gửi: 1 khi gửi được, 0.4 khi đang bị vô hiệu.
double _sendOpacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.ancestor(of: find.byKey(const ValueKey('send')), matching: find.byType(Opacity)).first).opacity;

const _linkNote = 'Chat ẩn danh không hỗ trợ gửi liên kết.';

void main() {
  group('message rules', () {
    test('links are detected, plain text is not', () {
      for (final link in [
        'xem http://abc.xyz',
        'https://nearsoul.app/x',
        'www.nearsoul',
        'vào abc.com nhé',
        'liên hệ ab.vn/x',
        'TAO.NET',
      ]) {
        expect(containsLink(link), isTrue, reason: link);
      }
      for (final ok in [
        'Hôm nay trời đẹp. Bạn ăn chưa?',
        'Mình ở cách bạn 2.5km thôi',
        'v.v. và v.v.',
        'Gặp lúc 3.30 nhé',
        'ok...',
      ]) {
        expect(containsLink(ok), isFalse, reason: ok);
      }
    });

    test('errors: empty is silent, links and over-long are rejected', () {
      expect(outgoingMessageError('   '), isNull);
      expect(outgoingMessageError('xin chào'), isNull);
      expect(outgoingMessageError('vào www.abc.com'), _linkNote);
      expect(outgoingMessageError('a' * (kMaxMessageLength + 1)), isNotNull);
      expect(outgoingMessageError('a' * kMaxMessageLength), isNull);
    });

    test('canSend requires real text', () {
      expect(canSendMessage(''), isFalse);
      expect(canSendMessage('  \n '), isFalse);
      expect(canSendMessage('hi'), isTrue);
      expect(canSendMessage('http://x.com'), isFalse);
    });
  });

  testWidgets('shows header, partner, 48h countdown, the topic card, and a text-only input', (tester) async {
    await _open(tester);

    expect(find.text('Mây Nhỏ'), findsOneWidget);
    expect(find.text('Đang trò chuyện ẩn danh'), findsOneWidget);
    expect(find.text('48:00:00'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    // "Báo cáo & Chặn" không hiện thường trực trên màn, chỉ nằm trong menu ⋮.
    expect(find.text('Báo cáo & Chặn'), findsNothing);

    // Tin nhắn hệ thống đầu cuộc trò chuyện: câu tự luận của hai người.
    expect(find.text('CHỦ ĐỀ MỞ LỜI'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      expect(find.text(_questions[i]), findsOneWidget);
      expect(find.text('Mây Nhỏ: ${_partnerTexts[i]}'), findsOneWidget);
      expect(find.text('Bạn: ${_myTexts[i]}'), findsOneWidget);
    }

    expect(find.text('Nhập tin nhắn...'), findsOneWidget);
    expect(find.text('KHÔNG CHIA SẺ THÔNG TIN CÁ NHÂN QUÁ SỚM.'), findsOneWidget);
    expect(find.text('Gặp nhau ngoài đời'), findsOneWidget);
    expect(find.text('Khi cả hai đồng ý, hệ thống sẽ mở xác thực QR.'), findsOneWidget);
    for (final icon in [Icons.attach_file, Icons.image, Icons.photo, Icons.photo_camera, Icons.add_photo_alternate, Icons.insert_link]) {
      expect(find.byIcon(icon), findsNothing, reason: '$icon');
    }
    expect(_sendOpacity(tester), 0.4); // chưa gõ gì thì chưa gửi được
    await _dispose(tester);
  });

  testWidgets('without free-text answers there is no icebreaker card', (tester) async {
    await _open(tester, withIcebreaker: false);
    expect(find.text('CHỦ ĐỀ MỞ LỜI'), findsNothing);
    expect(find.text('Nhập tin nhắn...'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('order: room-opened note first, then the topic card in its own frame, then the messages', (tester) async {
    await _open(tester);
    MockUserStore.addMessage(matchId: _match.id, senderId: _me.id, text: 'tin đầu tiên', at: DateTime(2026, 9, 21, 14, 31));
    await tester.pump(const Duration(seconds: 1));

    final note = tester.getTopLeft(find.text('NearSoul đã mở phòng chat 48 giờ cho hai bạn.')).dy;
    final card = tester.getTopLeft(find.text('CHỦ ĐỀ MỞ LỜI')).dy;
    final first = tester.getTopLeft(find.text('tin đầu tiên')).dy;
    expect(note < card, isTrue);
    expect(card < first, isTrue);

    // Thẻ có khung riêng (GlowCard) bọc cả tiêu đề lẫn câu hỏi, không phải chữ trôi nổi.
    for (final text in ['CHỦ ĐỀ MỞ LỜI', _questions.first]) {
      expect(find.ancestor(of: find.text(text), matching: find.byType(GlowCard)), findsOneWidget, reason: text);
    }
    expect(find.ancestor(of: find.text('tin đầu tiên'), matching: find.byType(GlowCard)), findsNothing);
    await _dispose(tester);
  });

  testWidgets('every message has its time, including the last one', (tester) async {
    await _open(tester);
    final t = DateTime(2026, 9, 21, 14, 31);
    MockUserStore.addMessage(matchId: _match.id, senderId: _me.id, text: 'một', at: t);
    MockUserStore.addMessage(matchId: _match.id, senderId: _partner.id, text: 'hai', at: t.add(const Duration(minutes: 1)));
    MockUserStore.addMessage(matchId: _match.id, senderId: _me.id, text: 'ba', at: t.add(const Duration(minutes: 2)));
    MockUserStore.addMessage(matchId: _match.id, senderId: _partner.id, text: 'Ừ, nghe ổn đó.', at: t.add(const Duration(minutes: 3)));
    await tester.pump(const Duration(seconds: 1));

    for (final time in ['14:31', '14:32', '14:33', '14:34']) {
      expect(find.text(time), findsOneWidget, reason: time);
    }
    // Giờ của tin cuối hiện đầy đủ phía trên ô nhập, không bị che.
    expect(tester.getBottomLeft(find.text('14:34')).dy < tester.getTopLeft(find.text('Nhập tin nhắn...')).dy, isTrue);
    await _dispose(tester);
  });

  group('meet in real life', () {
    testWidgets('is a two-way request: after tapping it waits for the other person', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Gặp nhau ngoài đời'));
      await tester.pump();

      expect(find.text('Đã gửi yêu cầu, chờ xác nhận...'), findsOneWidget);
      expect(find.text('Gặp nhau ngoài đời'), findsNothing);
      expect(_match.meetRequestedBy, _me.id);
      expect(_match.status, MatchStatus.chatting); // chưa lộ diện
      expect(find.text('Nhập tin nhắn...'), findsOneWidget); // vẫn chat được
      await _dispose(tester);
    });
  });

  group('menu ⋮', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('has "Kết thúc trò chuyện" and "Báo cáo & Chặn"', (tester) async {
      await _open(tester);
      await openMenu(tester);
      expect(find.text('Kết thúc trò chuyện'), findsOneWidget);
      expect(find.text('Báo cáo & Chặn'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('ending asks first; "Ở lại" changes nothing, confirming closes the room and goes back to the radar', (tester) async {
      await _open(tester);
      MockUserStore.addMessage(matchId: _match.id, senderId: _me.id, text: 'tin cũ', at: _clock);
      await openMenu(tester);
      await tester.tap(find.text('Kết thúc trò chuyện'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kết thúc trò chuyện với Mây Nhỏ?'), findsOneWidget);
      expect(find.text('Lịch sử chat sẽ không được lưu lại và không thể hoàn tác.'), findsOneWidget);

      await tester.tap(find.text('Ở lại'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nhập tin nhắn...'), findsOneWidget);
      expect(_match.status, MatchStatus.chatting);

      await openMenu(tester);
      await tester.tap(find.text('Kết thúc trò chuyện'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Kết thúc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Radar Discover'), findsOneWidget);
      expect(find.text('Kết nối đã kết thúc, tiếp tục quét...'), findsOneWidget); // trung tính, không nói ai chủ động
      expect(_match.status, MatchStatus.expired);
      expect(MockUserStore.messagesFor(_match.id), isEmpty);
      expect(MockUserStore.activeChats(), isEmpty);
      expect(_me.isScanning, isTrue);
      await _dispose(tester);
    });

    testWidgets('report & block: pick a reason, the person is blocked and the room closes; cancel changes nothing', (tester) async {
      await _open(tester);
      await openMenu(tester);
      await tester.tap(find.text('Báo cáo & Chặn'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Hủy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_me.blockedUsers, isEmpty);
      expect(_match.status, MatchStatus.chatting);

      await openMenu(tester);
      await tester.tap(find.text('Báo cáo & Chặn'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Quấy rối hoặc spam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Radar Discover'), findsOneWidget);
      expect(_me.blockedUsers, contains(_partner.id));
      expect(_match.status, MatchStatus.expired);
      await _dispose(tester);
    });
  });

  testWidgets('sending shows my bubble on the right, clears the input, stores it, and the other person replies', (tester) async {
    await _open(tester);
    await _type(tester, '  Xin chào bạn  ');
    expect(_sendOpacity(tester), 1);

    await _tapSend(tester);
    expect(find.text('Xin chào bạn'), findsOneWidget); // đã bỏ khoảng trắng thừa
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(_sendOpacity(tester), 0.4);

    final bubble = tester.getTopRight(find.text('Xin chào bạn'));
    expect(bubble.dx > 200, isTrue); // tin của mình nằm bên phải

    final sent = MockUserStore.messagesFor(_match.id).single;
    expect(sent.senderId, _me.id);
    expect(sent.text, 'Xin chào bạn');

    // Người kia đang nhập rồi trả lời sau 2 giây.
    expect(find.byKey(const ValueKey('typing')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('typing')), findsNothing);
    expect(find.text(MockUserStore.partnerReply(0)), findsOneWidget);
    expect(tester.getTopLeft(find.text(MockUserStore.partnerReply(0))).dx < 200, isTrue); // và nằm bên trái

    final thread = MockUserStore.messagesFor(_match.id);
    expect(thread.map((m) => m.senderId), [_me.id, _partner.id]);
    await _dispose(tester);
  });

  testWidgets('several messages in a row get a single reply, and replies move through the script', (tester) async {
    await _open(tester);
    for (final t in ['một', 'hai', 'ba']) {
      await _type(tester, t);
      await _tapSend(tester);
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(seconds: 3));
    expect(MockUserStore.messagesFor(_match.id).where((m) => m.senderId == _partner.id), hasLength(1));

    await _type(tester, 'bốn');
    await _tapSend(tester);
    await tester.pump(const Duration(seconds: 3));
    final replies = MockUserStore.messagesFor(_match.id).where((m) => m.senderId == _partner.id).map((m) => m.text).toList();
    expect(replies, [MockUserStore.partnerReply(0), MockUserStore.partnerReply(1)]);
    await _dispose(tester);
  });

  testWidgets('whitespace-only text cannot be sent', (tester) async {
    await _open(tester);
    await _type(tester, '   \n  ');
    expect(_sendOpacity(tester), 0.4);
    await _tapSend(tester);
    expect(MockUserStore.messagesFor(_match.id), isEmpty);
    await _dispose(tester);
  });

  testWidgets('links are refused with a clear note, the text stays, and typing again clears the note', (tester) async {
    await _open(tester);

    for (final link in ['xem http://abc.xyz', 'www.abc', 'vào abc.com nhé']) {
      await _type(tester, link);
      // Nút vẫn mờ vì tin không hợp lệ; gọi thẳng nút gửi để chắc chắn tin không lọt qua.
      expect(_sendOpacity(tester), 0.4, reason: link);
      await _tapSend(tester);
      expect(MockUserStore.messagesFor(_match.id), isEmpty, reason: link);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, link);
    }

    await _type(tester, 'Hôm nay trời đẹp. Bạn ăn chưa?');
    expect(find.text(_linkNote), findsNothing);
    expect(_sendOpacity(tester), 1);
    await _tapSend(tester);
    expect(MockUserStore.messagesFor(_match.id), hasLength(1));
    await _dispose(tester);
  });

  testWidgets('the input is capped at 500 characters', (tester) async {
    await _open(tester);
    await _type(tester, 'a' * 600);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text.length, lessThanOrEqualTo(kMaxMessageLength));
    await _dispose(tester);
  });

  testWidgets('reopening the room restores the conversation in order', (tester) async {
    await _open(tester);
    MockUserStore.addMessage(matchId: _match.id, senderId: _me.id, text: 'tin thứ nhất', at: DateTime(2026, 9, 21, 14, 31));
    MockUserStore.addMessage(matchId: _match.id, senderId: _partner.id, text: 'tin thứ hai', at: DateTime(2026, 9, 21, 14, 32));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: ChatRoomScreen(match: _match, partner: _partner, now: () => _clock)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('tin thứ nhất'), findsOneWidget);
    expect(find.text('tin thứ hai'), findsOneWidget);
    expect(tester.getTopLeft(find.text('tin thứ nhất')).dy < tester.getTopLeft(find.text('tin thứ hai')).dy, isTrue);
    expect(find.text('14:31'), findsOneWidget);
    expect(find.text('14:32'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('the countdown ticks down and the room locks when the 48 hours are over', (tester) async {
    await _open(tester, lifetime: const Duration(seconds: 3));
    expect(find.text('00:00:03'), findsOneWidget);
    expect(find.text('Nhập tin nhắn...'), findsOneWidget);

    _clock = _clock.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:02'), findsOneWidget);

    _clock = _clock.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Cuộc trò chuyện đã hết hạn.'), findsOneWidget);
    expect(find.text('Nhập tin nhắn...'), findsNothing); // không còn ô nhập, không gửi thêm được
    expect(find.byKey(const ValueKey('send')), findsNothing);
    await _dispose(tester);
  });

  testWidgets('an expired room goes back to the radar', (tester) async {
    await _open(tester, lifetime: const Duration(seconds: 1));
    _clock = _clock.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Về Radar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Radar Discover'), findsOneWidget);
    await _dispose(tester);
  });

  group('leaving', () {
    testWidgets('opened on top of another screen, back returns to it', (tester) async {
      await _open(tester, pushed: true);
      expect(find.text('Nhập tin nhắn...'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('mở chat'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('opened as the only screen (after the result), back goes to the radar instead of quitting the app', (tester) async {
      await _open(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Radar Discover'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('the system back button does the same', (tester) async {
      await _open(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Radar Discover'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('leaving before the other person answers cancels the pending reply', (tester) async {
      await _open(tester);
      await _type(tester, 'chào');
      await _tapSend(tester);
      await _dispose(tester); // rời phòng ngay khi người kia còn đang "nhập"

      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
      expect(MockUserStore.messagesFor(_match.id), hasLength(1)); // chưa có lời đáp nào bị thêm sau khi rời
    });
  });

  testWidgets('fits a short screen and wraps long messages', (tester) async {
    await _open(tester, size: const Size(360, 640));
    await _type(tester, 'Một tin nhắn khá dài để kiểm tra việc xuống dòng trong bong bóng chat mà không bị tràn ra ngoài màn hình nhỏ.');
    await _tapSend(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('send')), findsOneWidget);
    await _dispose(tester);
  });
}
