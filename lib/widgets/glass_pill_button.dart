import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum GlassPillTone {
  /// Hành động phụ thông thường (ví dụ "Bỏ qua").
  neutral,

  /// Hành động mang tính chặn/phá huỷ (ví dụ "Chặn ngay", sau này "Xoá tài khoản").
  danger,
}

/// Nút phụ dạng viên thuốc, nền kính mờ. Cùng hình dạng, chỉ khác sắc thái để phân biệt rõ hành động nguy hiểm.
class GlassPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final GlassPillTone tone;

  const GlassPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = GlassPillTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final danger = tone == GlassPillTone.danger;
    final color = danger ? AppColors.error : Colors.white;

    return Material(
      color: danger ? AppColors.error.withValues(alpha: 0.08) : const Color(0xFF363051).withValues(alpha: 0.5),
      shape: StadiumBorder(
        side: BorderSide(color: danger ? AppColors.error.withValues(alpha: 0.45) : AppColors.lilac.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
