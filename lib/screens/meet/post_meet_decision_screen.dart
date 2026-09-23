import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';
import 'connection_ended_screen.dart';
import 'connection_saved_screen.dart';

const _moods = ['Thoải mái', 'Có thiện cảm', 'Muốn trò chuyện tiếp'];

/// Sau khi xác thực gặp mặt xong: hỏi có muốn giữ kết nối lâu dài không.
/// "Giữ kết nối" là quyết định hai chiều (giống "Gặp nhau ngoài đời"): chỉ khi cả hai cùng chọn giữ mới
/// thêm nhau vào Danh bạ vĩnh viễn. "Không tiếp tục" thì một phía bấm là kết thúc ngay, không cần chờ.
///
/// Tên/ảnh thật của đối phương CHƯA hiện ở màn này — theo đúng quy ước trong model ("realName chỉ hiện sau
/// khi vào danh bạ"): vẫn dùng nickname + avatar hoạt hình như lúc chat ẩn danh, chỉ khác là có huy hiệu
/// "đã xác thực gặp mặt".
class PostMeetDecisionScreen extends StatefulWidget {
  final Match match;
  final AppUser me;
  final AppUser partner;

  /// Thời gian giả lập đối phương cũng chọn "Giữ kết nối" (chưa có backend đẩy sự kiện thật).
  final Duration mockPartnerDelay;

  const PostMeetDecisionScreen({
    super.key,
    required this.match,
    required this.me,
    required this.partner,
    this.mockPartnerDelay = const Duration(seconds: 3),
  });

  @override
  State<PostMeetDecisionScreen> createState() => _PostMeetDecisionScreenState();
}

class _PostMeetDecisionScreenState extends State<PostMeetDecisionScreen> {
  // Chỉ để người dùng tự ghi chú cảm nhận cho vui, không gửi đi đâu hay ảnh hưởng quyết định.
  final _selectedMoods = <String>{};
  bool _waitingForPartner = false;
  Timer? _mockTimer;

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }

  void _toggleMood(String mood) {
    setState(() {
      if (!_selectedMoods.remove(mood)) _selectedMoods.add(mood);
    });
  }

  /// Hai chiều: bấm xong chờ đối phương. Mock: đối phương cũng chọn giữ sau một lúc rồi mới vào Danh bạ.
  void _keepConnection() {
    if (widget.match.keepRequestedBy != null) return;
    widget.match.keepRequestedBy = widget.me.id;
    setState(() => _waitingForPartner = true);
    _mockTimer = Timer(widget.mockPartnerDelay, () {
      if (!mounted) return;
      widget.match.status = MatchStatus.completedSaved;
      if (!widget.me.friendIds.contains(widget.partner.id)) {
        widget.me.friendIds.add(widget.partner.id);
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConnectionSavedScreen(partner: widget.partner),
        ),
      );
    });
  }

  /// Một phía không muốn tiếp tục là đủ để kết thúc, không cần chờ đối phương đồng ý.
  void _endConnection() {
    widget.match
      ..status = MatchStatus.completedEnded
      ..chatExpiresAt = null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConnectionEndedScreen(partner: widget.partner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.partner.nickname ?? 'Ẩn danh';

    return PopScope(
      // Đang chờ đối phương xác nhận giữ kết nối thì không thoát ngang chừng, giống lúc chờ Get Ready.
      canPop: !_waitingForPartner,
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        _SuccessHero(name: name),
                        const SizedBox(height: 24),
                        _ProfileCard(partner: widget.partner),
                        const SizedBox(height: 20),
                        _MoodCard(
                          selected: _selectedMoods,
                          onToggle: _toggleMood,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: _waitingForPartner
                              ? 'Đang chờ $name xác nhận...'
                              : 'Giữ kết nối',
                          icon: _waitingForPartner
                              ? Icons.hourglass_top
                              : Icons.favorite,
                          onPressed: _waitingForPartner
                              ? null
                              : _keepConnection,
                          dimWhenDisabled: true,
                        ),
                        if (!_waitingForPartner) ...[
                          const SizedBox(height: 12),
                          _OutlineButton(
                            label: 'Không tiếp tục',
                            onPressed: _endConnection,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _FooterNotes(name: name),
                      ],
                    ),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(color: AppColors.lilac.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back, color: AppColors.lilac),
            ),
          ),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sau buổi gặp',
                  style: TextStyle(
                    color: AppColors.lilac,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Quyết định kết nối',
                  style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 40,
          ), // cân với nút back để tiêu đề nằm giữa thật
        ],
      ),
    );
  }
}

/// Vòng tròn ✓ phát sáng + huy hiệu "Đã xác thực gặp mặt" chờm góc dưới phải.
class _SuccessHero extends StatefulWidget {
  final String name;

  const _SuccessHero({required this.name});

  @override
  State<_SuccessHero> createState() => _SuccessHeroState();
}

class _SuccessHeroState extends State<_SuccessHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(
                        alpha: 0.15 + 0.1 * _pulse.value,
                      ),
                      blurRadius: 24 + 10 * _pulse.value,
                    ),
                  ],
                ),
                child: child,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 40,
              ),
            ),
            Positioned(
              bottom: -6,
              right: -28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lilac,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lilac.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFF440088)),
                    SizedBox(width: 4),
                    Text(
                      'Đã xác thực gặp mặt',
                      style: TextStyle(
                        color: Color(0xFF440088),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Bạn muốn tiếp tục kết nối?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cuộc gặp đã được xác thực. Hãy chọn cách bạn muốn tiếp tục với ${widget.name}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AppUser partner;

  const _ProfileCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Row(
        children: [
          AvatarImage(avatarId: partner.avatarId, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.nickname ?? 'Ẩn danh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.lilac,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.handshake,
                      size: 14,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Kết nối đã xác thực • Đã gặp',
                        style: TextStyle(
                          color: Color(0xFFCDC3D5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MoodCard({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Column(
        children: [
          Text(
            'Bạn cảm thấy thế nào sau buổi gặp?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.9),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MoodChip(
                  label: _moods[0],
                  selected: selected.contains(_moods[0]),
                  onTap: () => onToggle(_moods[0]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoodChip(
                  label: _moods[1],
                  selected: selected.contains(_moods[1]),
                  onTap: () => onToggle(_moods[1]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: _MoodChip(
              label: _moods[2],
              selected: selected.contains(_moods[2]),
              onTap: () => onToggle(_moods[2]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.lilac
          : AppColors.lilac.withValues(alpha: 0.05),
      shape: StadiumBorder(
        side: BorderSide(
          color: AppColors.lilac.withValues(alpha: selected ? 1 : 0.3),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF440088) : AppColors.lilac,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        shape: StadiumBorder(
          side: BorderSide(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFCDC3D5).withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterNotes extends StatelessWidget {
  final String name;

  const _FooterNotes({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Note(
          icon: Icons.info_outline,
          color: AppColors.lilac,
          text:
              'Nếu cả hai cùng chọn giữ kết nối, $name sẽ được thêm vào Danh bạ của bạn.',
        ),
        const SizedBox(height: 12),
        const _Note(
          icon: Icons.security,
          color: AppColors.error,
          text: 'Bạn luôn có thể chặn hoặc báo cáo nếu cảm thấy không an toàn.',
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Note({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
