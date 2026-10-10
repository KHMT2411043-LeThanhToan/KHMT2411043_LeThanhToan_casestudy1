import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Màn hình cá nhân. Thông tin người dùng đang là dữ liệu mẫu cố định
/// (app chưa có đăng nhập); các mục menu chưa có chức năng sẽ báo "đang phát triển".
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _userName = 'Nguyễn Văn A';
  static const _userEmail = 'nguyenvana@example.com';

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang được phát triển')),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Cá nhân',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFDCE7FB),
                child: Icon(Icons.person, size: 36, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      _userName,
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userEmail,
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.person_outline,
            label: 'Thông tin cá nhân',
            onTap: () => _comingSoon(context),
          ),
          _MenuItem(
            icon: Icons.settings_outlined,
            label: 'Cài đặt ngân sách',
            onTap: () => _comingSoon(context),
          ),
          _MenuItem(
            icon: Icons.category_outlined,
            label: 'Danh mục chi tiêu',
            onTap: () => _comingSoon(context),
          ),
          _MenuItem(
            icon: Icons.backup_outlined,
            label: 'Sao lưu dữ liệu',
            onTap: () => _comingSoon(context),
          ),
          _MenuItem(
            icon: Icons.lock_outline,
            label: 'Đổi mật khẩu',
            onTap: () => _comingSoon(context),
          ),
          _MenuItem(
            icon: Icons.logout,
            label: 'Đăng xuất',
            color: Colors.red,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.black87;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: c),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 15, color: c)),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
