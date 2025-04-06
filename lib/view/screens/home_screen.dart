import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/auth_view_model.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    final user = authVM.user;

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authVM.logout();
            },
          ),
        ],
      ),
      body: Center(
        child: user != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("📧 Email: ${user.email}"),
                  Text("🆔 UID: ${user.uid}"),
                  if (user.displayName != null) Text("👤 Name: ${user.displayName}"),
                  if (user.photoURL != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(user.photoURL!, height: 80),
                    ),
                ],
              )
            : Text("No user info available."),
      ),
    );
  }
}
