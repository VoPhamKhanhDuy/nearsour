import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/screens/match/get_ready_screen.dart';
import 'package:nearsoul/theme/app_theme.dart';

void main() {
  testWidgets('real path: Get Ready → Quiz with default arguments, does the countdown tick?', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(403 * 3, 900 * 3);
    addTearDown(tester.view.reset);

    MockUserStore.logout();
    MockUserStore.matches.clear();
    final me = MockUserStore.login('phamkhanhduyvo@gmail.com', '123456');
    final partner = MockUserStore.nearby.first.user;

    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: GetReadyScreen(me: me, partner: partner)));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1)); // giữ "Bắt đầu!" rồi tự vào Quiz
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Câu 1/5'), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);

    final seen = <String>[];
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      seen.add(tester.widget<Text>(find.textContaining(RegExp(r'^\d\d:\d\d$'))).data!);
    }
    // ignore: avoid_print
    print('countdown seen on the real path: $seen, exception: ${tester.takeException()}');
    expect(seen, ['00:14', '00:13', '00:12', '00:11', '00:10']);

    await tester.pumpWidget(const SizedBox());
  });
}
