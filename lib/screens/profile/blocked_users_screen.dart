import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';

/// Danh sách những người đã chặn — bỏ chặn được tại đây (blockUser được gọi ở nhiều nơi trong app
/// nhưng trước giờ chưa có chỗ xem lại/undo).
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  void _unblock(AppUser user) {
    MockUserStore.unblockUser(user.id);
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Đã bỏ chặn ${user.nickname ?? "người này"}.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final blockedIds = MockUserStore.currentUser?.blockedUsers ?? const [];
    final blocked = [
      for (final id in blockedIds)
        if (MockUserStore.userById(id) != null) MockUserStore.userById(id)!,
    ];

    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: blocked.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: blocked.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _BlockedTile(
                          user: blocked[i],
                          onUnblock: () => _unblock(blocked[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 24, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE6DEFF)),
          ),
          const SizedBox(width: 4),
          const Text(
            'Danh sách chặn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onUnblock;

  const _BlockedTile({required this.user, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Row(
        children: [
          Opacity(
            opacity: 0.6,
            child: AvatarImage(avatarId: user.avatarId, size: 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              user.nickname ?? 'Ẩn danh',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onUnblock,
            style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
            child: const Text('Bỏ chặn'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 48,
              color: AppColors.lilac.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa chặn ai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Những người bạn chặn sẽ không xuất hiện lại trên Radar và hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
