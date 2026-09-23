class AppUser {
  final String id;
  final String email;
  final String password; // MOCK ONLY — sẽ thay bằng gọi API auth thật sau này, không hash ở FE
  String? nickname;
  int? birthYear;
  String? gender;
  int? avatarId; // 1-12
  String? realName; // chỉ hiện sau khi vào danh bạ (friend)
  String? realPhotoUrl;
  String? bio;
  String? interests; // sở thích, hiện cùng bio ở màn Chỉnh sửa hồ sơ
  double? lat;
  double? lng;
  bool isOnline;
  bool isScanning; // đang bật "sẵn sàng kết nối"
  bool isHidden; // chế độ ẩn cư
  bool isAdmin; // vào thẳng NearSoul Admin thay vì luồng người dùng thường khi đăng nhập
  List<String> blockedUsers;
  List<String> friendIds;
  DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.password,
    this.nickname,
    this.birthYear,
    this.gender,
    this.avatarId,
    this.realName,
    this.realPhotoUrl,
    this.bio,
    this.interests,
    this.lat,
    this.lng,
    this.isOnline = false,
    this.isScanning = false,
    this.isHidden = false,
    this.isAdmin = false,
    List<String>? blockedUsers,
    List<String>? friendIds,
    DateTime? createdAt,
  }) : blockedUsers = blockedUsers ?? [],
       friendIds = friendIds ?? [],
       createdAt = createdAt ?? DateTime.now();
}
