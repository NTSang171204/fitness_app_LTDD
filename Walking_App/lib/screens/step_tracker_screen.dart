import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../services/step_tracker_screen_service.dart';

class StepTrackerScreen extends StatefulWidget {
  @override
  _StepTrackerScreenState createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  late StepTrackerService stepService;

  // ✅ Biến để hiển thị loading khi khởi tạo xong pedometer & Hive
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ✅ Lấy instance StepTrackerService từ Provider (listen: false để tránh rebuild không cần thiết)
    stepService = Provider.of<StepTrackerService>(context, listen: false);

    // ✅ Gọi hàm khởi tạo service
    initStepTracking();
  }

  // ✅ Hàm async khởi tạo service
  Future<void> initStepTracking() async {
    try {
      await stepService.init(); // Khởi động Hive, Pedometer, v.v.
    } catch (e) {
      // Nếu có lỗi, hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi khởi động step tracker: $e')),
      );
    } finally {
      // ✅ Sau khi init xong thì tắt loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ❌ ĐÃ GỠ BỎ dispose() thủ công – Provider sẽ tự dispose StepTrackerService
  // @override
  // void dispose() {
  //   stepService.dispose(); // ❌ Gây lỗi nếu Provider đã dispose rồi
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<StepTrackerService>(
      builder: (context, stepService, _) {
        // ✅ Loading UI khi đang khởi tạo
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text("Daily Steps")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ Tính phần trăm bước so với mục tiêu
        double percent = (stepService.stepsToday / stepService.dailyGoal).clamp(0.0, 1.0);

        // ✅ Chuyển đổi khoảng cách từ cm sang m
        double distanceInMeters = stepService.totalDistance / 100;

        return Scaffold(
          appBar: AppBar(title: Text("Daily Steps")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 150.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: percent,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${stepService.stepsToday}',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      Text("steps", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  progressColor: Colors.green,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(height: 20),
                Text('Distance: ${distanceInMeters.toStringAsFixed(2)} m',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Avg Accel: ${stepService.averageAcceleration.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
