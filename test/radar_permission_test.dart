import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearsoul/mock/mock_data.dart';
import 'package:nearsoul/screens/onboarding/radar_permission_screen.dart';
import 'package:nearsoul/services/location_service.dart';
import 'package:nearsoul/theme/app_theme.dart';

typedef Result = LocationPermissionResult;

/// Bản giả: trả kết quả theo kịch bản, không gọi hộp thoại hệ thống thật.
class FakeLocationService implements LocationService {
  FakeLocationService({required this.onRequest, this.onCheck = Result.denied});

  final List<Result> onRequest;
  Result onCheck;
  int requests = 0;
  final opened = <Result>[];

  @override
  Future<Result> checkPermission() async => onCheck;

  @override
  Future<Result> requestPermission() async {
    final i = requests < onRequest.length ? requests : onRequest.length - 1;
    requests++;
    return onRequest[i];
  }

  @override
  Future<void> openSettings(Result reason) async => opened.add(reason);
}

Future<void> _open(WidgetTester tester, FakeLocationService service, {Size size = const Size(403, 1000)}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  addTearDown(tester.view.reset);

  MockUserStore.logout();
  MockUserStore.login('nearsoul.test@gmail.com', '123456');
  await tester.pumpWidget(const SizedBox()); // bỏ Navigator cũ nếu đã mở màn này trước đó
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.dark(), home: RadarPermissionScreen(locationService: service)),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

// Màn này có animation chạy liên tục nên không dùng pumpAndSettle.
Future<void> _pumpFor(WidgetTester tester, [Duration d = const Duration(seconds: 1)]) async {
  await tester.pump();
  await tester.pump(d);
}

Finder get _activate => find.text('Kích hoạt Radar').last;

void main() {
  testWidgets('shows copy, three privacy promises and both actions (no setup step bar)', (tester) async {
    await _open(tester, FakeLocationService(onRequest: [Result.granted]));

    expect(find.textContaining('Bước'), findsNothing); // không thuộc 3 bước tạo hồ sơ
    expect(find.text('Kích hoạt Radar'), findsNWidgets(2)); // tiêu đề + nút
    expect(find.text('Bảo mật tuyệt đối'), findsOneWidget);
    expect(find.text('Không thấy vị trí chính xác'), findsOneWidget);
    expect(find.text('Chỉ hoạt động khi mở app'), findsOneWidget);
    expect(find.text('Không cho phép'), findsOneWidget);
    expect(find.text('BỎ QUA'), findsOneWidget);
  });

  testWidgets('permission already granted (returning user): shows success and continues by itself', (tester) async {
    final service = FakeLocationService(onRequest: [Result.granted], onCheck: Result.granted);
    await _open(tester, service);

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Đã kích hoạt Radar'), findsOneWidget);

    await _pumpFor(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
    expect(service.requests, 0); // không hỏi lại
  });

  testWidgets('granted: shows success then goes to Home', (tester) async {
    final service = FakeLocationService(onRequest: [Result.granted]);
    await _open(tester, service);

    await tester.tap(_activate);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Đã kích hoạt Radar'), findsOneWidget);

    await _pumpFor(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
    expect(service.requests, 1);
  });

  testWidgets('denied: explains why, can retry, then succeeds', (tester) async {
    final service = FakeLocationService(onRequest: [Result.denied, Result.granted]);
    await _open(tester, service);

    await tester.tap(_activate);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    expect(find.text('Bạn cần cấp quyền vị trí để sử dụng NearSoul'), findsOneWidget);
    expect(find.text('Vào Cài đặt để bật'), findsNothing); // còn xin lại được nên không cần Cài đặt

    await tester.tap(_activate);
    await _pumpFor(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
    expect(service.requests, 2);
  });

  testWidgets('"Không cho phép" explains without showing the system dialog', (tester) async {
    final service = FakeLocationService(onRequest: [Result.granted]);
    await _open(tester, service);

    await tester.tap(find.text('Không cho phép'));
    await tester.pump();
    expect(find.text('Bạn cần cấp quyền vị trí để sử dụng NearSoul'), findsOneWidget);
    expect(service.requests, 0);
  });

  testWidgets('denied forever: offers Settings, and resuming after enabling continues', (tester) async {
    final service = FakeLocationService(onRequest: [Result.deniedForever]);
    await _open(tester, service);

    await tester.tap(_activate);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    expect(find.text('Vào Cài đặt để bật'), findsOneWidget);

    await tester.tap(find.text('Vào Cài đặt để bật'));
    await tester.pump();
    expect(service.opened, [Result.deniedForever]);

    // Người dùng bật quyền trong Cài đặt rồi quay lại app.
    service.onCheck = Result.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpFor(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });

  testWidgets('location service off: asks to turn on GPS and opens location settings', (tester) async {
    final service = FakeLocationService(onRequest: [Result.serviceDisabled]);
    await _open(tester, service);

    await tester.tap(_activate);
    await _pumpFor(tester, const Duration(milliseconds: 200));
    expect(find.textContaining('bật dịch vụ vị trí'), findsOneWidget);

    await tester.tap(find.text('Vào Cài đặt để bật'));
    await tester.pump();
    expect(service.opened, [Result.serviceDisabled]);
  });

  testWidgets('resuming without permission keeps the warning', (tester) async {
    final service = FakeLocationService(onRequest: [Result.deniedForever]);
    await _open(tester, service);
    await tester.tap(_activate);
    await _pumpFor(tester, const Duration(milliseconds: 200));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpFor(tester);
    expect(find.text('Vào Cài đặt để bật'), findsOneWidget);
    expect(find.text('Đăng nhập thành công'), findsNothing);
  });

  testWidgets('skip goes to Home without asking for permission', (tester) async {
    final service = FakeLocationService(onRequest: [Result.granted]);
    await _open(tester, service);

    await tester.tap(find.text('BỎ QUA'));
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
    expect(service.requests, 0);
  });

  testWidgets('fits a short screen without overflow', (tester) async {
    await _open(tester, FakeLocationService(onRequest: [Result.granted]), size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    expect(find.text('Không cho phép'), findsOneWidget);
  });
}
