import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../models/avatar.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/step_progress.dart';
import '../onboarding/gps_intro_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _minAge = 18;
  static const _genders = [('male', 'Nam'), ('female', 'Nữ'), ('other', 'Khác')];

  final _nicknameCtrl = TextEditingController();

  int _avatarId = 1;
  int? _birthYear;
  String? _gender;

  // Chỉ hiện một lỗi tại một thời điểm, khi bấm "Tiếp tục".
  String? _nicknameError;
  String? _birthYearError;
  String? _genderError;

  late final List<int> _years = _buildYears();

  static List<int> _buildYears() {
    final latest = DateTime.now().year - _minAge;
    return [for (var y = latest; y >= latest - 62; y--) y];
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _clearErrors() {
    _nicknameError = null;
    _birthYearError = null;
    _genderError = null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final nicknameErr = Validators.nickname(_nicknameCtrl.text);
    setState(() {
      _clearErrors();
      if (nicknameErr != null) {
        _nicknameError = nicknameErr;
      } else if (_birthYear == null) {
        _birthYearError = 'Vui lòng chọn năm sinh';
      } else if (_gender == null) {
        _genderError = 'Vui lòng chọn giới tính';
      }
    });
    if (_nicknameError != null || _birthYearError != null || _genderError != null) return;

    MockUserStore.updateProfile(
      nickname: _nicknameCtrl.text,
      birthYear: _birthYear!,
      gender: _gender!,
      avatarId: _avatarId,
    );
    // Không xoá màn hồ sơ khỏi stack để người dùng có thể quay lại chỉnh sửa.
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GpsIntroScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        style: CosmicStyle.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              OnboardingHeader(
                onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepProgress(step: 1, total: 3),
                      const SizedBox(height: 10),
                      const _Title(),
                      const SizedBox(height: 10),
                      _AvatarPicker(
                        selectedId: _avatarId,
                        onSelected: (id) => setState(() => _avatarId = id),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Biệt danh'),
                      _NicknameField(
                        controller: _nicknameCtrl,
                        hasError: _nicknameError != null,
                        onChanged: (_) {
                          if (_nicknameError != null) setState(() => _nicknameError = null);
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      _FieldError(_nicknameError),
                      const SizedBox(height: 16),
                      _FieldLabel('Năm sinh'),
                      _BirthYearField(
                        years: _years,
                        value: _birthYear,
                        hasError: _birthYearError != null,
                        onChanged: (y) => setState(() {
                          _birthYear = y;
                          _birthYearError = null;
                        }),
                      ),
                      _FieldError(_birthYearError),
                      const SizedBox(height: 16),
                      _FieldLabel('Giới tính'),
                      _GenderSelector(
                        options: _genders,
                        value: _gender,
                        onChanged: (g) => setState(() {
                          _gender = g;
                          _genderError = null;
                        }),
                      ),
                      _FieldError(_genderError),
                      const SizedBox(height: 20),
                      PrimaryButton(label: 'Tiếp tục →', onPressed: _submit),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Bạn có thể thay đổi sau trong Cài đặt',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
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
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tạo hồ sơ của bạn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: AppColors.magenta.withValues(alpha: 0.4), blurRadius: 20)],
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.magenta),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Thông tin này sẽ được ẩn danh hoàn toàn',
                style: TextStyle(color: Color(0xFFB0A8D0), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  static const double _maxTile = 68;
  static const double _minGap = 8;
  static const double _maxGap = 16;
  static const int _columns = 4;

  final int selectedId;
  final ValueChanged<int> onSelected;

  const _AvatarPicker({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xB37B3FCC), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'CHỌN AVATAR',
              style: TextStyle(color: AppColors.magenta, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Avatar 72px (máy hẹp thì co lại). Khoảng cách ngang = dọc để lưới đều và nằm giữa thẻ.
              final tile = ((constraints.maxWidth - (_columns + 1) * _minGap) / _columns).clamp(0.0, _maxTile);
              final gap = ((constraints.maxWidth - _columns * tile) / (_columns + 1)).clamp(_minGap, _maxGap);
              final rows = (avatarKeys.length / _columns).ceil();
              return Column(
                children: [
                  for (var row = 0; row < rows; row++) ...[
                    if (row > 0) SizedBox(height: gap),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var col = 0; col < _columns; col++) ...[
                          if (col > 0) SizedBox(width: gap),
                          _AvatarTile(
                            id: row * _columns + col + 1,
                            size: tile,
                            selected: selectedId == row * _columns + col + 1,
                            onTap: onSelected,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final int id;
  final double size;
  final bool selected;
  final ValueChanged<int> onTap;

  const _AvatarTile({
    required this.id,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: ValueKey('avatar_$id'),
              onTap: () => onTap(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.cyan : const Color(0xFF3F3B6C),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.6), blurRadius: 15)]
                      : null,
                ),
                child: AvatarImage(avatarId: id, size: size),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldBg, width: 2),
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  final String? message;

  const _FieldError(this.message);

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Text(message!, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
    );
  }
}

/// Khung ô nhập: nền tối, viền magenta mờ, vạch magenta 2px bên trái; sáng lên khi focus, đỏ khi lỗi.
class _FieldShell extends StatelessWidget {
  final Widget child;
  final bool focused;
  final bool hasError;

  const _FieldShell({required this.child, this.focused = false, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : focused
            ? AppColors.magenta
            : AppColors.magenta.withValues(alpha: 0.45);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: focused && !hasError
            ? [BoxShadow(color: AppColors.magenta.withValues(alpha: 0.4), blurRadius: 10)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: child),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: hasError ? AppColors.error : AppColors.magenta),
            ),
          ],
        ),
      ),
    );
  }
}

class _NicknameField extends StatefulWidget {
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _NicknameField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_NicknameField> createState() => _NicknameFieldState();
}

class _NicknameFieldState extends State<_NicknameField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      focused: _focusNode.hasFocus,
      hasError: widget.hasError,
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9B7FE8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              maxLength: 20,
              textInputAction: TextInputAction.done,
              cursorColor: AppColors.cyan,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                isCollapsed: true,
                hintText: 'Nhập biệt danh của bạn...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthYearField extends StatelessWidget {
  final List<int> years;
  final int? value;
  final bool hasError;
  final ValueChanged<int?> onChanged;

  const _BirthYearField({
    required this.years,
    required this.value,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      hasError: hasError,
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF9B7FE8)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isExpanded: true,
                menuMaxHeight: 320,
                dropdownColor: const Color(0xFF201B3B),
                borderRadius: BorderRadius.circular(14),
                icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.4)),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                hint: Text(
                  'Chọn năm sinh',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
                ),
                items: [
                  for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final List<(String, String)> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const _GenderSelector({required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _GenderPill(
              label: options[i].$2,
              selected: value == options[i].$1,
              onTap: () => onChanged(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _GenderPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF7B3FCC), AppColors.magenta])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
