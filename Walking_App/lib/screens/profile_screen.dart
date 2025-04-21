import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login/providers/theme_provider.dart';
import 'package:login/utils/logout_helper.dart';
import 'package:login/widgets/bottom_navigation_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:login/services/flutter_notify_services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String phone = '';
  String? localAvatarPath;
  bool isNotificationOn = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserInfo();
    await _loadLocalAvatar();
    await _loadNotificationStatus();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      setState(() {
        name = data['name'] ?? 'Unknown User';
        email = data['email'] ?? 'noemail@domain.com';
        phone = data['phone'] ?? 'No phone';
      });
    }
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('localAvatarPath');
    if (path != null && File(path).existsSync()) {
      setState(() {
        localAvatarPath = path;
      });
    }
  }

  Future<void> _pickAndSaveLocalAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final prefs = await SharedPreferences.getInstance();

      final oldPath = prefs.getString('localAvatarPath');
      if (oldPath != null && File(oldPath).existsSync()) {
        await File(oldPath).delete();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$timestamp.jpg';
      final localPath = '${dir.path}/$fileName';

      final newImage = await File(picked.path).copy(localPath);

      await prefs.setString('localAvatarPath', newImage.path);

      setState(() {
        localAvatarPath = newImage.path;
      });
    }
  }

  Future<void> _loadNotificationStatus() async {
    final enabled = await NotiService().isNotificationEnabled();
    setState(() {
      isNotificationOn = enabled;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    await NotiService().setNotificationEnabled(value);
    setState(() {
      isNotificationOn = value;
    });
  }

  Widget _buildThemeTile(ThemeProvider themeProvider) {
    final isDarkMode = themeProvider.isDarkMode;

    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text("Theme"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isDarkMode ? "Dark mode" : "Light mode",
            style: const TextStyle(color: Colors.blue),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isDarkMode,
            onChanged: themeProvider.toggleTheme,
            activeColor: Colors.white,
            activeTrackColor: Colors.blue,
            inactiveThumbColor: Colors.grey.shade700,
            inactiveTrackColor: Colors.grey.shade400,
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).iconTheme.color),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất')),
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
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: localAvatarPath != null
                            ? FileImage(File(localAvatarPath!))
                            : null,
                        child: localAvatarPath == null ? const Icon(Icons.person, size: 50) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndSaveLocalAvatar,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color.fromARGB(255, 168, 232, 91),
                            child: Icon(Icons.edit, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("$email | $phone"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildCard([
                    _buildListTile(Icons.edit, "Edit profile information", () {
                      Navigator.pushNamed(context, '/userInfoForm');
                    }),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text("Notifications"),
                      trailing: Switch(
                        value: isNotificationOn,
                        onChanged: _toggleNotification,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue,
                        inactiveThumbColor: Colors.grey.shade700,
                        inactiveTrackColor: Colors.grey.shade400,
                      ),
                    ),
                    _buildListTileWithTrailing(Icons.language, "Language", "English", () {}),
                  ]),
                  _buildCard([
                    _buildListTile(Icons.lock, "Security", () {}),
                    _buildThemeTile(themeProvider),
                  ]),
                  _buildCard([
                    _buildListTile(Icons.help, "Help & Support", () {}),
                    _buildListTile(Icons.mail, "Contact us", () {}),
                    _buildListTile(Icons.privacy_tip, "Privacy policy", () {
                      Navigator.pushNamed(context, '/policy');
                    }),
                  ]),
                  const SizedBox(height: 32),
      