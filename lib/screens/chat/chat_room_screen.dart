import 'dart:async';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/match.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../utils/message_rules.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';
import '../main/main_shell.dart';
import '../meet/meet_verify_screen.dart';
import '../meet/post_meet_decision_screen.dart';
import '../quiz/quiz_screen.dart' show kConnectionEndedMessage;

/// Phòng chat ẩn danh 48 giờ: chỉ chữ (không ảnh, không liên kết).
/// Thứ tự từ trên xuống: thông báo mở phòng → thẻ chủ đề mở lời (câu trả lời tự luận nguyên văn của hai người,
/// có khung riêng để không lẫn với tin nhắn) → tin nhắn. Hết 48 giờ thì khóa ô nhập.
class ChatRoomScreen extends StatefulWidget {
  final Match match;
  final AppUser partner;

  /// Đồng hồ (chỉnh được để test hết hạn) và thời gian người kia "đang nhập" trước khi trả lời (giả lập).
  final DateTime Function() now;
  final Duration replyDelay;

  const ChatRoomScreen({
    super.key,
    required this.match,
    required this.partner,
    this.now = DateTime.now,
    this.replyDelay = const Duration(seconds: 2),
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

enum _MenuAction { end, reportAndBlock }

const _reportReasons = [
  'Nội dung không phù hợp',
  'Quấy rối hoặc spam',
  'Hỏi thông tin cá nhân quá sớm',
  'Lý do khác',
];

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  // Ô nhập có controller riêng, sở hữu ở đây và truyền vào widget con.
  final _input = TextEditingController();

  late final AppUser _me = MockUserStore.currentUser!;
  String? _error;
  bool _partnerTyping = false;
  Timer? _ticker;
  Timer? _replyTimer;
  Timer? _meetTimer;

  DateTime get _expiresAt => widget.match.chatExpiresAt ?? widget.now();
  Duration get _remaining => _expiresAt.difference(widget.now());
  bool get _expired => !_expiresAt.isAfter(widget.now());

  @override
  void initState() {
    super.initState();
    // Đồng hồ hết hạn chạy mỗi giây; cũng là lúc ô nhập bị khóa khi hết 48 giờ.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _replyTimer?.cancel();
    _meetTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _send() {
    if (_expired) return;
    final text = _input.text;
    final error = outgoingMessageError(text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (!canSendMessage(text)) return;

    MockUserStore.addMessage(
      matchId: widget.match.id,
      senderId: _me.id,
      text: text,
      at: widget.now(),
    );
    _input.clear();
    setState(() => _error = null);
    _scheduleReply();
  }

  // Giả lập người kia trả lời sau một lúc (chỉ một lượt trả lời cho mỗi loạt tin liên tiếp).
  void _scheduleReply() {
    _replyTimer?.cancel();
    setState(() => _partnerTyping = true);
    _replyTimer = Timer(widget.replyDelay, () {
      if (!mounted) return;
      final partnerMessages = MockUserStore.messagesFor(widget.match.id)
          .where((m) => m.senderId == widget.partner.id)
          .length;
      MockUserStore.addMessage(
        matchId: widget.match.id,
        senderId: widget.partner.id,
        text: MockUserStore.partnerReply(partnerMessages),
        at: widget.now(),
      );
      setState(() => _partnerTyping = false);
    });
  }

  void _leave() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    }
  }

  /// Đóng phòng rồi về Radar: quét lại ngay, chỉ một dòng thông báo trung tính (không nói ai chủ động).
  void _closeRoomAndGoBack(String notice) {
    _replyTimer?.cancel();
    MockUserStore.cancelMatchResult(widget.match.id);
    _me.isScanning = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => MainShell(notice: notice)),
      (_) => false,
    );
  }

  void _onMenu(_MenuAction action) {
    switch (action) {
      case _MenuAction.end:
        _confirmEnd();
      case _MenuAction.reportAndBlock:
        _reportAndBlock();
    }
  }

  /// Kết thúc giữa chừng: không hoàn tác được nên luôn hỏi lại. Việc báo cho người kia cần backend.
  Future<void> _confirmEnd() async {
    final name = widget.partner.nickname ?? 'người này';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Kết thúc trò chuyện với $name?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Lịch sử chat sẽ không được lưu lại và không thể hoàn tác.',
          style: TextStyle(color: Color(0xFFCDC3D5), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _closeRoomAndGoBack(kConnectionEndedMessage);
  }

  /// Chọn lý do rồi báo cáo: người đó bị chặn và phòng đóng, để bạn không gặp lại họ.
  Future<void> _reportAndBlock() async {
    final name = widget.partner.nickname ?? 'người này';
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.fieldBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Báo cáo & chặn $name',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          for (final r in _reportReasons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(r),
              child: Text(
                r,
                style: const TextStyle(color: Color(0xFFE6DEFF), fontSize: 15),
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF968D9F), fontSize: 15),
            ),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    MockUserStore.blockUser(widget.partner.id);
    _closeRoomAndGoBack(
      'Đã gửi báo cáo. Người này sẽ không xuất hiện lại với bạn.',
    );
  }

  /// "Gặp nhau ngoài đời" là đề nghị hai chiều: bấm xong chỉ là chờ người kia, chưa lộ diện.
  /// Mock: vì chưa có backend đẩy sự kiện thật, đối phương "đồng ý" sau một lúc rồi cùng vào xác thực QR.
  void _requestMeeting() {
    if (widget.match.meetRequestedBy != null) return;
    widget.match.meetRequestedBy = _me.id;
    setState(() {});
    _meetTimer?.cancel();
    _meetTimer = Timer(const Duration(seconds: 3), _openMeetVerify);
  }

  Future<void> _openMeetVerify() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<MeetVerifyResult>(
      MaterialPageRoute<MeetVerifyResult>(
        builder: (_) => MeetVerifyScreen(
          match: widget.match,
          me: _me,
          partner: widget.partner,
        ),
      ),
    );
    if (!mounted) return;

    switch (result) {
      case MeetVerifyResult.success:
        // TODO: mở khóa gửi ảnh trong chat nếu sau này quay lại chat được (chưa làm ở bước này).
        widget.match.status = MatchStatus.metPending;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PostMeetDecisionScreen(
              match: widget.match,
              me: _me,
              partner: widget.partner,
            ),
          ),
        );
      case MeetVerifyResult.expired:
        widget.match.meetRequestedBy =
            null; // cho phép bấm "Gặp nhau ngoài đời" lại từ đầu
        setState(() {});
        _snack('Phiên xác thực gặp mặt đã hết hạn.');
      case MeetVerifyResult.cancelled:
        widget.match.meetRequestedBy = null;
        setState(() {});
      case null:
        break;
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final messages = MockUserStore.messagesFor(widget.match.id);
    final showTopic = widget.match.freeTextQuestions.isNotEmpty;
    // Từ trên xuống: [thông báo mở phòng, (thẻ chủ đề), ...tin nhắn].
    final leading = showTopic ? 2 : 1;
    final itemCount = leading + messages.length;
    final name = widget.partner.nickname ?? 'Ẩn danh';

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                _ChatHeader(
                  name: name,
                  remaining: _remaining,
                  expired: _expired,
                  onBack: _leave,
                  onMenu: _expired ? null : _onMenu,
                ),
                Expanded(
                  child: ListView.builder(
                    reverse: true, // tin mới nhất ở dưới cùng và luôn hiện sẵn
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: itemCount,
                    itemBuilder: (context, i) {
                      // reverse: chỉ số 0 là mục cuối cùng.
                      final index = itemCount - 1 - i;
                      if (index == 0) {
                        return const _SystemNote(
                          'NearSoul đã mở phòng chat 48 giờ cho hai bạn.',
                        );
                      }
                      if (showTopic && index == 1) {
                        return _TopicCard(
                          match: widget.match,
                          partnerId: widget.partner.id,
                          name: name,
                          meId: _me.id,
                        );
                      }
                      final message = messages[index - leading];
                      return _Bubble(
                        message: message,
                        mine: message.senderId == _me.id,
                      );
                    },
                  ),
                ),
                if (_partnerTyping && !_expired) _TypingBubble(name: name),
                if (_expired)
                  _ExpiredBar(onLeave: _leave)
                else
                  _Footer(
                    meetRequested: widget.match.meetRequestedBy != null,
                    onMeet: _requestMeeting,
                    input: _InputBar(
                      controller: _input,
                      error: _error,
                      canSend: canSendMessage(_input.text),
                      onChanged: () => setState(() => _error = null),
                      onSend: _send,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "HH:MM:SS" còn lại của phòng chat.
String formatRemaining(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two((total % 3600) ~/ 60)}:${two(total % 60)}';
}

/// Header của phòng chat: back, tên người kia + dòng phụ, đồng hồ 48 giờ và menu ⋮.
/// "Kết thúc trò chuyện" và "Báo cáo & Chặn" nằm trong menu, không hiện thường trực trên màn.
class _ChatHeader extends StatelessWidget {
  final String name;
  final Duration remaining;
  final bool expired;
  final VoidCallback onBack;
  final ValueChanged<_MenuAction>? onMenu;

  const _ChatHeader({
    required this.name,
    required this.remaining,
    required this.expired,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.onboardingBg.withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0x807B3FCC), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE6DEFF)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE6DEFF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                Text(
                  'Đang trò chuyện ẩn danh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _ExpiryChip(remaining: remaining, expired: expired),
          if (onMenu != null)
            PopupMenuButton<_MenuAction>(
              tooltip: 'Tùy chọn',
              icon: const Icon(Icons.more_vert, color: Color(0xFFCDC3D5)),
              color: AppColors.fieldBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: onMenu,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MenuAction.end,
                  child: Text(
                    'Kết thúc trò chuyện',
                    style: TextStyle(color: Color(0xFFE6DEFF)),
                  ),
                ),
                PopupMenuItem(
                  value: _MenuAction.reportAndBlock,
                  child: Text(
                    'Báo cáo & Chặn',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final Duration remaining;
  final bool expired;

  const _ExpiryChip({required this.remaining, required this.expired});

  @override
  Widget build(BuildContext context) {
    // Dưới 1 giờ thì chuyển màu cảnh báo (vàng cam theo token trạng thái).
    final urgent = !expired && remaining < const Duration(hours: 1);
    final color = expired
        ? AppColors.error
        : (urgent ? const Color(0xFFF59E0B) : const Color(0xFF54D5FF));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 14),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            formatRemaining(remaining),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thông báo hệ thống dạng viên thuốc ở giữa khung chat.
class _SystemNote extends StatelessWidget {
  final String text;

  const _SystemNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ ghim ngay dưới thông báo mở phòng: câu trả lời tự luận nguyên văn của hai người làm chủ đề mở lời.
class _TopicCard extends StatelessWidget {
  final Match match;
  final String partnerId;
  final String meId;
  final String name;

  const _TopicCard({
    required this.match,
    required this.partnerId,
    required this.meId,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theirs = match.freeTextAnswers[partnerId] ?? const <String>[];
    final mine = match.freeTextAnswers[meId] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlowCard(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: AppColors.cyan),
                SizedBox(width: 8),
                Text(
                  'CHỦ ĐỀ MỞ LỜI',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            for (var i = 0; i < match.freeTextQuestions.length; i++) ...[
              const SizedBox(height: 14),
              Text(
                match.freeTextQuestions[i],
                style: const TextStyle(
                  color: Color(0xFFB0A8D0),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              _Quote(
                who: name,
                text: i < theirs.length ? theirs[i] : '—',
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              _Quote(
                who: 'Bạn',
                text: i < mine.length ? mine[i] : '—',
                color: AppColors.cyan,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final String who;
  final String text;
  final Color color;

  const _Quote({required this.who, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.6), width: 2),
        ),
      ),
      child: Text(
        '$who: $text',
        style: TextStyle(color: color, fontSize: 14, height: 1.45),
      ),
    );
  }
}

/// Mọi tin nhắn đều có giờ ngay bên dưới, nên không có tin nào thiếu.
class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: mine
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7B3FCC), Color(0xFF54D5FF)],
                        )
                      : null,
                  color: mine ? null : const Color(0x66241850),
                  border: mine
                      ? null
                      : Border.all(
                          color: AppColors.lilac.withValues(alpha: 0.12),
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(mine ? 20 : 4),
                    topRight: Radius.circular(mine ? 4 : 20),
                    bottomLeft: const Radius.circular(20),
                    bottomRight: const Radius.circular(20),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: mine ? Colors.white : const Color(0xFFE6DEFF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  _time(message.createdAt),
                  style: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.5),
                    fontSize: 10,
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

/// Người kia đang nhập: ba chấm nhấp nhô trong bong bóng bên trái.
class _TypingBubble extends StatefulWidget {
  final String name;

  const _TypingBubble({required this.name});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tôn trọng "giảm chuyển động": các chấm đứng yên.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mỗi chấm lệch pha một chút, nhô lên rồi về chỗ cũ.
  double _bounce(int i) {
    final t = (_controller.value - i * 0.15) % 1;
    return t < 0.5 ? t * 2 : (1 - t) * 2;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: '${widget.name} đang nhập',
          child: ExcludeSemantics(
            child: Container(
              key: const ValueKey('typing'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x66241850),
                border: Border.all(
                  color: AppColors.lilac.withValues(alpha: 0.12),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        child: Transform.translate(
                          offset: Offset(0, -3 * _bounce(i)),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE6DEFF)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Khối dưới cùng: nút "Gặp nhau ngoài đời" (đề nghị hai chiều), ô nhập và lời nhắc an toàn.
class _Footer extends StatelessWidget {
  final bool meetRequested;
  final VoidCallback onMeet;
  final Widget input;

  const _Footer({
    required this.meetRequested,
    required this.onMeet,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.onboardingBg.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: meetRequested
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.lilac.withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Material(
              color: meetRequested
                  ? const Color(0xFF2B2546).withValues(alpha: 0.6)
                  : AppColors.purple.withValues(alpha: 0.25),
              shape: StadiumBorder(
                side: BorderSide(
                  color: meetRequested
                      ? AppColors.lilac.withValues(alpha: 0.2)
                      : AppColors.lilac.withValues(alpha: 0.7),
                  width: meetRequested ? 1 : 1.4,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: meetRequested ? null : onMeet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 11,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        meetRequested ? Icons.schedule : Icons.favorite,
                        size: meetRequested ? 14 : 16,
                        color: meetRequested
                            ? AppColors.lilac.withValues(alpha: 0.7)
                            : AppColors.lilac,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          meetRequested
                              ? 'Đã gửi yêu cầu, chờ xác nhận...'
                              : 'Gặp nhau ngoài đời',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: meetRequested
                                ? AppColors.lilac.withValues(alpha: 0.7)
                                : Colors.white,
                            fontSize: meetRequested ? 14 : 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meetRequested
                ? 'Bạn vẫn có thể tiếp tục trò chuyện trong lúc chờ.'
                : 'Khi cả hai đồng ý, hệ thống sẽ mở xác thực QR.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          input,
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool canSend;
  final VoidCallback onChanged;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.error,
    required this.canSend,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: error != null
                        ? AppColors.error
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  minLines: 1,
                  maxLines: 4,
                  maxLength: kMaxMessageLength,
                  textInputAction: TextInputAction.newline,
                  cursorColor: const Color(0xFF54D5FF),
                  style: const TextStyle(
                    color: Color(0xFFE6DEFF),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: const Color(0xFFCDC3D5).withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Gửi tin nhắn',
              child: Opacity(
                opacity: canSend ? 1 : 0.4,
                child: GestureDetector(
                  onTap: canSend ? onSend : null,
                  child: Container(
                    key: const ValueKey('send'),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF54D5FF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF54D5FF).withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Color(0xFF003544),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          error ?? 'KHÔNG CHIA SẺ THÔNG TIN CÁ NHÂN QUÁ SỚM.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: error != null
                ? AppColors.error
                : const Color(0xFFCDC3D5).withValues(alpha: 0.4),
            fontSize: error != null ? 11 : 9,
            letterSpacing: error != null ? 0 : 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ExpiredBar extends StatelessWidget {
  final VoidCallback onLeave;

  const _ExpiredBar({required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.onboardingBg.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cuộc trò chuyện đã hết hạn.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Về Radar',
            style: PrimaryButtonStyle.outline,
            onPressed: onLeave,
          ),
        ],
      ),
    );
  }
}
