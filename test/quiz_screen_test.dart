import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/mock/mock_questions.dart';
import 'package:nearsoul/models/match.dart';
import 'package:nearsoul/models/user.dart';
import 'package:nearsoul/screens/quiz/quiz_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';
import 'package:nearsoul/utils/quiz_scoring.dart';
import 'package:nearsoul/widgets/primary_button.dart';

final _questions = [
  ...kMultipleChoiceBank.take(3),
  ...kFreeTextBank.take(2),
];

late AppUser _me;
late AppUser _partner;
late Match _match;

const _text1 = 'Mình thích những buổi chiều yên tĩnh bên cửa sổ.';
const _text2 = 'Một cuộc trò chuyện dài với người bạn cũ hôm qua.';

Future<void> _open(
  WidgetTester tester, {
  QuizBehavior partner = const QuizBehavior(),
  Size size = const Size(403, 900),
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.clearHidden();
  MockUserStore.matches.clear();
  _me = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456')
    ..isScanning = false
    ..blockedUsers.clear();
  _partner = MockUserStore.nearby.first.user;
  _match = MockUserStore.quizMatchWith(_partner.id);

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: QuizScreen(
        match: _match,
        me: _me,
        partner: _partner,
        questions: _questions,
        partnerBehavior: partner,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Gỡ cây widget để huỷ mọi timer/animation còn chạy khi kết thúc test.
Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.text('Gửi câu trả lời'));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _answerChoice(WidgetTester tester, int option) async {
  await tester.tap(find.byKey(ValueKey('option_$option')));
  await tester.pump();
  await _send(tester);
}

Future<void> _answerText(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await _send(tester);
}

/// Trả lời đủ 5 câu: 3 trắc nghiệm theo [choices] rồi 2 tự luận.
Future<void> _answerAll(WidgetTester tester, List<int> choices) async {
  for (final c in choices) {
    await _answerChoice(tester, c);
  }
  await _answerText(tester, _text1);
  await _answerText(tester, _text2);
}

VoidCallback? _sendCallback(WidgetTester tester) => tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed;

/// Chờ [seconds] giây rồi thêm một chút cho màn chuyển trang xong.
Future<void> _wait(WidgetTester tester, int seconds) async {
  await tester.pump(Duration(seconds: seconds));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('shows the quiz layout with real icons, no leaked icon names', (tester) async {
    await _open(tester);

    expect(find.text('NEARSOUL'), findsOneWidget);
    expect(find.text('Hủy kết nối'), findsOneWidget);
    expect(find.text('AI Quiz'), findsOneWidget);
    expect(find.text('Câu 1/5'), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);
    expect(find.text(_questions.first.text), findsOneWidget);
    expect(find.text('Hết giờ, hệ thống tự khóa đáp án và chuyển câu tiếp theo.'), findsOneWidget);
    expect(find.text('Đáp án của bạn sẽ được ẩn cho đến khi cả hai hoàn thành.'), findsOneWidget);
    expect(find.text('AI chỉ dùng câu trả lời để gợi mở cuộc trò chuyện phù hợp.'), findsOneWidget);

    // Icon thật, không phải tên icon hiện thành chữ ("arrow_back", "check_circle", "schedule").
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    for (final leaked in ['arrow_back', 'row_back', 'check_circle', 'schedule']) {
      expect(find.text(leaked), findsNothing, reason: leaked);
    }

    // Trắc nghiệm chỉ có 2 đáp án; chưa chọn thì nút gửi đang mờ.
    expect(find.byKey(const ValueKey('option_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('option_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('option_2')), findsNothing);
    expect(_sendCallback(tester), isNull);
    await _dispose(tester);
  });

  testWidgets('picking an answer shows a check icon and enables sending; changing the pick keeps a single tick', (tester) async {
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('option_1')));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(_sendCallback(tester), isNotNull);

    await tester.tap(find.byKey(const ValueKey('option_0')));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('each question has its own countdown; sending moves on and resets it', (tester) async {
    await _open(tester);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:12'), findsOneWidget);

    await _answerChoice(tester, 0);
    expect(find.text('Câu 2/5'), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);
    expect(find.text(_questions[1].text), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('the timer turns urgent in the last seconds and auto-locks + moves on at zero', (tester) async {
    await _open(tester);

    await tester.pump(const Duration(seconds: 11));
    expect(find.text('00:04'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, isNot(const Color(0xFF00CFFF)));

    await tester.pump(const Duration(seconds: 4)); // hết giờ, chưa chọn gì
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Câu 2/5'), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('free-text questions: 45 seconds, at least 20 characters to send, counter shown', (tester) async {
    await _open(tester);
    for (var i = 0; i < 3; i++) {
      await _answerChoice(tester, 0);
    }

    expect(find.text('Câu 4/5'), findsOneWidget);
    expect(find.text('00:45'), findsOneWidget);
    expect(find.text('Nhập câu trả lời của bạn...'), findsOneWidget);
    expect(find.text('Câu trả lời sẽ được ẩn cho đến khi cả hai hoàn thành.'), findsOneWidget);
    expect(find.text('0/300'), findsOneWidget);
    expect(_sendCallback(tester), isNull);

    await tester.enterText(find.byType(TextField), 'a' * 19);
    await tester.pump();
    expect(_sendCallback(tester), isNull);
    expect(find.text('Cần thêm 1 ký tự để gửi (tối thiểu 20).'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '${'a' * 19}        '); // khoảng trắng không được tính
    await tester.pump();
    expect(_sendCallback(tester), isNull);

    await tester.enterText(find.byType(TextField), 'a' * 20);
    await tester.pump();
    expect(_sendCallback(tester), isNotNull);
    expect(find.text('20/300'), findsOneWidget);
    expect(find.text('Đã đủ độ dài, bạn có thể gửi.'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('a free-text question opens empty and the box is cleared for the next one', (tester) async {
    await _open(tester);
    for (var i = 0; i < 3; i++) {
      await _answerChoice(tester, 0);
    }
    await _answerText(tester, _text1);

    expect(find.text('Câu 5/5'), findsOneWidget);
    expect(find.text(_questions[4].text), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    await _dispose(tester);
  });

  group('outcomes', () {
    testWidgets('>= 2 of 3 answers agree: waits for the other person, then shows the result and opens chat with both free-text answers', (tester) async {
      await _open(tester);
      await _answerAll(tester, [0, 0, 1]); // người kia chọn [0, 0, 0] → trùng 2/3

      expect(find.text('Đang chờ đối phương hoàn thành...'), findsOneWidget);
      expect(find.text('Gửi câu trả lời'), findsNothing);
      expect(_match.status, MatchStatus.quiz);

      await _wait(tester, 46); // người kia xong lúc giây thứ 45

      // Báo kết quả trước; chỉ khi bấm "Mở phòng chat" mới vào phòng chat.
      expect(find.text('Kết nối thành công'), findsOneWidget);
      expect(find.text('CHỦ ĐỀ MỞ LỜI'), findsNothing); // chưa vào phòng chat
      expect(find.textContaining(const QuizBehavior().textAnswers.first), findsOneWidget); // câu trả lời của người kia hiện ở đây
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('67%'), findsOneWidget);
      await tester.tap(find.text('Mở phòng chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Phòng chat thật: có ô nhập, và đầu chat là tin nhắn hệ thống nhắc lại các câu tự luận làm chủ đề mở lời.
      expect(find.text('Nhập tin nhắn...'), findsOneWidget);
      expect(find.text('CHỦ ĐỀ MỞ LỜI'), findsOneWidget);
      expect(find.textContaining('Mây Nhỏ: ${const QuizBehavior().textAnswers.first}'), findsOneWidget);
      expect(find.textContaining('Bạn: $_text1'), findsOneWidget);
      expect(_match.status, MatchStatus.chatting);
      expect(_match.quizScore, 2);
      expect(_match.quizAnswers, {_me.id: [0, 0, 1], _partner.id: [0, 0, 0]});
      expect(_match.freeTextAnswers[_me.id], [_text1, _text2]);
      final until = _match.chatExpiresAt!.difference(DateTime.now());
      expect(until.inHours, inInclusiveRange(47, 48)); // chat mở 48 giờ
      await _dispose(tester);
    });

    testWidgets('all 3 agree shows 100% and also allows opening chat', (tester) async {
      await _open(tester);
      await _answerAll(tester, [0, 0, 0]);
      await _wait(tester, 46);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('100%'), findsOneWidget);
      await tester.tap(find.text('Mở phòng chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Nhập tin nhắn...'), findsOneWidget);
      expect(_match.status, MatchStatus.chatting);
      await _dispose(tester);
    });

    testWidgets('fewer than 2 agree: no chat, neutral message, hidden from each other for 24h, free text discarded', (tester) async {
      await _open(tester);
      await _answerAll(tester, [1, 1, 0]); // trùng 1/3
      await _wait(tester, 46);

      expect(find.text('Radar Discover'), findsOneWidget);
      expect(find.text(kConnectionEndedMessage), findsOneWidget);
      expect(find.text('Kết nối thành công'), findsNothing);
      expect(find.textContaining(const QuizBehavior().textAnswers.first), findsNothing); // câu tự luận không lộ ra

      expect(_match.status, MatchStatus.rejected);
      expect(_match.quizScore, 1);
      expect(_match.chatExpiresAt, isNull);
      expect(_match.freeTextAnswers, isEmpty);
      expect(_match.hiddenUntil!.difference(DateTime.now()).inHours, inInclusiveRange(23, 24));
      expect(MockUserStore.isHiddenFromRadar(_partner.id), isTrue);
      expect(MockUserStore.nextNearby()!.user.id, isNot(_partner.id)); // radar không hiện lại họ
      expect(_me.isScanning, isTrue); // "tiếp tục quét..."
      await _dispose(tester);
    });

    testWidgets('running out of time on every question counts as no agreement', (tester) async {
      await _open(tester);
      // 3 câu × 15s + 2 câu × 45s = 135s, không trả lời câu nào; người kia đã xong từ giây 45.
      await _wait(tester, 136);

      expect(find.text(kConnectionEndedMessage), findsOneWidget);
      expect(_match.status, MatchStatus.rejected);
      expect(_match.quizScore, 0);
      expect(_match.quizAnswers[_me.id], [-1, -1, -1]);
      await _dispose(tester);
    });
  });

  group('ending early', () {
    testWidgets('cancel asks first; "Ở lại" keeps the quiz going', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Hủy kết nối'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hủy kết nối?'), findsOneWidget);

      await tester.tap(find.text('Ở lại'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hủy kết nối?'), findsNothing);
      expect(find.text('Câu 1/5'), findsOneWidget);
      expect(_match.status, MatchStatus.quiz);
      await _dispose(tester);
    });

    testWidgets('cancelling ends the session: match expired, answers not kept, neutral message, radar keeps scanning', (tester) async {
      await _open(tester);
      await _answerChoice(tester, 0); // đã có một đáp án dở dang

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Hủy kết nối')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Radar Discover'), findsOneWidget);
      expect(find.text(kConnectionEndedMessage), findsOneWidget);
      expect(_match.status, MatchStatus.expired);
      expect(_match.quizAnswers, isEmpty);
      expect(_match.freeTextAnswers, isEmpty);
      expect(_me.isScanning, isTrue);
      await _dispose(tester);
    });

    testWidgets('the system back button asks the same question instead of leaving', (tester) async {
      await _open(tester);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hủy kết nối?'), findsOneWidget);
      await _dispose(tester);
    });

    testWidgets('the other person leaving ends the session with the same neutral message (no reason given)', (tester) async {
      await _open(tester, partner: const QuizBehavior(finishAfter: null, leaveAfter: Duration(seconds: 20)));
      await _answerChoice(tester, 0);

      await _wait(tester, 21);
      expect(find.text('Radar Discover'), findsOneWidget);
      expect(find.text(kConnectionEndedMessage), findsOneWidget);
      expect(find.textContaining('rời'), findsNothing);
      expect(find.textContaining('thoát'), findsNothing);
      expect(find.textContaining('hết giờ'), findsNothing);
      expect(_match.status, MatchStatus.expired);
      expect(_match.quizAnswers, isEmpty);
      await _dispose(tester);
    });

    testWidgets('the whole session is capped at 5 minutes even if the other person never finishes', (tester) async {
      await _open(tester, partner: const QuizBehavior(finishAfter: null));
      await _answerAll(tester, [0, 0, 0]);
      expect(find.text('Đang chờ đối phương hoàn thành...'), findsOneWidget);

      await tester.pump(const Duration(minutes: 4, seconds: 50));
      expect(find.text('Đang chờ đối phương hoàn thành...'), findsOneWidget); // chưa tới 5 phút

      await _wait(tester, 15);
      expect(find.text(kConnectionEndedMessage), findsOneWidget);
      expect(_match.status, MatchStatus.expired);
      expect(MockUserStore.matches.length, 1);
      await _dispose(tester);
    });
  });

  group('per-question countdown', () {
    test('15s for multiple choice, 45s for free text, well inside the 5-minute session cap', () {
      expect(kMultipleChoiceTime, const Duration(seconds: 15));
      expect(kFreeTextTime, const Duration(seconds: 45));
      final worstCase = kMultipleChoiceTime * kMultipleChoiceCount + kFreeTextTime * kFreeTextCount;
      expect(worstCase, const Duration(seconds: 135));
      expect(worstCase < MockUserStore.quizSessionLimit, isTrue);
    });

    testWidgets('really ticks down every second, it is not a static number', (tester) async {
      await _open(tester);

      final seen = <String>[];
      for (var s = 0; s < 6; s++) {
        seen.add(tester.widget<Text>(find.textContaining(RegExp(r'^\d\d:\d\d$'))).data!);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(seen, ['00:15', '00:14', '00:13', '00:12', '00:11', '00:10']);
      await _dispose(tester);
    });

    testWidgets('resets to the new question\'s own time and never carries time over', (tester) async {
      await _open(tester);

      await tester.pump(const Duration(seconds: 9)); // dùng 9 giây của câu 1
      await _answerChoice(tester, 0);
      expect(find.text('Câu 2/5'), findsOneWidget);
      expect(find.text('00:15'), findsOneWidget); // đúng 15s, không phải 15 + 6

      await _answerChoice(tester, 0);
      await _answerChoice(tester, 0);
      expect(find.text('Câu 4/5'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);

      await tester.pump(const Duration(seconds: 20)); // dùng 20 giây của câu 4
      await _answerText(tester, _text1);
      expect(find.text('Câu 5/5'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget); // đúng 45s, không cộng dồn
      await _dispose(tester);
    });

    testWidgets('free text out of time keeps what was typed (even when under 20 characters) and moves on', (tester) async {
      await _open(tester);
      for (var i = 0; i < 3; i++) {
        await _answerChoice(tester, 0);
      }
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(_sendCallback(tester), isNull); // chưa đủ 20 ký tự nên chưa gửi tay được

      await tester.pump(const Duration(seconds: 45));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Câu 5/5'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);

      await _answerText(tester, _text2);
      await _wait(tester, 46); // người kia xong lúc giây 45; hai người trùng 3/3
      expect(_match.freeTextAnswers[_me.id], ['abc', _text2]);
      await _dispose(tester);
    });

    testWidgets('leaving the quiz cancels the timer: nothing changes afterwards', (tester) async {
      await _open(tester);
      await _answerChoice(tester, 0);
      await tester.pump(const Duration(seconds: 5));

      await _dispose(tester); // thoát màn Quiz giữa chừng (dispose)
      await tester.pump(const Duration(minutes: 6)); // đủ để mọi timer sót lại (nếu có) bắn ra

      expect(tester.takeException(), isNull);
      expect(_match.status, MatchStatus.quiz); // không tự hết hạn, không bị chấm điểm sau khi đã thoát
      expect(_match.quizAnswers, isEmpty);
    });
  });

  testWidgets('fits a short screen', (tester) async {
    await _open(tester, size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    expect(find.text('Gửi câu trả lời'), findsOneWidget);

    // Màn thấp: nội dung cuộn được, nút gửi cố định ở đáy luôn thấy.
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.byKey(const ValueKey('option_0')));
      await tester.pump();
      await _answerChoice(tester, 0);
    }
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Gửi câu trả lời'), findsOneWidget);
    await _dispose(tester);
  });
}
