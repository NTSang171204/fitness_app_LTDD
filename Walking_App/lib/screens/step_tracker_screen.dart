import 'package:flutter/material.dart';
import 'package:login/widgets/bottom_navigation_bar.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../services/step_tracker_screen_service.dart';

class StepTrackerScreen extends StatefulWidget {
  @override
  _StepTrackerScreenState createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  late StepTrackerService stepService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    stepService = Provider.of<StepTrackerService>(context, listen: false);
    initStepTracking();
  }

  Future<void> initStepTracking() async {
    try {
      await stepService.init();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi khởi động step tracker: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StepTrackerService>(
      builder: (context, stepService, _) {
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text("Daily Steps")),
            body: Center(child: CircularProgressIndicator()),
            bottomNavigationBar: CustomBottomNav(currentIndex: 0),
          );
        }

        double percent = (stepService.stepsToday / stepService.dailyGoal).clamp(0.0, 1.0);
        double distanceInKm = stepService.totalDistance / 100000; // từ cm sang km
        double kcal = stepService.stepsToday * 0.04; // ví dụ: 0.04 kcal mỗi bước
        double accel = stepService.averageAcceleration;

        return Scaffold(
          appBar: AppBar(title: Text("Daily Steps"), backgroundColor: Colors.blue),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 100.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: percent,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stepService.stepsToday}',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formattedDate(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Goal: ${stepService.dailyGoal}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  progressColor: Colors.blue[300],
                  backgroundColor: Colors.grey.shade300,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoCard(Icons.local_fire_department, '${kcal.toStringAsFixed(0)} kcal', 'Calories', Colors.red),
                    _infoCard(Icons.location_on, '${distanceInKm.toStringAsFixed(2)} km', 'Distance', Colors.purple),
                    _infoCard(Icons.speed, accel.toStringAsFixed(2), 'Acceleration', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(currentIndex: 0),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
