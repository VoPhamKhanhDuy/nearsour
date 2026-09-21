import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Thanh tiến trình các bước thiết lập: thanh gradient và chữ "Bước x / y" chung một hàng.
class StepProgress extends StatelessWidget {
  final int step;
  final int total;

  const StepProgress({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    // Thanh tiến trình và "Bước x / y" chung một hàng để đỡ tốn chiều cao.
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: const Color(0xFF201B3B),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: step / total,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.magenta, AppColors.cyan]),
                    boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.5), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Bước $step / $total',
          style: const TextStyle(color: AppColors.magenta, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
