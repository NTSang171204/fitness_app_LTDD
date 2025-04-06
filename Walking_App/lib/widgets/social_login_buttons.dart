import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton('assets/google.png'),
        _buildSocialButton('assets/facebook.png'),
        _buildSocialButton('assets/apple.png'),
      ],
    );
  }

  Widget _buildSocialButton(String imagePath) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Image.asset(imagePath, width: 30, height: 30),
    );
  }
}
