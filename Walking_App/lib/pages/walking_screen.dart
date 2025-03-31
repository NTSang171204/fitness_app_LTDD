import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class WalkingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue.shade50,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 10.0,
              percent: 5000 / 6000, // Dynamic value
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('5,000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('03/03/2025', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Goal: 6,000', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.grey.shade300,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoCard(Icons.favorite, '1,352 kcal', 'Calories', Colors.red),
                _infoCard(Icons.location_on, '17 km', 'Distance', Colors.purple),
                _infoCard(Icons.access_time, '4:10 h', 'Active Time', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
