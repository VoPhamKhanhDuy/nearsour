class Validators {
  Validators._();

  static const emailHint = 'Ví dụ: tenban@gmail.com';
  static const passwordHint = 'Tối thiểu 6 ký tự';

  // Định dạng chung tên@miền.đuôi — nhận mọi nhà cung cấp (Gmail, Outlook, Yahoo...).
  static final _email = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)*\.[^@\s.]{2,}$');

  static String? email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Vui lòng nhập email';
    if (!_email.hasMatch(value)) return 'Email không đúng định dạng';
    return null;
  }

  static String? nickname(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Vui lòng nhập biệt danh';
    if (value.length < 2 || value.length > 20) return 'Biệt danh phải từ 2 đến 20 ký tự';
    return null;
  }

  static String? password(String? v) {
    if ((v ?? '').isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v!.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }
}
