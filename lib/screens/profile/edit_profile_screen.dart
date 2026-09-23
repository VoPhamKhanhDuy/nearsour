import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/primary_button.dart';

/// Chỉnh sửa thông tin THẬT (tên thật, ảnh thật, bio, sở thích) — khác hồ sơ ẩn danh dùng lúc quét radar.
/// Thông tin này chỉ hiện với những kết nối đã xác thực gặp mặt và được lưu vào Danh bạ.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameCtrl = TextEditingController(
    text: MockUserStore.currentUser?.realName ?? '',
  );
  late final _bioCtrl = TextEditingController(
    text: MockUserStore.currentUser?.bio ?? '',
  );
  late final _interestsCtrl = TextEditingController(
    text: MockUserStore.currentUser?.interests ?? '',
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    MockUserStore.updateRealProfile(
      realName: _nameCtrl.text,
      bio: _bioCtrl.text,
      interests: _interestsCtrl.text,
    );
    Navigator.of(context).pop();
  }

  void _uploadPhoto() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Chưa hỗ trợ tải ảnh thật trong bản thử nghiệm.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              _EditHeader(
                onBack: () => Navigator.of(context).maybePop(),
                onSave: _save,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      _PhotoPicker(
                        avatarId: MockUserStore.currentUser?.avatarId,
                        onTap: _uploadPhoto,
                      ),
                      const SizedBox(height: 24),
                      GlowCard(
                        padding: const EdgeInsets.all(16),
                        radius: 20,
                        child: Column(
                          children: [
                            _LabeledField(
                              label: 'Tên thật',
                              controller: _nameCtrl,
                              hint: 'Nhập tên của bạn',
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Bio cá nhân',
                              controller: _bioCtrl,
                              hint: 'Viết vài dòng giới thiệu về bạn',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            _LabeledField(
                              label: 'Sở thích',
                              controller: _interestsCtrl,
                              hint: 'Cà phê, sách, âm nhạc...',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _PrivacyNote(),
                      const SizedBox(height: 28),
                      PrimaryButton(label: 'Lưu thay đổi', onPressed: _save),
                      const SizedBox(height: 12),
                      _CancelButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
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

class _EditHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _EditHeader({required this.onBack, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE6DEFF)),
          ),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSave,
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final int? avatarId;
  final VoidCallback onTap;

  const _PhotoPicker({required this.avatarId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.cyan, AppColors.magenta],
                ),
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: const Color(0xFF2B2546),
                  child: AvatarImage(avatarId: avatarId, size: 90),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.onboardingBg,
                    border: Border.all(
                      color: AppColors.lilac.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 16,
                    color: AppColors.lilac,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Ảnh đại diện thật',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Chỉ hiển thị với kết nối đã xác thực.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFCDC3D5).withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFFCDC3D5).withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lilac.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: controller,
            minLines: maxLines,
            maxLines: maxLines,
            cursorColor: AppColors.cyan,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFFCDC3D5).withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield, size: 18, color: AppColors.cyan),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin thật của bạn không hiển thị trên Radar. Chỉ những kết nối đã xác thực và được lưu vào Danh bạ mới có thể xem.',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

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
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Hủy chỉnh sửa',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCDC3D5),
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
