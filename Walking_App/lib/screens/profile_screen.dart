import 'package:flutter/material.dart';
import 'package:login/utils/logout_helper.dart';
import 'package:login/widgets/bottom_navigation_bar.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.black),
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Đăng xuất'),
                content: Text('Bạn có chắc chắn muốn đăng xuất?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Đăng xuất')),
                ],
              ),
            );

            if (shouldLogout == true) {
              handleLogout(context);
            }
          },

        ),
      ],
    ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Avatar + Name + Info
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/avatar.png'), // or NetworkImage
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, size: 18),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Puerto Rico",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text("youremail@domain.com | +01 234 567 89"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Edit info, Notifications, Language
            _buildCard([
              _buildListTile(Icons.edit, "Edit profile information", () {}),
              _buildListTileWithTrailing(
                Icons.notifications, "Notifications", "ON", () {}),
              _buildListTileWithTrailing(
                Icons.language, "Language", "English", () {}),
            ]),

            // Section 2: Security, Theme
            _buildCard([
              _buildListTile(Icons.lock, "Security", () {}),
              _buildListTileWithTrailing(
                Icons.palette, "Theme", "Light mode", () {}),
            ]),

            // Section 3: Help, Contact, Privacy
            _buildCard([
              _buildListTile(Icons.help, "Help & Support", () {}),
              _buildListTile(Icons.mail, "Contact us", () {}),
              _buildListTile(Icons.privacy_tip, "Privacy policy", () {}),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildListTileWithTrailing(
    IconData icon,
    String title,
    String trailingText,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailingText, style: const TextStyle(color: Colors.blue)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}
