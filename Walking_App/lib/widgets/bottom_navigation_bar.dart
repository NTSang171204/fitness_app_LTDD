import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Không làm gì nếu đang ở trang đó
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, "/dailySteps");
            break;
          case 1:
            Navigator.pushReplacementNamed(context, "/history");
            break;
          case 2:
            Navigator.pushReplacementNamed(context, "/profile");
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
