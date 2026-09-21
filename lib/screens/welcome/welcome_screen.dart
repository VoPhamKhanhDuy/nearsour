import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/nearsoul_logo.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openAuth(BuildContext context, AuthMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AuthScreen(initialMode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _BrandBlock(),
                const Spacer(flex: 5),
                PrimaryButton(
                  label: 'Tạo tài khoản',
                  onPressed: () => _openAuth(context, AuthMode.register),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Đăng nhập',
                  style: PrimaryButtonStyle.outline,
                  onPressed: () => _openAuth(context, AuthMode.login),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NearSoulLogo(),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFE2E8F0), AppColors.cyan],
          ).createShader(bounds),
          child: Text(
            'NEARSOUL',
            style: GoogleFonts.cinzel(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Đúng người. Đúng thời điểm.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tìm những kết nối thật, ngoài đời thực',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
