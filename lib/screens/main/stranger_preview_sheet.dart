import 'dart:ui';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glass_pill_button.dart';
import '../../widgets/primary_button.dart';

enum StrangerAction { skip, block, connect }

/// Hiện thông tin sơ lược của người radar vừa tìm thấy trên nền mờ tối của màn Radar.
/// Trả về hành động người dùng chọn; đóng bằng chạm ra ngoài / vuốt / nút back được coi là [StrangerAction.skip].
Future<StrangerAction> showStrangerPreview(BuildContext context, NearbyPerson person) async {
  final result = await showGeneralDialog<StrangerAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng',
    barrierColor: Colors.transparent, // nền mờ và tối do chính sheet vẽ để có hiệu ứng blur
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, _, _) => _StrangerPreviewSheet(person: person),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? StrangerAction.skip;
}

class _StrangerPreviewSheet extends StatelessWidget {
  final NearbyPerson person;

  const _StrangerPreviewSheet({required this.person});

  void _close(BuildContext context, StrangerAction action) => Navigator.of(context).pop(action);

  @override
  Widget build(BuildContext context) {
    final user = person.user;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Nền: mờ 10px + phủ tối 60%; chạm ra ngoài thì đóng.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _close(context, StrangerAction.skip),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(color: AppColors.onboardingBg.withValues(alpha: 0.6)),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      decoration: BoxDecoration(
                        color: const Color(0xEB1C1736),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.45), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppColors.cyan.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, -10)),
                          BoxShadow(color: AppColors.magenta.withValues(alpha: 0.25), blurRadius: 24),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B4453).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 20),
                          _RingAvatar(avatarId: user.avatarId),
                          const SizedBox(height: 14),
                          Text(
                            user.nickname ?? 'Người lạ',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFE6DEFF), fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${person.age} tuổi · ${person.distanceMeters}m',
                            style: TextStyle(color: const Color(0xFFCDC3D5).withValues(alpha: 0.85), fontSize: 15),
                          ),
                          if (user.bio != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              user.bio!,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFFE6DEFF), fontSize: 15, height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: GlassPillButton(
                                  label: 'Bỏ qua',
                                  icon: Icons.close,
                                  onPressed: () => _close(context, StrangerAction.skip),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GlassPillButton(
                                  label: 'Chặn ngay',
                                  icon: Icons.block,
                                  tone: GlassPillTone.danger,
                                  onPressed: () => _close(context, StrangerAction.block),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PrimaryButton(
                            label: 'Gửi yêu cầu kết nối',
                            icon: Icons.send,
                            onPressed: () => _close(context, StrangerAction.connect),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(Icons.security, size: 14, color: const Color(0xFFCDC3D5).withValues(alpha: 0.7)),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Thông tin thật chỉ mở khi cả hai xác thực gặp mặt ngoài đời.',
                                  style: TextStyle(color: const Color(0xFFCDC3D5).withValues(alpha: 0.75), fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar có vòng gradient cyan → magenta phát sáng (cùng motif vòng tròn glow của các màn trước).
class _RingAvatar extends StatelessWidget {
  final int? avatarId;

  const _RingAvatar({required this.avatarId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [AppColors.cyan, AppColors.magenta]),
        boxShadow: [
          BoxShadow(color: AppColors.cyan.withValues(alpha: 0.4), blurRadius: 20),
          BoxShadow(color: AppColors.magenta.withValues(alpha: 0.35), blurRadius: 24),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.onboardingBg),
        child: AvatarImage(avatarId: avatarId, size: 80),
      ),
    );
  }
}
