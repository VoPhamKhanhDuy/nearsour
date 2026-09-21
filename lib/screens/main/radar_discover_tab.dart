import 'dart:async';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/match.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/discover_radar.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';
import '../match/get_ready_screen.dart';
import 'stranger_preview_sheet.dart';

/// Tab "Radar": bật/tắt tìm người gần bạn. Thứ tự: radar → nút hành động → giải thích → bộ lọc an toàn.
class RadarDiscoverTab extends StatefulWidget {
  /// Thời gian (giả lập) từ lúc bật quét đến lúc "tìm thấy" một người.
  final Duration findDelay;

  /// Thời gian (giả lập) sau khi bật quét thì có người gửi yêu cầu kết nối đến bạn (một lần mỗi phiên).
  /// Null = tắt giả lập này.
  final Duration? incomingDelay;

  const RadarDiscoverTab({
    super.key,
    this.findDelay = const Duration(seconds: 3),
    this.incomingDelay = const Duration(seconds: 20),
  });

  @override
  State<RadarDiscoverTab> createState() => _RadarDiscoverTabState();
}

class _RadarDiscoverTabState extends State<RadarDiscoverTab> {
  /// Người gửi chỉ thấy một dòng trung tính này khi yêu cầu không thành: người kia từ chối hay im lặng đều như nhau.
  static const _noConnectionMessage =
      'Không tìm thấy kết nối lúc này, tiếp tục quét...';

  late bool _scanning = MockUserStore.currentUser?.isScanning ?? false;
  final _skipped =
      <
        String
      >{}; // những người đã bỏ qua hoặc không kết nối được trong phiên này
  bool _sheetOpen = false;
  bool _incomingShown = false;
  Timer? _findTimer;
  Timer? _incomingTimer;
  Timer? _mockResponseTimer;

  @override
  void initState() {
    super.initState();
    if (_scanning) _startTimers();
  }

  @override
  void dispose() {
    _findTimer?.cancel();
    _incomingTimer?.cancel();
    _mockResponseTimer?.cancel();
    super.dispose();
  }

  void _setScanning(bool value) {
    setState(() => _scanning = value);
    MockUserStore.currentUser?.isScanning = value;
    if (value) {
      _startTimers();
    } else {
      _findTimer?.cancel();
      _incomingTimer?.cancel();
    }
  }

  void _toggle() => _setScanning(!_scanning);

  void _startTimers() {
    _scheduleFind();
    _scheduleIncoming(widget.incomingDelay);
  }

  void _scheduleFind() {
    _findTimer?.cancel();
    _findTimer = Timer(widget.findDelay, _onFound);
  }

  void _scheduleIncoming(Duration? delay) {
    _incomingTimer?.cancel();
    if (delay == null || _incomingShown) return;
    _incomingTimer = Timer(delay, _onIncoming);
  }

  // ---- Phía người gửi: radar tìm thấy một người ----

  Future<void> _onFound() async {
    if (!mounted || !_scanning) return;
    if (_sheetOpen) {
      _scheduleFind();
      return;
    }

    final person = MockUserStore.nextNearby(skipped: _skipped);
    if (person == null) {
      // Hết người phù hợp: giữ nguyên trạng thái quét, báo nhẹ một lần.
      _snack('Chưa có ai khác phù hợp quanh bạn lúc này. Radar vẫn đang quét.');
      return;
    }

    Match? sent;
    _sheetOpen = true;
    final result = await showStrangerPreview(
      context,
      person,
      onSend: () {
        sent = MockUserStore.sendRequest(person.user.id);
        return _mockResponse(person, sent!);
      },
    );
    _sheetOpen = false;
    _mockResponseTimer?.cancel();
    if (!mounted) return;

    final name = person.user.nickname ?? 'người này';
    switch (result) {
      case SheetResult.block:
        MockUserStore.blockUser(person.user.id);
        _snack('Đã chặn $name. Họ sẽ không xuất hiện lại với bạn.');
        _scheduleFind();
      case SheetResult.accepted:
        _openGetReady(partner: person.user);
      case SheetResult.noResponse:
        // Từ chối và hết hạn xử lý HOÀN TOÀN GIỐNG NHAU: không nói ai từ chối, radar quét tiếp.
        if (sent != null) MockUserStore.expireRequest(sent!.id);
        _skipped.add(person.user.id);
        _snack(_noConnectionMessage);
        _scheduleFind();
      case SheetResult.skip || SheetResult.declined || SheetResult.expired:
        _skipped.add(person.user.id);
        _scheduleFind();
    }
  }

  /// Giả lập phản hồi của người kia theo [NearbyPerson.response]. Người im lặng thì Future không bao giờ hoàn thành
  /// (sheet tự hết hạn sau 30 giây).
  Future<bool> _mockResponse(NearbyPerson person, Match match) {
    final completer = Completer<bool>();
    if (person.response != MockResponse.ignore) {
      _mockResponseTimer = Timer(person.responseDelay, () {
        final accepted = person.response == MockResponse.accept;
        if (accepted) {
          MockUserStore.acceptRequest(match.id);
        } else {
          MockUserStore.declineRequest(match.id);
        }
        completer.complete(accepted);
      });
    }
    return completer.future;
  }

  // ---- Phía người nhận: có người gửi yêu cầu đến bạn ----

  Future<void> _onIncoming() async {
    if (!mounted || !_scanning) return;
    if (_sheetOpen) {
      // Chờ sheet đang mở đóng lại rồi thử lại.
      _scheduleIncoming(const Duration(seconds: 5));
      return;
    }
    _incomingShown = true;
    _findTimer
        ?.cancel(); // tạm dừng "tìm thấy người" trong lúc xử lý yêu cầu đến
    final person = MockUserStore.incomingRequester;
    final match = MockUserStore.receiveRequest(person.user.id);

    _sheetOpen = true;
    final result = await showIncomingRequest(context, person);
    _sheetOpen = false;
    if (!mounted) return;

    switch (result) {
      case SheetResult.accepted:
        MockUserStore.acceptRequest(match.id);
        _openGetReady(partner: person.user);
      case SheetResult.block:
        MockUserStore.declineRequest(match.id);
        MockUserStore.blockUser(person.user.id);
        _snack(
          'Đã chặn ${person.user.nickname}. Họ sẽ không xuất hiện lại với bạn.',
        );
        _scheduleFind();
      case SheetResult.expired:
        MockUserStore.expireRequest(match.id);
        _scheduleFind();
      case SheetResult.declined || SheetResult.skip || SheetResult.noResponse:
        // Từ chối: chỉ đóng sheet, không cần xác nhận gì thêm.
        MockUserStore.declineRequest(match.id);
        _scheduleFind();
    }
  }

  // ---- Chung ----

  void _openGetReady({required AppUser partner}) {
    final me = MockUserStore.currentUser;
    if (me == null) return;
    _setScanning(false);
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
