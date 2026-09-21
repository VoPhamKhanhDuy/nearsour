import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ô nhập dùng cho màn Auth. Controller do màn hình sở hữu và truyền vào —
/// widget này nằm NGOÀI class màn hình để không bị tạo lại mỗi lần build.
///
/// Không tự validate: màn hình quyết định khi nào báo lỗi và truyền vào [errorText].
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? helperText; // gợi ý định dạng, hiện dưới ô khi không có lỗi
  final String? errorText; // lỗi (đỏ), thay cho helperText
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBlur; // gọi khi người dùng rời khỏi ô
  final ValueChanged<String>? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.helperText,
    this.errorText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onBlur,
    this.onSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();
  bool _obscure = true;
  bool _hadFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _hadFocus = true;
    } else if (_hadFocus) {
      _hadFocus = false;
      widget.onBlur?.call();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFFCEC2D7);
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autocorrect: false,
      enableSuggestions: !widget.isPassword,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      cursorColor: AppColors.cyan,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: const Color(0xFF333155).withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        prefixIcon: Icon(widget.icon, color: muted),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: muted,
                ),
              )
            : null,
        helperText: widget.helperText,
        helperMaxLines: 3,
        helperStyle: TextStyle(
          color: muted.withValues(alpha: 0.7),
          fontSize: 12.5,
        ),
        errorText: widget.errorText,
        errorMaxLines: 3,
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12.5),
        enabledBorder: _border(const Color(0xFF3F3B6C)),
        focusedBorder: _border(AppColors.cyan.withValues(alpha: 0.8), 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 1.5),
      ),
    );
  }
}
