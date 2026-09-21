import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum PrimaryButtonStyle { gradient, outline }

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonStyle style;
  final bool loading;

  /// Icon đứng trước chữ (tuỳ chọn).
  final IconData? icon;

  /// Khi nút bị vô hiệu (onPressed = null): giảm độ đậm cả nút xuống ~50% thay vì đổi sang xám phẳng.
  final bool dimWhenDisabled;

  /// Thay gradient tím → cyan mặc định, ví dụ màu xanh lá cho trạng thái thành công.
  final Gradient? gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PrimaryButtonStyle.gradient,
    this.loading = false,
    this.icon,
    this.gradient,
    this.dimWhenDisabled = false,
  });

  bool get _isGradient => style == PrimaryButtonStyle.gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final button = Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _isGradient ? (gradient ?? AppColors.primaryGradient) : null,
        color: _isGradient
            ? null
            : const Color(0xFF1F1B42).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: _isGradient
            ? null
            : Border.all(color: AppColors.cyan, width: 1.5),
        boxShadow: _isGradient
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: enabled ? onPressed : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return dimWhenDisabled && onPressed == null
        ? Opacity(opacity: 0.5, child: button)
        : button;
  }
}
