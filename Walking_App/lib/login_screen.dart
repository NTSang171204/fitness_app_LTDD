import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login/pages/onboard_screen.dart';
import 'package:login/user_info.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// Đăng nhập bằng Email/Password
  Future<void> signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Lấy user sau khi đăng nhập
      User? user = _auth.currentUser;

      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserInfoScreen(user: user)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  /// Đăng nhập bằng Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Người dùng huỷ đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // Debug thông tin user trả về
      debugPrint("✅ Đăng nhập thành công!");
      debugPrint("👤 ID: ${user?.uid}");
      debugPrint("📧 Email: ${user?.email}");
      debugPrint("📝 Display Name: ${user?.displayName}");
      debugPrint("🖼️ Photo URL: ${user?.photoURL}");

      // Chuyển hướng sang trang User Info
      if (user != null) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => UserInfoScreen(user: user)),
        // );
        Navigator.push(context, MaterialPageRoute(builder: (context) => OnboardScreen()),);
      }
    } catch (e) {
      debugPrint("❌ Lỗi Google Sign-In: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi Google Sign-In: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng nhập")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset("assets/images/logo_blue.png"),
            Text("SmartTasks", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            Text("A simple and efficent to-do app", style: TextStyle(fontSize: 16, color: Colors.blue),),
            SizedBox(height: 100),
            Text("Welcome", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Ready to explore? Log in to get started.", style: TextStyle(fontSize: 16)),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signIn,
              child: Text("Đăng nhập"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: signInWithGoogle,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[200]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                
                children: [
                  Image.asset("assets/images/google_logo.png"),

                  Text("      Đăng nhập bằng Google", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
