import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/match.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glow_card.dart';
import '../chat/chat_room_screen.dart';

/// Tab "Danh bạ": 2 phần — "Kết nối đã lưu" (bạn đã gặp ngoài đời và giữ kết nối, vĩnh viễn) ở trên,
/// "Đang trò chuyện" (chat ẩn danh 48 giờ, tạm thời) ở dưới.
class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  Future<void> _open(Match match) async {
    final partner = MockUserStore.partnerOf(match);
    if (partner == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(match: match, partner: partner),
      ),
    );
    if (mounted) setState(() {}); // cập nhật tin nhắn mới nhất khi quay lại
  }

  // Trò chuyện với kết nối đã lưu (không giới hạn 48h) chưa có phòng chat riêng — cần làm ở bản sau.
  void _messageFriend(AppUser friend) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Trò chuyện với kết nối đã lưu sẽ có ở bản sau.'),
        ),
      );
  }

  void _showDetail(AppUser friend) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FriendDetailSheet(friend: friend),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = MockUserStore.currentUser;
    final friends = [
      for (final id in me?.friendIds ?? const <String>[])
        if (MockUserStore.userById(id) != null) MockUserStore.userById(id)!,
    ];
    final chats = MockUserStore.activeChats();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh bạ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          if (friends.isEmpty && chats.isEmpty)
            const _EmptyState()
          else ...[
            if (friends.isNotEmpty) ...[
              _SavedSummary(count: friends.length),
              const SizedBox(height: 14),
              for (final friend in friends) ...[
                _SavedFriendTile(
                  friend: friend,
                  onMessage: () => _messageFriend(friend),
                  onDetail: () => _showDetail(friend),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
            ],
            if (chats.isNotEmpty) ...[
              Text(
                'ĐANG TRÒ CHUYỆN (${chats.length})',
                style: TextStyle(
                  color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              for (final chat in chats) ...[
                _ChatTile(match: chat, onTap: () => _open(chat)),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

/// Thẻ tóm tắt đầu phần "Kết nối đã lưu".
class _SavedSummary extends StatelessWidget {
  final int count;

  const _SavedSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.verified, size: 20, color: AppColors.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count kết nối đã lưu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Những người bạn đã gặp ngoài đời và chọn giữ kết nối.',
                  style: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedFriendTile extends StatelessWidget {
  final AppUser friend;
  final VoidCallback onMessage;
  final VoidCallback onDetail;

  const _SavedFriendTile({
    required this.friend,
    required this.onMessage,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarImage(avatarId: friend.avatarId, size: 52),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan,
                        border: Border.all(
                          color: const Color(0xFF1E1455),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.nickname ?? 'Ẩn danh',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'ĐÃ XÁC THỰC',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          '• Đã gặp ngoài đời',
                          style: TextStyle(
                            color: const Color(0xFFCDC3D5)
                                .withValues(alpha: 0.6),
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Material(
                    color: AppColors.purple.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onMessage,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble,
                            size: 16,
                            color: AppColors.lilac,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Nhắn tin',
                            style: TextStyle(
                              color: AppColors.lilac,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onDetail,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lilac.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Chi tiết',
                          style: TextStyle(
                            color: AppColors.lilac,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendDetailSheet extends StatelessWidget {
  final AppUser friend;

  const _FriendDetailSheet({required this.friend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.lilac.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  AvatarImage(avatarId: friend.avatarId, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.nickname ?? 'Ẩn danh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Kết nối đã xác thực • Đã gặp ngoài đời',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if ((friend.bio ?? '').isNotEmpty) ...[
                const _DetailLabel('Bio'),
                const SizedBox(height: 4),
                Text(
                  friend.bio!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if ((friend.interests ?? '').isNotEmpty) ...[
                const _DetailLabel('Sở thích'),
                const SizedBox(height: 4),
                Text(
                  friend.interests!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if ((friend.bio ?? '').isEmpty &&
                  (friend.interests ?? '').isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    '${friend.nickname ?? "Người này"} chưa cập nhật thông tin thật.',
                    style: TextStyle(
                      color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
              Row(
                children: [
                  const Icon(Icons.lock, size: 14, color: Color(0xFF968D9F)),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Chỉ bạn xem được thông tin này — không hiển thị công khai.',
                      style: TextStyle(color: Color(0xFF968D9F), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  final String text;

  const _DetailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.lilac.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const _ChatTile({required this.match, required this.onTap});

  static String _left(Duration d) {
    if (d.inHours >= 1) return 'còn ${d.inHours} giờ';
    return 'còn ${d.inMinutes.clamp(1, 59)} phút';
  }

  @override
  Widget build(BuildContext context) {
    final partner = MockUserStore.partnerOf(match);
    final messages = MockUserStore.messagesFor(match.id);
    final last = messages.isEmpty ? null : messages.last;
    final left = match.chatExpiresAt!.difference(DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlowCard(
        padding: const EdgeInsets.all(14),
        radius: 20,
        child: Row(
          children: [
            AvatarImage(avatarId: partner?.avatarId, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner?.nickname ?? 'Ẩn danh',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    last?.text ?? 'Hãy bắt đầu cuộc trò chuyện',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFCDC3D5).withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _left(left),
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.contacts_outlined, size: 56, color: AppColors.lilac),
            SizedBox(height: 16),
            Text(
              'Chưa có cuộc trò chuyện nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Những người bạn kết nối thành công sẽ xuất hiện ở đây. Người bạn đã gặp và muốn giữ liên lạc sẽ ở lại sau đó.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCDC3D5),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
