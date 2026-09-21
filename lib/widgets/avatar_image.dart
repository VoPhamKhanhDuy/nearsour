import 'package:flutter/material.dart';

import '../models/avatar.dart';

/// Avatar ẩn danh dạng tròn từ ảnh local; id không hợp lệ thì hiện icon người.
class AvatarImage extends StatelessWidget {
  final int? avatarId;
  final double size;

  const AvatarImage({super.key, required this.avatarId, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = avatarAsset(avatarId);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: asset == null
            ? ColoredBox(
                color: const Color(0xFF2D1F7A),
                child: Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: Colors.white54,
                ),
              )
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
      ),
    );
  }
}
