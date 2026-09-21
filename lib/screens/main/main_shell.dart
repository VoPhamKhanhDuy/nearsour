import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/status_badge.dart';
import 'contacts_tab.dart';
import 'profile_tab.dart';
import 'radar_discover_tab.dart';

/// Khung chính của app sau khi thiết lập xong: header, nội dung theo tab và thanh điều hướng dưới.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _items = [
    AppNavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Radar'),
    AppNavItem(icon: Icons.contacts_outlined, activeIcon: Icons.contacts, label: 'Danh bạ'),
    AppNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Cá nhân'),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Không có nút back: đây là màn gốc của app. Trạng thái Online chỉ hiện đúng một chỗ, ở góc phải.
              const OnboardingHeader(trailing: StatusBadge(label: 'Online', color: AppColors.statusOnline)),
              Expanded(
                child: switch (_index) {
                  0 => const RadarDiscoverTab(),
                  1 => const ContactsTab(),
                  _ => const ProfileTab(),
                },
              ),
              AppBottomNav(items: _items, index: _index, onChanged: (i) => setState(() => _index = i)),
            ],
          ),
        ),
      ),
    );
  }
}
