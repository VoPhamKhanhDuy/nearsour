import 'package:geolocator/geolocator.dart';

enum LocationPermissionResult {
  granted,

  /// Người dùng từ chối lần này; có thể xin lại.
  denied,

  /// Đã chọn "không hỏi lại"/bị chặn: chỉ bật được trong Cài đặt của hệ thống.
  deniedForever,

  /// Dịch vụ vị trí (GPS) của thiết bị đang tắt.
  serviceDisabled,
}

/// Lớp mỏng quanh quyền vị trí để màn hình không phụ thuộc trực tiếp vào plugin (dễ thay bằng bản giả khi test).
abstract class LocationService {
  /// Kiểm tra trạng thái hiện tại, KHÔNG hiện hộp thoại xin quyền.
  Future<LocationPermissionResult> checkPermission();

  /// Xin quyền vị trí khi đang dùng app; hiện hộp thoại hệ thống nếu cần.
  Future<LocationPermissionResult> requestPermission();

  /// Mở màn hình cài đặt phù hợp với lý do bị chặn.
  Future<void> openSettings(LocationPermissionResult reason);
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationPermissionResult> checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationPermissionResult.serviceDisabled;
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationPermissionResult> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationPermissionResult.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _map(permission);
  }

  @override
  Future<void> openSettings(LocationPermissionResult reason) async {
    if (reason == LocationPermissionResult.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static LocationPermissionResult _map(LocationPermission p) => switch (p) {
        LocationPermission.always || LocationPermission.whileInUse => LocationPermissionResult.granted,
        LocationPermission.deniedForever => LocationPermissionResult.deniedForever,
        LocationPermission.denied || LocationPermission.unableToDetermine => LocationPermissionResult.denied,
      };
}
