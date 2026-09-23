import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../welcome/welcome_screen.dart';

/// NearSoul Admin: giám sát hệ thống ở tầng metadata/thống kê — KHÔNG xem được nội dung chat hay câu trả lời
/// Quiz của người dùng (đúng nguyên tắc ẩn danh của app). Vào được màn này bằng tài khoản có `isAdmin = true`.
///
/// Toàn bộ số liệu ở đây là DỮ LIỆU MẪU TĨNH cho mục đích trình bày — app chưa có backend đa người dùng
/// thật để tính các con số như "1.248 người dùng hoạt động" hay "12.540 tài khoản đăng ký".
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _leave(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    }
  }

  void _logout(BuildContext context) {
    MockUserStore.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context);
      },
      child: Scaffold(
        body: CosmicBackground(
          style: CosmicStyle.onboarding,
          child: SafeArea(
            child: Column(
              children: [
                _AdminHeader(onBack: () => _leave(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _KpiGrid(),
                        const SizedBox(height: 16),
                        const _ActivityTrendCard(),
                        const SizedBox(height: 16),
                        const _FunnelCard(),
                        const SizedBox(height: 16),
                        _SafetyReportsCard(
                          onViewReports: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Danh sách báo cáo chi tiết sẽ có ở bản sau.',
                                ),
                              ),
                            ),
                        ),
                        const SizedBox(height: 16),
                        const _PrivacyGovernanceCard(),
                        const SizedBox(height: 16),
                        _AdminAccountRow(onLogout: () => _logout(context)),
                        const SizedBox(height: 24),
                        const _Footer(),
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

class _AdminHeader extends StatefulWidget {
  final VoidCallback onBack;

  const _AdminHeader({required this.onBack});

  @override
  State<_AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<_AdminHeader>
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: const Color(0xFF2B2546),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      color: Color(0xFFE6DEFF),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NearSoul Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Giám sát hệ thống',
                      style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lilac.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.lilac.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'ROLE_ADMIN',
                  style: TextStyle(
                    color: AppColors.lilac,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _pulse,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SYSTEM SECURE',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: const [
        _KpiTile(
          icon: Icons.group,
          iconColor: AppColors.cyan,
          label: 'Người dùng hoạt động',
          value: '1.248',
          delta: '+12%',
        ),
        _KpiTile(
          icon: Icons.person_add,
          iconColor: AppColors.lilac,
          label: 'Tài khoản đăng ký',
          value: '12.540',
        ),
        _KpiTile(
          icon: Icons.favorite,
          iconColor: AppColors.magenta,
          label: 'Tỷ lệ gặp mặt',
          value: '64%',
        ),
        _KpiTile(
          icon: Icons.qr_code_scanner,
          iconColor: AppColors.cyan,
          label: 'QR xác thực',
          value: '892',
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? delta;

  const _KpiTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: iconColor),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.8),
              fontSize: 11.5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 6),
                Text(
                  delta!,
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Biểu đồ đường minh hoạ "xu hướng hoạt động" — vẽ tay bằng CustomPaint, chạy 1 lần lúc mở màn.
class _ActivityTrendCard extends StatefulWidget {
  const _ActivityTrendCard();

  @override
  State<_ActivityTrendCard> createState() => _ActivityTrendCardState();
}

class _ActivityTrendCardState extends State<_ActivityTrendCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'XU HƯỚNG HOẠT ĐỘNG',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            '7 ngày gần nhất',
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  CustomPaint(painter: _TrendPainter(_controller.value)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in _days)
                Text(
                  d,
                  style: TextStyle(
                    color: const Color(0xFFCDC3D5).withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final double progress;

  _TrendPainter(this.progress);

  // Điểm mẫu tĩnh (0..1) cho đường xu hướng, chỉ để minh hoạ hình dáng.
  static const _points = [0.25, 0.68, 0.42, 0.7, 0.55, 0.82, 0.95];

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / (_points.length - 1);
    final offsets = [
      for (var i = 0; i < _points.length; i++)
        Offset(i * dx, size.height * (1 - _points[i])),
    ];

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final mid = Offset(
        (offsets[i].dx + offsets[i + 1].dx) / 2,
        (offsets[i].dy + offsets[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(offsets[i].dx, offsets[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(offsets.last.dx, offsets.last.dy);

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress.clamp(0, 1));

    final fillPath = Path.from(drawn)
      ..lineTo(offsets.last.dx * progress, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cyan.withValues(alpha: 0.35),
            AppColors.cyan.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.cyan,
    );

    if (progress > 0.98) {
      canvas.drawCircle(offsets.last, 3.5, Paint()..color = AppColors.cyan);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard();

  static const _steps = [
    ('Radar Match', 1.0),
    ('Hoàn thành AI Quiz', 0.82),
    ('Mở phòng chat', 0.78),
    ('QR xác thực', 0.46),
    ('Lưu Danh bạ', 0.28),
  ];

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MATCH TO MEET FUNNEL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _FunnelBar(label: _steps[i].$1, value: _steps[i].$2),
          ],
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final double value;

  const _FunnelBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFFCDC3D5).withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: AppColors.lilac,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 6,
            color: const Color(0xFF201B3B),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lilac, AppColors.cyan],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SafetyReportsCard extends StatelessWidget {
  final VoidCallback onViewReports;

  const _SafetyReportsCard({required this.onViewReports});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.report,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SAFETY REPORTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: '24',
                  label: 'TUẦN NÀY',
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  value: '8',
                  label: 'ĐÃ XỬ LÝ',
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  value: '3',
                  label: 'ƯU TIÊN CAO',
                  color: AppColors.magenta,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _MiniStat(
                  value: '13',
                  label: 'ĐANG XEM XÉT',
                  color: Color(0xFFCDC3D5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewReports,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: const Color(0xFFCDC3D5).withValues(alpha: 0.2),
                ),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Xem báo cáo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4B4453).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.6),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyGovernanceCard extends StatelessWidget {
  const _PrivacyGovernanceCard();

  static const _points = [
    'Không truy cập nội dung chat',
    'Không truy cập câu trả lời Quiz',
    'Phân quyền khóa cứng ở tầng hệ thống',
    'Mọi thao tác Admin được ghi Audit Log',
  ];

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.shield, size: 26, color: AppColors.cyan),
          ),
          const SizedBox(height: 12),
          const Text(
            'DATA PRIVACY GOVERNANCE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin chỉ được xem metadata và thống kê tổng quan. Nội dung chat và câu trả lời Quiz riêng tư được bảo vệ tuyệt đối.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.85),
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in _points) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (p != _points.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAccountRow extends StatelessWidget {
  final VoidCallback onLogout;

  const _AdminAccountRow({required this.onLogout});

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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Quyền quản trị viên',
                  style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: StadiumBorder(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onLogout,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 14, color: AppColors.error),
                    SizedBox(width: 6),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Quyền riêng tư được bảo vệ theo thiết kế. Admin chỉ được cấp quyền trên metadata vận hành.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.5),
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 28, height: 1, color: const Color(0xFF4B4453)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'NEARSOUL PROTOCOL v2.4',
                style: TextStyle(
                  color: const Color(0xFFCDC3D5).withValues(alpha: 0.35),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Container(width: 28, height: 1, color: const Color(0xFF4B4453)),
          ],
        ),
      ],
    );
  }
}
