import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/match.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glow_card.dart';
import '../chat/chat_room_screen.dart';

/// Tab "Danh bạ": các cuộc trò chuyện 48 giờ đang mở để vào lại. Danh bạ vĩnh viễn (giữ kết nối sau khi gặp)
/// sẽ làm sau khi có luồng gặp mặt.
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

  @override
  Widget build(BuildContext context) {
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
          if (chats.isEmpty)
            const _EmptyState()
          else ...[
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
