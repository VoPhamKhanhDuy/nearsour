import '../models/match.dart';
import '../models/user.dart';

/// Ô nhập mà lỗi auth gắn vào.
enum AuthField { email, password, confirm }

class AuthException implements Exception {
  final String message;
  final AuthField field;
  const AuthException(this.message, this.field);

  @override
  String toString() => message;
}

/// Kho user trong bộ nhớ — chỉ để giả lập auth ở giai đoạn FE, mất hết khi tắt app.
class MockUserStore {
  MockUserStore._();

  static final List<AppUser> _users = [
    AppUser(
      id: 'u1',
      email: 'nearsoul.test@gmail.com',
      password: '123456',
      nickname: 'Tester',
      birthYear: 2000,
      gender: 'male',
      avatarId: 1,
    ),
    AppUser(
      id: 'u2',
      email: 'phamkhanhduyvo@gmail.com',
      password: '123456',
      nickname: 'Duy',
      birthYear: 2003,
      gender: 'male',
      avatarId: 4,
    ),
    AppUser(
      id: 'u4',
      email: 'linh.tran@gmail.com',
      password: '123456',
      nickname: 'Linh',
      birthYear: 2002,
      gender: 'female',
      avatarId: 3,
    ),
    AppUser(
      id: 'u5',
      email: 'minh.nguyen@outlook.com',
      password: '123456',
      nickname: 'Minh',
      birthYear: 2001,
      gender: 'other',
      avatarId: 6,
    ),
    // Chưa có hồ sơ ẩn danh: đăng nhập sẽ đi qua màn "Tạo hồ sơ của bạn".
    AppUser(id: 'u6', email: 'chuacohoso@gmail.com', password: '123456'),
  ];

  static int _nextUserId = 100; // tránh trùng id với các tài khoản mẫu

  static AppUser? _current;
  static AppUser? get currentUser => _current;

  static String _normalize(String email) => email.trim().toLowerCase();

  static AppUser? findByEmail(String email) {
    final key = _normalize(email);
    for (final u in _users) {
      if (u.email == key) return u;
    }
    return null;
  }

  static AppUser login(String email, String password) {
    final user = findByEmail(email);
    if (user == null) throw const AuthException('Email không đúng', AuthField.email);
    if (user.password != password) {
      throw const AuthException('Mật khẩu không đúng', AuthField.password);
    }
    return _current = user;
  }

  static AppUser register(String email, String password) {
    if (findByEmail(email) != null) {
      throw const AuthException('Email này đã được đăng ký', AuthField.email);
    }
    final user = AppUser(
      id: 'u${_nextUserId++}',
      email: _normalize(email),
      password: password,
    );
    _users.add(user);
    return _current = user;
  }

  static void logout() => _current = null;

  /// Lưu hồ sơ ẩn danh cho user đang đăng nhập.
  static void updateProfile({
    required String nickname,
    required int birthYear,
    required String gender,
    required int avatarId,
  }) {
    final user = _current;
    if (user == null) return;
    user
      ..nickname = nickname.trim()
      ..birthYear = birthYear
      ..gender = gender
      ..avatarId = avatarId;
  }

  // ---- Radar: người ở gần (mock) ----

  /// Những người "đang online quanh bạn" mà radar có thể tìm thấy, theo thứ tự tìm thấy.
  static final List<NearbyPerson> nearby = [
    NearbyPerson(
      distanceMeters: 120,
      user: AppUser(
        id: 's1',
        email: 'may.nho@nearsoul.mock',
        password: '',
        nickname: 'Mây Nhỏ',
        birthYear: DateTime.now().year - 21,
        gender: 'female',
        avatarId: 11,
        bio: 'Thích những cuộc trò chuyện sâu sắc và những quán cà phê yên tĩnh.',
        isOnline: true,
      ),
    ),
    NearbyPerson(
      distanceMeters: 85,
      user: AppUser(
        id: 's2',
        email: 'nang.mai@nearsoul.mock',
        password: '',
        nickname: 'Nắng Mai',
        birthYear: DateTime.now().year - 24,
        gender: 'female',
        avatarId: 7,
        bio: 'Mê sách cũ, nhạc acoustic và những buổi chiều đi bộ quanh hồ.',
        isOnline: true,
      ),
    ),
    NearbyPerson(
      distanceMeters: 170,
      user: AppUser(
        id: 's3',
        email: 'gio.dong@nearsoul.mock',
        password: '',
        nickname: 'Gió Đông',
        birthYear: DateTime.now().year - 26,
        gender: 'male',
        avatarId: 5,
        bio: 'Thích khám phá quán ăn nhỏ và trò chuyện về những điều giản dị.',
        isOnline: true,
      ),
    ),
  ];

  /// Yêu cầu kết nối đã gửi trong phiên này.
  static final List<Match> matches = [];

  static const double radarRadiusMeters = 200;

  /// Người phù hợp kế tiếp theo bộ lọc an toàn: online, dưới 200m, không bị chặn, chưa bị bỏ qua.
  static NearbyPerson? nextNearby({Set<String> skipped = const {}}) {
    final blocked = _current?.blockedUsers ?? const <String>[];
    for (final p in nearby) {
      if (!p.user.isOnline || p.distanceMeters > radarRadiusMeters) continue;
      if (blocked.contains(p.user.id) || skipped.contains(p.user.id)) continue;
      return p;
    }
    return null;
  }

  static void blockUser(String userId) {
    final user = _current;
    if (user == null || user.blockedUsers.contains(userId)) return;
    user.blockedUsers.add(userId);
  }

  /// Tạo yêu cầu kết nối ở trạng thái chờ phản hồi.
  static Match sendRequest(String userId) {
    final match = Match(
      id: 'm${matches.length + 1}',
      userA: _current?.id ?? '',
      userB: userId,
      status: MatchStatus.pending,
    );
    matches.add(match);
    return match;
  }

  /// Người kia đồng ý: cặp bước vào giai đoạn Quiz (sau màn Get Ready).
  static void acceptRequest(String matchId) {
    for (final m in matches) {
      if (m.id == matchId && m.status == MatchStatus.pending) m.status = MatchStatus.quiz;
    }
  }
}

/// Một người ở gần bạn và khoảng cách tới bạn.
class NearbyPerson {
  final AppUser user;
  final int distanceMeters;

  const NearbyPerson({required this.user, required this.distanceMeters});

  int get age => DateTime.now().year - (user.birthYear ?? DateTime.now().year);
}
