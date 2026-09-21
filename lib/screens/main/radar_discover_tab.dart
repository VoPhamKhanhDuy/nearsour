import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/discover_radar.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';

/// Tab "Radar": bật/tắt tìm người gần bạn. Thứ tự: radar → nút hành động → giải thích → bộ lọc an toàn.
class RadarDiscoverTab extends StatefulWidget {
  const RadarDiscoverTab({super.key});

  @override
  State<RadarDiscoverTab> createState() => _RadarDiscoverTabState();
}

class _RadarDiscoverTabState extends State<RadarDiscoverTab> {
  late bool _scanning = MockUserStore.currentUser?.isScanning ?? false;

  // TODO: khi đang quét, sau một lúc mở bottom sheet thông tin người phù hợp (bỏ qua / chặn / gửi yêu cầu).
  void _toggle() {
    setState(() => _scanning = !_scanning);
    MockUserStore.currentUser?.isScanning = _scanning;
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
                Shadow(color: AppColors.cyan.withValues(alpha: 0.8), blurRadius: 16),
                Shadow(color: AppColors.magenta.withValues(alpha: 0.4), blurRadius: 24),
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
              style: const TextStyle(color: Color(0xFFCDC3D5), fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          DiscoverRadar(scanning: _scanning, avatarId: MockUserStore.currentUser?.avatarId),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _scanning ? 'Dừng tìm kiếm' : 'Sẵn sàng kết nối',
            style: _scanning ? PrimaryButtonStyle.outline : PrimaryButtonStyle.gradient,
            onPressed: _toggle,
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.shield_outlined, size: 14, color: Color(0xFFD1D5DB)),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Hệ thống tự chọn 1 người phù hợp. Bạn không cần chọn thủ công.',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13, height: 1.35),
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
              Text('Bộ lọc an toàn', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
          child: Text(label, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
