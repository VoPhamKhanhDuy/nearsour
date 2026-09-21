import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tab "Danh bạ" (tạm): danh bạ vĩnh viễn sẽ làm sau khi có luồng gặp mặt.
class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_outlined, size: 56, color: AppColors.lilac),
            SizedBox(height: 16),
            Text(
              'Danh bạ',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Những người bạn đã gặp và muốn giữ kết nối sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFCDC3D5), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
