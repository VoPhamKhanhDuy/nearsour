import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/mock/mock_questions.dart';
import 'package:nearsoul/models/match.dart';
import 'package:nearsoul/models/user.dart';
import 'package:nearsoul/screens/quiz/quiz_screen.dart' show kConnectionEndedMessage;
import 'package:nearsoul/screens/result/match_result_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';
import 'package:nearsoul/utils/quiz_scoring.dart';

late AppUser _me;
late AppUser _partner;
late Match _match;

final _freeTextQuestions = [for (final q in kFreeTextBank.take(2)) q.text];
const _myTexts = ['Mình thích những buổi chiều yên tĩnh bên cửa sổ.', 'Một cuộc trò chuyện dài với người bạn cũ hôm qua.'];
final _partnerTexts = const QuizBehavior().textAnswers;

/// Mở màn kết quả như sau một Quiz khớp: [mine] là đáp án của bạn, người kia chọn [0, 0, 0].
Future<void> _open(
  WidgetTester tester, {
  List<int> mine = const [0, 0, 1],
  Size size = const Size(403, 900),
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  MockUserStore.logout();
  MockUserStore.clearHidden();
  MockUserStore.matches.clear();
  MockUserStore.messages.clear();
  _me = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456')..isScanning = false;
  _partner = MockUserStore.nearby.first.user;
  _match = MockUserStore.quizMatchWith(_partner.id);

  const partnerAnswers = [0, 0, 0];
  MockUserStore.completeQuiz(
    _match,
    userId: _me.id,
    partnerId: _partner.id,
    myAnswers: mine,
    partnerAnswers: partnerAnswers,
    myTexts: _myTexts,
    partnerTexts: _partnerTexts,
    freeTextQuestions: _freeTextQuestions,
    score: countMatchingAnswers(mine, partnerAnswers),
    matched: true,
  );

  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MatchResultScreen(match: _match, me: _me, partner: _partner),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _settleAnimation(WidgetTester tester) => tester.pump(const Duration(milliseconds: 1600));

/// Bấm nút xác nhận trong hộp thoại (chữ giống nút bên dưới nên lọc theo AlertDialog).
Future<void> _confirmInDialog(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Bỏ qua kết nối')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('shows the result: header, title, percent, chat-opened card, their answers, privacy note, actions', (tester) async {
    await _open(tester);
    await _settleAnimation(tester);

    expect(find.text('NEARSOUL'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/logo.png'),
      findsOneWidget,
    );
    expect(find.text('Đã kết nối'), findsOneWidget);
    expect(find.text('Kết nối thành công'), findsOneWidget);
    expect(find.text('AI đã tìm thấy điểm chung phù hợp trong câu trả lời của hai bạn.'), findsOneWidget);

    expect(find.text('67%'), findsOneWidget); // 2 trên 3 câu trùng
    expect(find.text('MỨC ĐỘ PHÙ HỢP'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    expect(find.text('Phòng chat 48 giờ đã được mở'), findsOneWidget);
    expect(find.text('Bạn có thể trò chuyện ẩn danh trước khi quyết định gặp ngoài đời.'), findsOneWidget);
    expect(find.text('Thông tin cá nhân vẫn được bảo vệ cho đến khi cả hai xác thực gặp mặt.'), findsOneWidget);

    expect(find.text('Mở phòng chat'), findsOneWidget);
    expect(find.text('Bỏ qua kết nối này'), findsOneWidget);
    expect(find.text('Quay lại Radar'), findsNothing); // đã đổi tên: nút này bỏ qua người vừa khớp
    expect(find.text('Cuộc trò chuyện sẽ tự động hết hạn sau 48 giờ.'), findsOneWidget);
    for (final leaked in ['check_circle', 'forum', 'chat_bubble', 'lock', 'arrow_back']) {
      expect(find.text(leaked), findsNothing, reason: leaked);
    }
    await _dispose(tester);
  });

  testWidgets('shows the other person\'s free-text answers verbatim (no summarising chips)', (tester) async {
    await _open(tester);
    await _settleAnimation(tester);

    expect(find.text('CÂU TRẢ LỜI CỦA MÂY NHỎ'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      expect(find.text(_freeTextQuestions[i]), findsOneWidget);
      expect(find.text('“${_partnerTexts[i]}”'), findsOneWidget); // nguyên văn, trong dấu trích dẫn
    }
    // Không hiện câu trả lời của chính mình, và không còn các chip "chủ đề gợi mở" tóm tắt.
    expect(find.textContaining(_myTexts.first), findsNothing);
    expect(find.text('CHỦ ĐỀ GỢI MỞ'), findsNothing);
    for (final q in kMultipleChoiceBank.take(3)) {
      for (final option in q.options!) {
        expect(find.text(option), findsNothing, reason: option);
      }
    }
    await _dispose(tester);
  });

  testWidgets('the percent counts up from 0 to the result (finite animation)', (tester) async {
    await _open(tester);
    int shown() {
      final text = tester.widget<Text>(find.textContaining(RegExp(r'^\d+%$'))).data!;
      return int.parse(text.replaceAll('%', ''));
    }

    final start = shown(); // vừa bắt đầu chạy, còn xa kết quả
    expect(start, lessThan(50));

    await tester.pump(const Duration(milliseconds: 500));
    final midway = shown();
    expect(midway, greaterThan(start));
    expect(midway, lessThan(67));
    await _settleAnimation(tester);
    expect(find.text('67%'), findsOneWidget);
    await tester.pumpAndSettle(); // không còn animation nào chạy mãi
    await _dispose(tester);
  });

  testWidgets('reduced motion shows the final result straight away', (tester) async {
    await _open(tester, reduceMotion: true);
    expect(find.text('67%'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('3 of 3 shows 100%', (tester) async {
    await _open(tester, mine: [0, 0, 0]);
    await _settleAnimation(tester);
    expect(find.text('100%'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('"Mở phòng chat" opens the real chat room (with an input) and keeps the match open for 48h', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Mở phòng chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Nhập tin nhắn...'), findsOneWidget); // có ô nhập, không phải màn cụt chỉ có nút thoát
    expect(find.byKey(const ValueKey('send')), findsOneWidget);
    expect(find.text('CHỦ ĐỀ MỞ LỜI'), findsOneWidget);
    expect(_match.status, MatchStatus.chatting);
    expect(_match.chatExpiresAt!.difference(DateTime.now()).inHours, inInclusiveRange(47, 48));
    expect(_match.freeTextAnswers[_me.id], _myTexts);
    await _dispose(tester);
  });

  group('"Bỏ qua kết nối này" cancels the result', () {
    testWidgets('asks first; "Ở lại" changes nothing', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Bỏ qua kết nối này'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bỏ qua kết nối này?'), findsOneWidget);
      expect(find.text('Phòng chat sẽ không được mở và đáp án của bạn không được lưu lại.'), findsOneWidget);

      await tester.tap(find.text('Ở lại'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bỏ qua kết nối này?'), findsNothing);
      expect(find.text('Kết nối thành công'), findsOneWidget);
      expect(_match.status, MatchStatus.chatting);
      expect(_match.chatExpiresAt, isNotNull);
      await _dispose(tester);
    });

    testWidgets('confirming cancels the match, discards everything, and goes back to a scanning radar', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Bỏ qua kết nối này'));
      await tester.pump(const Duration(milliseconds: 300));
      await _confirmInDialog(tester);

      expect(find.text('Radar Discover'), findsOneWidget);
      expect(find.text(kConnectionEndedMessage), findsOneWidget);
      // Chỉ một dòng trung tính: không nói ai bỏ qua ai.
      expect(find.textContaining('từ chối'), findsNothing);
      expect(find.textContaining('bỏ qua'), findsNothing);

      expect(_match.status, MatchStatus.expired);
      expect(_match.chatExpiresAt, isNull); // phòng chat không mở
      expect(_match.quizScore, 0);
      expect(_match.quizAnswers, isEmpty);
      expect(_match.freeTextAnswers, isEmpty); // câu tự luận không được giữ lại
      expect(_match.freeTextQuestions, isEmpty);
      expect(_me.isScanning, isTrue);
      expect(MockUserStore.activeChats(), isEmpty); // và không còn ở danh sách chat
      await _dispose(tester);
    });

    testWidgets('the back arrow and the system back button ask the same question', (tester) async {
      await _open(tester);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bỏ qua kết nối này?'), findsOneWidget);
      await tester.tap(find.text('Ở lại'));
      await tester.pump(const Duration(milliseconds: 300));

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bỏ qua kết nối này?'), findsOneWidget);
      expect(_match.status, MatchStatus.chatting); // chưa hủy khi chưa xác nhận
      await _dispose(tester);
    });
  });

  testWidgets('fits a short screen: content scrolls, both actions stay visible', (tester) async {
    await _open(tester, size: const Size(360, 640));
    await _settleAnimation(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Mở phòng chat'), findsOneWidget);
    expect(find.text('Bỏ qua kết nối này'), findsOneWidget);
    await _dispose(tester);
  });
}
