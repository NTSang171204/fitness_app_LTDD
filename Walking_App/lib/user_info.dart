import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoScreen extends StatelessWidget {
  final User user;

  UserInfoScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    String photoUrl = user.photoURL ?? 'https://via.placeholder.com/150';
    String displayName = user.displayName ?? 'Unknown';
    String email = user.email ?? 'No Email';
    String dob = '17/12/2004'; // Thay bằng giá trị từ Google People API nếu có

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Ảnh đại diện
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(photoUrl),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Thêm chức năng thay đổi avatar
                  },
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, color: Colors.blue, size: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Trường nhập Name
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              controller: TextEditingController(text: displayName),
            ),
            SizedBox(height: 10),

            // Trường nhập Email
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              controller: TextEditingController(text: email),
            ),
            SizedBox(height: 10),

            // Trường chọn Date of Birth
            TextField(
              
              decoration: InputDecoration(
                labelText: "Date of Birth",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              controller: TextEditingController(text: dob),
            ),
            SizedBox(height: 30),

            // Nút Back
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Back", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
