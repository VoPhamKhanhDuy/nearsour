import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/match.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';

/// Vì sao đóng: đã xác thực xong ([success]), người dùng tự hủy ([cancelled]) hoặc hết 10 phút ([expired]).
/// Người gọi (phòng chat) dựa vào đây để quyết định có mở lại nút "Gặp nhau ngoài đời" hay không.
enum MeetVerifyResult { success, cancelled, expired }

/// Xác thực gặp mặt: mỗi người quét mã QR của người kia để xác nhận đang ở cùng một chỗ ngoài đời.
/// Quét chéo bắt buộc (không chỉ bấm nút xác nhận) vì đó là điều duy nhất không giả được từ xa.
///
/// Bố cục 1 trang cuộn: camera quét mã đối phương → tiến trình 2 bước → QR của mình (đổi mỗi 15 giây để
/// chống chụp màn hình gửi đi) → nút thoát. Mock: chưa kiểm tra token/khoảng cách thật, chỉ cần quét/được
/// đánh dấu là coi như hợp lệ; nút DEBUG (chỉ hiện ở kDebugMode) giả lập phía đối phương vì không có máy thứ 2.
class MeetVerifyScreen extends StatefulWidget {
  final Match match;
  final AppUser me;
  final AppUser partner;

  /// Đồng hồ và thời lượng phiên (chỉnh được để test).
  final DateTime Function() now;
  final Duration duration;

  const MeetVerifyScreen({
    super.key,
    required this.match,
    required this.me,
    required this.partner,
    this.now = DateTime.now,
    this.duration = const Duration(minutes: 10),
  });

  @override
  State<MeetVerifyScreen> createState() => _MeetVerifyScreenState();
}

class _MeetVerifyScreenState extends State<MeetVerifyScreen> {
  late final DateTime _expiresAt = widget.now().add(widget.duration);
  late final MobileScannerController _cameraController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  Timer? _ticker;

  bool _iScanned = false; // "Bạn quét mã đối phương"
  bool _partnerScanned = false; // "Đối phương quét mã bạn"
  bool _closing = false; // đã pop rồi thì không xử lý hết hạn/thêm sự kiện nữa

  Duration get _remaining => _expiresAt.difference(widget.now());
  bool get _expired => !_expiresAt.isAfter(widget.now());
  bool get _bothDone => _iScanned && _partnerScanned;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_expired && !_bothDone) _close(MeetVerifyResult.expired);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _close(MeetVerifyResult result) {
    if (_closing) return;
    _closing = true;
    _ticker?.cancel();
    Navigator.of(context).pop(result);
  }

  /// Mock: chưa kiểm tra token/khoảng cách thật — quét được mã gì (không rỗng) cũng coi là hợp lệ.
  void _handleScanResult(String raw) {
    if (_iScanned || raw.trim().isEmpty) return;
    setState(() => _iScanned = true);
    _cameraController.stop(); // đã quét xong, tắt camera cho đỡ hao pin
  }

  /// DEBUG-only: giả lập đối phương đã quét xong mình (không có máy thứ 2 để test thật).
  void _debugMarkPartnerScanned() => setState(() => _partnerScanned = true);

  /// DEBUG-only: giả lập chính mình đã quét được — camera giả của emulator không có mã QR thật để quét.
  void _debugMarkIScanned() => _handleScanResult('debug:${widget.me.id}');

  // Token đổi mỗi 15 giây theo đồng hồ chung (không phải theo lúc mở màn) để đơn giản và vẫn test được.
  int get _rotationBucket => widget.now().millisecondsSinceEpoch ~/ 1000 ~/ 15;
  int get _rotationSecondsLeft =>
      15 - (widget.now().millisecondsSinceEpoch ~/ 1000 % 15);
  String get _myToken =>
      'nearsoul:meet:${widget.match.id}:${widget.me.id}:$_rotationBucket';

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.partner.nickname ?? 'đối phương';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(MeetVerifyResult.cancelled);
      },
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                _VerifyHeader(
                  remaining: _remaining,
                  expired: _expired,
                  onBack: () => _close(MeetVerifyResult.cancelled),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        _ScanCard(
                          controller: _cameraController,
                          partnerName: partnerName,
                          done: _iScanned,
                          onDetect: _handleScanResult,
                        ),
                        const SizedBox(height: 20),
                        _ProgressCard(
                          partnerName: partnerName,
                          iScanned: _iScanned,
                          partnerScanned: _partnerScanned,
                          onDebugMarkIScanned: kDebugMode
                              ? _debugMarkIScanned
                              : null,
                          onDebugMarkPartnerScanned: kDebugMode
                              ? _debugMarkPartnerScanned
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _MyCodeCard(
                          token: _myToken,
                          refreshInSeconds: _rotationSecondsLeft,
                        ),
                        const SizedBox(height: 20),
                        _BottomButton(
                          bothDone: _bothDone,
                          onPressed: () => _close(
                            _bothDone
                                ? MeetVerifyResult.success
                                : MeetVerifyResult.cancelled,
                          ),
                        ),
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

/// Header riêng của màn này (không phải header chung NEARSOUL): back tròn, tiêu đề 2 dòng, đồng hồ đếm ngược.
class _VerifyHeader extends StatefulWidget {
  final Duration remaining;
  final bool expired;
  final VoidCallback onBack;

  const _VerifyHeader({
    required this.remaining,
    required this.expired,
    required this.onBack,
  });

  @override
  State<_VerifyHeader> createState() => _VerifyHeaderState();
}

class _VerifyHeaderState extends State<_VerifyHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
    final mm = (widget.remaining.inSeconds.clamp(0, 999) ~/ 60)
        .toString()
        .padLeft(2, '0');
    final ss = (widget.remaining.inSeconds.clamp(0, 999) % 60)
        .toString()
        .padLeft(2, '0');

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
          Material(
            color: const Color(0xFF1C1736),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onBack,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_back, color: AppColors.lilac, size: 22),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Xác thực gặp mặt',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE6DEFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Quét QR chéo trong 10 phút',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.magenta.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2546),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (widget.expired ? AppColors.error : AppColors.cyan)
                    .withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.expired ? AppColors.error : AppColors.cyan)
                      .withValues(alpha: 0.25),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: widget.expired
                      ? const AlwaysStoppedAnimation(1)
                      : _pulse,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.expired ? AppColors.error : AppColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$mm:$ss',
                  style: TextStyle(
                    color: widget.expired ? AppColors.error : AppColors.cyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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

/// Camera quét mã QR của đối phương, với khung ngắm 4 góc + tia quét chạy, và hướng dẫn tĩnh
/// (chỉ MỘT dòng trạng thái ở đây; tiến trình Bước 1/2 để [_ProgressCard] đảm nhiệm, tránh lặp).
class _ScanCard extends StatelessWidget {
  final MobileScannerController controller;
  final String partnerName;
  final bool done;
  final ValueChanged<String> onDetect;

  const _ScanCard({
    required this.controller,
    required this.partnerName,
    required this.done,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quét mã của đối phương',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                done ? Icons.check_circle : Icons.center_focus_strong,
                color: AppColors.cyan,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: const Color(0xFF0F0928)),
                  if (!done)
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        final raw = capture.barcodes.isEmpty
                            ? null
                            : capture.barcodes.first.rawValue;
                        if (raw != null) onDetect(raw);
                      },
                      // Camera không mở được (quyền bị từ chối, không có camera...): vẫn giữ layout, chỉ ẩn preview.
                      errorBuilder: (context, exception) =>
                          const SizedBox.shrink(),
                    ),
                  Center(child: _ScanReticle(done: done)),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text(
                      done
                          ? 'Đã quét được mã của $partnerName'
                          : 'Đưa mã QR của $partnerName vào khung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (done ? AppColors.cyan : const Color(0xFFCDC3D5))
                            .withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ngắm 192x192: 4 góc cyan cố định + tia quét chạy dọc khi chưa xong, dấu tích khi đã quét được.
class _ScanReticle extends StatefulWidget {
  final bool done;

  const _ScanReticle({required this.done});

  @override
  State<_ScanReticle> createState() => _ScanReticleState();
}

class _ScanReticleState extends State<_ScanReticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.done) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _ScanReticle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const RepaintBoundary(child: CustomPaint(painter: _CornerPainter())),
          if (!widget.done)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Positioned(
                top: _controller.value * 188,
                left: 4,
                right: 4,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan.withValues(alpha: 0),
                        AppColors.cyan.withValues(alpha: 0.9),
                        AppColors.cyan.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Icon(Icons.check_circle, color: AppColors.cyan, size: 40),
            ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const len = 26.0;
    final paint = Paint()
      ..color = AppColors.cyan
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    corner(Offset.zero, const Offset(len, 0), const Offset(0, len));
    corner(Offset(size.width, 0), const Offset(-len, 0), const Offset(0, len));
    corner(Offset(0, size.height), const Offset(len, 0), const Offset(0, -len));
    corner(
      Offset(size.width, size.height),
      const Offset(-len, 0),
      const Offset(0, -len),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tiến trình 2 bước: bước 1 (mình quét) luôn nổi bật cyan vì mình chủ động làm được ngay;
/// bước 2 (đối phương quét) mờ hơn vì không tự làm được — CHỈ nơi này hiện trạng thái Đang chờ/Hoàn thành.
class _ProgressCard extends StatelessWidget {
  final String partnerName;
  final bool iScanned;
  final bool partnerScanned;
  final VoidCallback? onDebugMarkIScanned;
  final VoidCallback? onDebugMarkPartnerScanned;

  const _ProgressCard({
    required this.partnerName,
    required this.iScanned,
    required this.partnerScanned,
    required this.onDebugMarkIScanned,
    required this.onDebugMarkPartnerScanned,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cả hai cần quét mã của nhau để xác nhận đã gặp ngoài đời.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFCDC3D5),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: 1,
            label: 'Bạn quét mã $partnerName',
            done: iScanned,
            emphasized: true,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: SizedBox(
              height: 16,
              child: VerticalDivider(color: Color(0x334B4453), width: 1),
            ),
          ),
          _StepRow(
            number: 2,
            label: '$partnerName quét mã bạn',
            done: partnerScanned,
            emphasized: false,
          ),
          if ((onDebugMarkIScanned != null && !iScanned) ||
              (onDebugMarkPartnerScanned != null && !partnerScanned)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (onDebugMarkIScanned != null && !iScanned)
                  _DebugButton(
                    label: 'DEBUG: giả lập bạn đã quét',
                    onPressed: onDebugMarkIScanned!,
                  ),
                if (onDebugMarkPartnerScanned != null && !partnerScanned)
                  _DebugButton(
                    label: 'DEBUG: giả lập đối phương đã quét',
                    onPressed: onDebugMarkPartnerScanned!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DebugButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.bug_report_outlined, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF59E0B),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String label;
  final bool done;

  /// Bước "trong tầm tay mình" tô cyan cả khi đang chờ; bước phụ thuộc đối phương thì mờ đến khi xong.
  final bool emphasized;

  const _StepRow({
    required this.number,
    required this.label,
    required this.done,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final active = done || emphasized;
    final tint = active ? AppColors.cyan : const Color(0xFF4B4453);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.cyan : Colors.transparent,
            border: Border.all(color: tint, width: 2),
          ),
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: tint,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          done ? 'Hoàn thành' : 'Đang chờ',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontStyle: done ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// QR của mình, đổi nội dung mỗi 15 giây để chống chụp màn hình gửi đi cho người khác thay mình quét.
class _MyCodeCard extends StatelessWidget {
  final String token;
  final int refreshInSeconds;

  const _MyCodeCard({required this.token, required this.refreshInSeconds});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mã QR của bạn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Làm mới sau 0:${refreshInSeconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: AppColors.magenta.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    // ignore: deprecated_member_use
                    data: token,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    backgroundColor: Colors.white,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0B2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.lilac.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.lilac,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Đưa mã này cho đối phương quét.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.security,
                  size: 12,
                  color: const Color(0xFFCDC3D5).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Mã QR thay đổi liên tục để chống chụp màn hình và gửi từ xa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.5),
                    fontSize: 10,
                    height: 1.3,
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

class _BottomButton extends StatelessWidget {
  final bool bothDone;
  final VoidCallback onPressed;

  const _BottomButton({required this.bothDone, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF1C1736),
        shape: StadiumBorder(
          side: BorderSide(
            color: (bothDone ? AppColors.cyan : AppColors.lilac).withValues(
              alpha: bothDone ? 0.6 : 0.2,
            ),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              bothDone ? 'Về phòng chat' : 'Hủy xác thực',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bothDone ? AppColors.cyan : const Color(0xFFCDC3D5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
