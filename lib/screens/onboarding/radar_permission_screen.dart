import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/pulse_radar.dart';
import '../main/main_shell.dart';

/// Trang kích hoạt Radar: xin quyền vị trí (bắt buộc để radar tính bán kính 200m).
/// Không thuộc 3 bước tạo hồ sơ; hiện ra sau khi tạo hồ sơ xong hoặc sau khi đăng nhập.
class RadarPermissionScreen extends StatefulWidget {
  final LocationService locationService;

  const RadarPermissionScreen({
    super.key,
    this.locationService = const GeolocatorLocationService(),
  });

  @override
  State<RadarPermissionScreen> createState() => _RadarPermissionScreenState();
}

enum _Phase { idle, requesting, granted, blocked }

class _RadarPermissionScreenState extends State<RadarPermissionScreen>
    with WidgetsBindingObserver {
  static const _successPause = Duration(milliseconds: 800);

  _Phase _phase = _Phase.idle;
  LocationPermissionResult _blockedReason = LocationPermissionResult.denied;

  // Chỉ có thể bật lại trong Cài đặt của hệ thống (không xin lại được bằng hộp thoại).
  bool get _needsSettings =>
      _phase == _Phase.blocked &&
      (_blockedReason == LocationPermissionResult.deniedForever ||
          _blockedReason == LocationPermissionResult.serviceDisabled);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExisting();
  }

  // Quyền đã được cấp từ trước (ví dụ đăng nhập lại): hiện trạng thái đã kích hoạt rồi đi tiếp, không bắt bấm lại.
  Future<void> _checkExisting() async {
    try {
      final result = await widget.locationService.checkPermission();
      if (mounted &&
          result == LocationPermissionResult.granted &&
          _phase == _Phase.idle) {
        await _onGranted();
      }
    } catch (_) {
      // Không đọc được trạng thái quyền thì cứ hiện màn xin quyền như bình thường.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Người dùng bật quyền trong Cài đặt rồi quay lại app: tự nhận ra mà không cần bấm lại.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needsSettings) _recheck();
  }

  Future<void> _recheck() async {
    final result = await widget.locationService.checkPermission();
    if (!mounted || result != LocationPermissionResult.granted) return;
    await _onGranted();
  }

  Future<void> _activate() async {
    if (_phase == _Phase.requesting || _phase == _Phase.granted) return;
    setState(() => _phase = _Phase.requesting);

    final result = await widget.locationService.requestPermission();
    if (!mounted) return;

    if (result == LocationPermissionResult.granted) {
      await _onGranted();
    } else {
      setState(() {
        _phase = _Phase.blocked;
        _blockedReason = result;
      });
    }
  }

  Future<void> _onGranted() async {
    setState(() => _phase = _Phase.granted);
    await Future<void>.delayed(_successPause);
    if (mounted) _finish();
  }

  // "Không cho phép": không gọi hộp thoại hệ thống, chỉ giải thích vì sao cần quyền này.
  void _decline() {
    setState(() {
      _phase = _Phase.blocked;
      _blockedReason = LocationPermissionResult.denied;
    });
  }

  // Vào khung chính của app (tab Radar).
  void _finish() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final granted = _phase == _Phase.granted;

    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              OnboardingHeader(
                onBack: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).pop()
                    : null,
                actionLabel: 'Bỏ qua',
                onAction: _finish,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: Column(
                          children: [
                            const _RadarIllustration(),
                            const SizedBox(height: 12),
                            const _Intro(),
                            const SizedBox(height: 20),
                            const _PrivacyCard(),
                            if (_phase == _Phase.blocked) ...[
                              const SizedBox(height: 16),
                              _WarningBox(
                                reason: _blockedReason,
                                onOpenSettings: _needsSettings
                                    ? () => widget.locationService.openSettings(
                                        _blockedReason,
                                      )
                                    : null,
                              ),
                            ],
                            const Spacer(),
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: granted
                                  ? 'Đã kích hoạt Radar'
                                  : 'Kích hoạt Radar',
                              icon: granted
                                  ? Icons.check_circle_outline
                                  : Icons.radar,
                              loading: _phase == _Phase.requesting,
                              gradient: granted
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF16A34A),
                                        Color(0xFF22C55E),
                                      ],
                                    )
                                  : null,
                              onPressed: granted ? null : _activate,
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: granted || _phase == _Phase.requesting
                                  ? null
                                  : _decline,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withValues(
                                  alpha: 0.65,
                                ),
                                minimumSize: const Size(0, 40),
                              ),
                              child: const Text(
                                'Không cho phép',
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                            Text(
                              'Bạn có thể tắt quyền vị trí bất cứ lúc nào trong Cài đặt',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarIllustration extends StatelessWidget {
  const _RadarIllustration();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        PulseRadar(),
        Positioned(top: 4, right: -8, child: _ScanBadge()),
      ],
    );
  }
}

class _ScanBadge extends StatelessWidget {
  const _ScanBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.onboardingBg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radar, size: 14, color: AppColors.cyan),
          SizedBox(width: 6),
          Text(
            'Đang quét khu vực...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Kích hoạt Radar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: AppColors.magenta.withValues(alpha: 0.6),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'NearSoul cần quyền truy cập vị trí để phát hiện những người phù hợp trong bán kính 200m xung quanh bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFCDC3D5),
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ba cam kết quyền riêng tư — xử lý đúng lo ngại "theo dõi GPS" của người dùng.
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return const GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrivacyRow(icon: Icons.lock_outline, text: 'Bảo mật tuyệt đối'),
          SizedBox(height: 14),
          _PrivacyRow(
            icon: Icons.visibility_off_outlined,
            text: 'Không thấy vị trí chính xác',
          ),
          SizedBox(height: 14),
          _PrivacyRow(icon: Icons.bolt, text: 'Chỉ hoạt động khi mở app'),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivacyRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.cyan),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFC8C0E8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  final LocationPermissionResult reason;
  final VoidCallback? onOpenSettings;

  const _WarningBox({required this.reason, required this.onOpenSettings});

  String get _message => switch (reason) {
    LocationPermissionResult.serviceDisabled =>
      'Hãy bật dịch vụ vị trí (GPS) của thiết bị để dùng NearSoul',
    LocationPermissionResult.deniedForever => 'Quyền vị trí đang bị chặn. Bạn cần bật lại trong Cài đặt để dùng NearSoul',
    _ => 'Bạn cần cấp quyền vị trí để sử dụng NearSoul',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(height: 6),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFF9090),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onOpenSettings != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onOpenSettings,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Vào Cài đặt để bật',
                  style: TextStyle(
                    color: AppColors.magenta,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
