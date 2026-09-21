import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nearsoul_logo.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/radar_permission_screen.dart';
import '../profile/profile_setup_screen.dart';

enum AuthMode { register, login }

class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;

  const AuthScreen({super.key, this.initialMode = AuthMode.register});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Mỗi ô một controller riêng.
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late AuthMode _mode = widget.initialMode;
  bool _loading = false;

  // Lỗi từng ô — chỉ hiện khi màn hình chủ động set (rời ô / bấm nút), không validate lúc đang gõ.
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  bool get _isRegister => _mode == AuthMode.register;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _confirmError = null;
  }

  void _switchMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = _isRegister ? AuthMode.login : AuthMode.register;
      _clearErrors();
      _confirmCtrl.clear();
    });
  }

  // Người dùng sửa ô nào thì lỗi của ô đó biến mất.
  void _onEmailChanged(String _) {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _onPasswordChanged(String _) {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  void _onConfirmChanged(String _) {
    if (_confirmError != null) setState(() => _confirmError = null);
  }

  // Đăng ký: gõ xong (rời ô) mới báo sai định dạng; ô trống thì không báo. Đăng nhập: không kiểm tra.
  void _onEmailBlur() {
    if (!_isRegister || _emailCtrl.text.trim().isEmpty) return;
    setState(() => _emailError = Validators.email(_emailCtrl.text));
  }

  void _onPasswordBlur() {
    if (!_isRegister || _passwordCtrl.text.isEmpty) return;
    setState(() => _passwordError = Validators.password(_passwordCtrl.text));
  }

  /// Lỗi đầu tiên theo thứ tự ô, hoặc null nếu hợp lệ. Chỉ trả về MỘT lỗi để không hiện đồng loạt.
  (AuthField, String)? _firstError() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (_isRegister) {
      final emailErr = Validators.email(email);
      if (emailErr != null) return (AuthField.email, emailErr);
      final passwordErr = Validators.password(password);
      if (passwordErr != null) return (AuthField.password, passwordErr);
      if (_confirmCtrl.text.isEmpty) {
        return (AuthField.confirm, 'Vui lòng xác nhận mật khẩu');
      }
      if (_confirmCtrl.text != password) {
        return (AuthField.confirm, 'Mật khẩu xác nhận không khớp');
      }
      return null;
    }

    // Đăng nhập: chỉ kiểm tra khi bấm nút; đúng/sai tài khoản do MockUserStore quyết định.
    final emailErr = Validators.email(email);
    if (emailErr != null) return (AuthField.email, emailErr);
    if (password.isEmpty) return (AuthField.password, 'Vui lòng nhập mật khẩu');
    return null;
  }

  void _showError(AuthField field, String message) {
    _clearErrors();
    switch (field) {
      case AuthField.email:
        _emailError = message;
      case AuthField.password:
        _passwordError = message;
      case AuthField.confirm:
        _confirmError = message;
    }
  }

  void _showComingSoon(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — chưa hỗ trợ ở bản mock')));
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final firstError = _firstError();
    if (firstError != null) {
      setState(() => _showError(firstError.$1, firstError.$2));
      return;
    }

    setState(() {
      _loading = true;
      _clearErrors();
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      final email = _emailCtrl.text;
      final password = _passwordCtrl.text;
      _isRegister
          ? MockUserStore.register(email, password)
          : MockUserStore.login(email, password);
    } on AuthException catch (e) {
      setState(() {
        _loading = false;
        _showError(e.field, e.message);
      });
      return;
    }

    // Chưa có hồ sơ ẩn danh (vừa đăng ký) thì tạo hồ sơ trước; đã có hồ sơ thì vào thẳng trang kích hoạt Radar.
    final hasProfile = MockUserStore.currentUser?.nickname != null;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => hasProfile
            ? const RadarPermissionScreen()
            : const ProfileSetupScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const _Header(),
                    Expanded(child: _buildCard()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF19173A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(
          top: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _AuthForm(
        isRegister: _isRegister,
        emailCtrl: _emailCtrl,
        passwordCtrl: _passwordCtrl,
        confirmCtrl: _confirmCtrl,
        emailError: _emailError,
        passwordError: _passwordError,
        confirmError: _confirmError,
        loading: _loading,
        onEmailChanged: _onEmailChanged,
        onPasswordChanged: _onPasswordChanged,
        onConfirmChanged: _onConfirmChanged,
        onEmailBlur: _onEmailBlur,
        onPasswordBlur: _onPasswordBlur,
        onSubmit: _submit,
        onSwitchMode: _switchMode,
        onGoogle: () => _showComingSoon('Đăng nhập với Google'),
        onForgotPassword: () => _showComingSoon('Quên mật khẩu'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ),
          const NearSoulLogo(size: 65),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE2E8F0), AppColors.cyan],
            ).createShader(bounds),
            child: Text(
              'NEARSOUL',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  final bool isRegister;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final String? emailError;
  final String? passwordError;
  final String? confirmError;
  final bool loading;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmChanged;
  final VoidCallback onEmailBlur;
  final VoidCallback onPasswordBlur;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;
  final VoidCallback onGoogle;
  final VoidCallback onForgotPassword;

  const _AuthForm({
    required this.isRegister,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.emailError,
    required this.passwordError,
    required this.confirmError,
    required this.loading,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onConfirmChanged,
    required this.onEmailBlur,
    required this.onPasswordBlur,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.onGoogle,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFFCEC2D7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRegister ? 'Tạo tài khoản' : 'Đăng nhập',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        _GoogleButton(onPressed: onGoogle),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: muted.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'HOẶC',
                style: TextStyle(
                  color: muted.withValues(alpha: 0.6),
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(child: Divider(color: muted.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 16),
        AuthTextField(
          key: const ValueKey('email'),
          controller: emailCtrl,
          hint: 'Email của bạn',
          helperText: isRegister ? Validators.emailHint : null,
          errorText: emailError,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: onEmailChanged,
          onBlur: onEmailBlur,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          key: const ValueKey('password'),
          controller: passwordCtrl,
          hint: 'Mật khẩu',
          helperText: isRegister ? Validators.passwordHint : null,
          errorText: passwordError,
          icon: Icons.lock_outline,
          isPassword: true,
          textInputAction: isRegister
              ? TextInputAction.next
              : TextInputAction.done,
          onChanged: onPasswordChanged,
          onBlur: onPasswordBlur,
          onSubmitted: isRegister ? null : (_) => onSubmit(),
        ),
        if (isRegister) ...[
          const SizedBox(height: 16),
          AuthTextField(
            key: const ValueKey('confirm'),
            controller: confirmCtrl,
            hint: 'Xác nhận mật khẩu',
            errorText: confirmError,
            icon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onChanged: onConfirmChanged,
            onSubmitted: (_) => onSubmit(),
          ),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: isRegister ? 'Đăng ký ngay' : 'Đăng nhập',
          loading: loading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSwitchMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text.rich(
                TextSpan(
                  text: isRegister
                      ? 'Đã có tài khoản? '
                      : 'Chưa có tài khoản? ',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: isRegister ? 'Đăng nhập' : 'Đăng ký',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bằng việc tiếp tục, bạn đồng ý với Điều khoản và Chính sách bảo mật của NearSoul.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'G',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 12),
              Text(
                'Tiếp tục với Google',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
