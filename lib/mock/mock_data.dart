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
    // Viết theo đúng chính tả bạn đã gõ ("gmail"), phòng khi dùng cách viết này để đăng nhập.
    AppUser(
      id: 'u3',
      email: 'phamkhanhduyvo@gmail.com',
      password: '123456',
      nickname: 'Duy Vo',
      birthYear: 2003,
      gender: 'male',
      avatarId: 2,
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
      id: 'u${_users.length + 1}',
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
}
