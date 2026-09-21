import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Thanh trên cùng của các màn thiết lập: nút back (nếu có), logo + NEARSOUL, nút phụ bên phải (nếu có).
class OnboardingHeader extends StatelessWidget {
  static const double _sideWidth = 72;

  /// Null = ẩn nút back (ví dụ màn đầu tiên sau khi đăng ký, không có gì để quay lại).
  final VoidCallback? onBack;

  /// Nút chữ ở góc phải, ví dụ "Bỏ qua". Cần truyền cả hai tham số.
  final String? actionLabel;
  final VoidCallback? onAction;

  const OnboardingHeader({super.key, this.onBack, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.onboardingBg.withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0x807B3FCC), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _sideWidth,
            child: onBack == null
                ? null
                : Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, color: AppColors.magenta),
                    ),
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset('assets/images/logo.png', width: 24, height: 24, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NEARSOUL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _sideWidth,
            child: actionLabel == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        actionLabel!.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
