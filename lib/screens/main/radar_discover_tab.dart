import 'dart:async';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/discover_radar.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';
import '../../models/user.dart';
import '../match/get_ready_screen.dart';
import 'stranger_preview_sheet.dart';

/// Tab "Radar": bật/tắt tìm người gần bạn. Thứ tự: radar → nút hành động → giải thích → bộ lọc an toàn.
class RadarDiscoverTab extends StatefulWidget {
  /// Thời gian (giả lập) từ lúc bật quét đến lúc "tìm thấy" một người.
  final Duration findDelay;

  /// Thời gian (giả lập) để người kia đồng ý sau khi bạn gửi yêu cầu kết nối.
  final Duration acceptDelay;

  const RadarDiscoverTab({
    super.key,
    this.findDelay = const Duration(seconds: 3),
    this.acceptDelay = const Duration(seconds: 2),
  });

  @override
  State<RadarDiscoverTab> createState() => _RadarDiscoverTabState();
}

class _RadarDiscoverTabState extends State<RadarDiscoverTab> {
  late bool _scanning = MockUserStore.currentUser?.isScanning ?? false;
  final _skipped = <String>{}; // những người đã bỏ qua trong phiên này
  Timer? _findTimer;
  Timer? _acceptTimer;

  @override
  void initState() {
    super.initState();
    if (_scanning) _scheduleFind();
  }

  @override
  void dispose() {
    _findTimer?.cancel();
    _acceptTimer?.cancel();
    super.dispose();
  }

  void _setScanning(bool value) {
    setState(() => _scanning = value);
    MockUserStore.currentUser?.isScanning = value;
    if (value) {
      _scheduleFind();
    } else {
      _findTimer?.cancel();
    }
  }

  void _toggle() => _setScanning(!_scanning);

  void _scheduleFind() {
    _findTimer?.cancel();
    _findTimer = Timer(widget.findDelay, _onFound);
  }

  Future<void> _onFound() async {
    if (!mounted || !_scanning) return;

    final person = MockUserStore.nextNearby(skipped: _skipped);
    if (person == null) {
      // Hết người phù hợp: giữ nguyên trạng thái quét, báo nhẹ một lần.
      _snack('Chưa có ai khác phù hợp quanh bạn lúc này. Radar vẫn đang quét.');
      return;
    }

    final action = await showStrangerPreview(context, person);
    if (!mounted) return;

    final name = person.user.nickname ?? 'người này';
    switch (action) {
      case StrangerAction.skip:
        _skipped.add(person.user.id);
        _scheduleFind();
      case StrangerAction.block:
        MockUserStore.blockUser(person.user.id);
        _snack('Đã chặn $name. Họ sẽ không xuất hiện lại với bạn.');
        _scheduleFind();
      case StrangerAction.connect:
        final match = MockUserStore.sendRequest(person.user.id);
        _setScanning(false);
        _snack('Đã gửi yêu cầu kết nối tới $name. Đang chờ họ phản hồi…');
        // Giả lập người kia đồng ý sau ít giây rồi cả hai vào Get Ready.
        _acceptTimer = Timer(
          widget.acceptDelay,
          () => _onAccepted(match.id, person.user),
        );
    }
  }

  void _onAccepted(String matchId, AppUser partner) {
    final me = MockUserStore.currentUser;
    if (!mounted || me == null) return;
    MockUserStore.acceptRequest(matchId);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GetReadyScreen(me: me, partner: partner),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Text(
            'Radar Discover',
            style: TextStyle(
              color: const Color(0xFFB8EAFF),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: AppColors.cyan.withValues(alpha: 0.8),
                  blurRadius: 16,
                ),
                Shadow(
                  color: AppColors.magenta.withValues(alpha: 0.4),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              _scanning
                  ? 'Đang quét trong bán kính 200m. NearSoul sẽ báo khi tìm thấy người phù hợp.'
                  : 'Bạn đang online. Bấm “Sẵn sàng kết nối” để bắt đầu tìm người gần bạn.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFCDC3D5),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DiscoverRadar(
            scanning: _scanning,
            avatarId: MockUserStore.currentUser?.avatarId,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _scanning ? 'Dừng tìm kiếm' : 'Sẵn sàng kết nối',
            style: _scanning
                ? PrimaryButtonStyle.outline
                : PrimaryButtonStyle.gradient,
            onPressed: _toggle,
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: Color(0xFFD1D5DB),
                ),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Hệ thống tự chọn 1 người phù hợp. Bạn không cần chọn thủ công.',
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SafetyFilters(),
        ],
      ),
    );
  }
}

class _SafetyFilters extends StatelessWidget {
  const _SafetyFilters();

  @override
  Widget build(BuildContext context) {
    return const GlowCard(
      padding: EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 18, color: AppColors.lilac),
              SizedBox(width: 8),
              Text(
                'Bộ lọc an toàn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Check('Online')),
              Expanded(child: _Check('Không bị chặn')),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Check('Dưới 200m')),
              Expanded(child: _Check('Người lạ')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final String label;

  const _Check(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.cyan),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
