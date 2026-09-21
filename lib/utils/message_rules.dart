/// Chat ẩn danh 48 giờ: chỉ gửi chữ; không ảnh và không liên kết.
const kMaxMessageLength = 500;

// http(s)://, www., hoặc dạng "ten.com/vn/net/…" — bắt cả link viết trần không có http.
final _linkPattern = RegExp(
  r'(https?://|www\.|\b[a-z0-9-]+\.(com|vn|net|org|io|me|co|app|xyz|info|biz|link|ly|gl)\b)',
  caseSensitive: false,
);

bool containsLink(String text) => _linkPattern.hasMatch(text);

/// Lý do tin nhắn không gửi được, hoặc null nếu hợp lệ. Tin rỗng không báo lỗi (nút gửi chỉ mờ đi).
String? outgoingMessageError(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length > kMaxMessageLength) {
    return 'Tin nhắn tối đa $kMaxMessageLength ký tự.';
  }
  if (containsLink(trimmed)) return 'Chat ẩn danh không hỗ trợ gửi liên kết.';
  return null;
}

bool canSendMessage(String text) =>
    text.trim().isNotEmpty && outgoingMessageError(text) == null;
