import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/glass_pill_button.dart';
import '../../widgets/primary_button.dart';

/// Kết quả người dùng chọn trên sheet.
///
/// Phía người gửi chỉ có [skip], [block], [accepted], [noResponse]: người kia từ chối hay im lặng đều là
/// [noResponse] (không từ chối công khai). Phía người nhận có [accepted], [declined], [block], [expired].
enum SheetResult { skip, block, accepted, noResponse, declined, expired }

/// Người gửi: hiện thông tin người radar vừa tìm thấy. Bấm "Gửi yêu cầu kết nối" thì sheet ở lại và chờ tối đa
/// [timeout] (đếm ngược trên nút) cho tới khi [onSend] trả về `true` (đồng ý) hoặc `false` (người kia không nhận).
/// [onSend] có thể không bao giờ hoàn thành — khi đó hết hạn sẽ là [SheetResult.noResponse].
Future<SheetResult> showStrangerPreview(
  BuildContext context,
  NearbyPerson person, {
  required Future<bool> Function() onSend,
  Duration timeout = MockUserStore.requestTimeout,
}) {
  return _show(
    context,
    _PersonSheet(
      person: person,
      incoming: false,
      onSend: onSend,
      timeout: timeout,
    ),
  );
}

/// Người nhận: có người gửi yêu cầu kết nối đến. Phải chọn Chấp nhận / Từ chối / Chặn ngay, hoặc hết hạn sau [timeout].
Future<SheetResult> showIncomingRequest(
  BuildContext context,
  NearbyPerson person, {
  Duration timeout = MockUserStore.requestTimeout,
}) {
  return _show(
    context,
    _PersonSheet(person: person, incoming: true, timeout: timeout),
  );
}

Future<SheetResult> _show(BuildContext context, Widget sheet) async {
  final result = await showGeneralDialog<SheetResult>(
    context: context,
    barrierDismissible:
        false, // nền mờ do sheet tự xử lý chạm để có thể chặn khi đang chờ
    barrierLabel: 'Đóng',
    barrierColor: Colors
        .transparent, // nền mờ và tối do chính sheet vẽ để có hiệu ứng blur
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, _, _) => sheet,
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
  // Đóng bằng nút back hệ thống: người gửi coi như bỏ qua; người nhận không bao giờ tới đây (sheet chặn back).
  return result ?? SheetResult.skip;
}

class _PersonSheet extends StatefulWidget {
  final NearbyPerson person;
  final bool incoming;
  final Future<bool> Function()? onSend;
  final Duration timeout;

  const _PersonSheet({
    required this.person,
    required this.incoming,
    this.onSend,
    required this.timeout,
  });

  @override
  State<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<_PersonSheet> {
  Timer? _ticker;
  bool _waiting = false; // người gửi đã bấm gửi và đang chờ phản hồi
  bool _done = false;
  int _remaining = 0;

  bool get _counting => _waiting || widget.incoming;

  @override
  void initState() {
    super.initState();
    // Người nhận: đồng hồ hết hạn chạy ngay khi sheet hiện.
    if (widget.incoming) _startCountdown(SheetResult.expired);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCountdown(SheetResult onZero) {
    _remaining = widget.timeout.inSeconds;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _finish(onZero);
    });
  }

  void _finish(SheetResult result) {
    if (_done || !mounted) return;
    _done = true;
    _ticker?.cancel();
    Navigator.of(context).pop(result);
  }

  Future<void> _send() async {
    if (_waiting) return;
    setState(() => _waiting = true);
    _startCountdown(SheetResult.noResponse);

    final accepted = await widget.onSend!();
    _finish(accepted ? SheetResult.accepted : SheetResult.noResponse);
  }

  // Chạm ra ngoài: người gửi = bỏ qua (trừ khi đang chờ); người nhận phải chọn rõ ràng nên không đóng được.
  void _onBackdropTap() {
    if (widget.incoming || _waiting) return;
    _finish(SheetResult.skip);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final user = person.user;
    final incoming = widget.incoming;
    final name = user.nickname ?? 'Người lạ';

    return PopScope(
      canPop: !_counting,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Nền: mờ 10px + phủ tối 60%.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBackdropTap,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: ColoredBox(
                    color: AppColors.onboardingBg.withValues(alpha: 0.6),
                  ),
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
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.15),
                              blurRadius: 40,
                              offset: const Offset(0, -10),
                            ),
                            BoxShadow(
                              color: AppColors.magenta.withValues(alpha: 0.25),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4B4453)
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              incoming
                                  ? '${name.toUpperCase()} MUỐN KẾT NỐI VỚI BẠN'
                                  : 'TÌM THẤY 1 NGƯỜI PHÙ HỢP GẦN BẠN',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _RingAvatar(avatarId: user.avatarId),
                            const SizedBox(height: 14),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE6DEFF),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${person.age} tuổi · ${person.distanceMeters}m',
                              style: TextStyle(
                                color: const Color(0xFFCDC3D5)
                                    .withValues(alpha: 0.85),
                                fontSize: 15,
                              ),
                            ),
                            if (user.bio != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                user.bio!,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE6DEFF),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: GlassPillButton(
                                    label: incoming ? 'Từ chối' : 'Bỏ qua',
                                    icon: Icons.close,
                                    onPressed: _waiting
                                        ? null
                                        : () => _finish(
                                            incoming
                                                ? SheetResult.declined
                                                : SheetResult.skip,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GlassPillButton(
                                    label: 'Chặn ngay',
                                    icon: Icons.block,
                                    tone: GlassPillTone.danger,
                                    onPressed: _waiting
                                        ? null
                                        : () => _finish(SheetResult.block),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            PrimaryButton(
                              label: incoming
                                  ? 'Chấp nhận'
                                  : _waiting
                                  ? 'Đang chờ phản hồi... ${_remaining}s'
                                  : 'Gửi yêu cầu kết nối',
                              icon: incoming ? Icons.check : Icons.send,
                              dimWhenDisabled: true,
                              onPressed: incoming
                                  ? () => _finish(SheetResult.accepted)
                                  : _waiting
                                  ? null
                                  : _send,
                            ),
                            const SizedBox(height: 14),
                            if (incoming)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Yêu cầu hết hạn sau ${_remaining}s...',
                                  style: TextStyle(
                                    color: AppColors.cyan.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.security,
                                    size: 14,
                                    color: const Color(0xFFCDC3D5)
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Thông tin thật chỉ mở khi cả hai xác thực gặp mặt ngoài đời.',
                                    style: TextStyle(
                                      color: const Color(0xFFCDC3D5)
                                          .withValues(alpha: 0.75),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
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
        gradient: const LinearGradient(
          colors: [AppColors.cyan, AppColors.magenta],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.4),
            blurRadius: 20,
          ),
          BoxShadow(
            color: AppColors.magenta.withValues(alpha: 0.35),
            blurRadius: 24,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onboardingBg,
        ),
        child: AvatarImage(avatarId: avatarId, size: 80),
      ),
    );
  }
}
