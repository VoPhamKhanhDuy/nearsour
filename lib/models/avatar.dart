/// Avatar ẩn danh — avatarId (1-12) là vị trí trong danh sách + 1, ảnh nằm ở `assets/images/{key}.png`.
const avatarKeys = [
  'bear',
  'cat',
  'dog',
  'dragon',
  'duck',
  'eagle',
  'fox',
  'gorilla',
  'meerkat',
  'panda',
  'rabbit',
  'shark',
];

/// Đường dẫn ảnh của avatar, hoặc null nếu id không hợp lệ.
String? avatarAsset(int? avatarId) {
  if (avatarId == null || avatarId < 1 || avatarId > avatarKeys.length) return null;
  return 'assets/images/${avatarKeys[avatarId - 1]}.png';
}
