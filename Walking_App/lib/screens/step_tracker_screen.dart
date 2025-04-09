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

  // ✅ Biến để kiểm tra xem dữ liệu đã sẵn sàng để hiển thị chưa
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ✅ Lấy instance StepTrackerService từ Provider (listen: false để tránh rebuild không cần thiết)
    stepService = Provider.of<StepTrackerService>(context, listen: false);

    // ✅ Gọi hàm khởi tạo service bao gồm Hive, Pedometer, Accel, v.v.
    initStepTracking();
  }

  // ✅ Hàm async để khởi tạo và xử lý lỗi nếu có
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
    // ✅ Dùng Consumer để lắng nghe thay đổi từ StepTrackerService
    return Consumer<StepTrackerService>(
      builder: (context, stepService, _) {
        // ✅ Nếu đang loading (chưa init xong), hiển thị loading screen
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text("Daily Steps")),
            body: Center(child: CircularProgressIndicator()),
            bottomNavigationBar: CustomBottomNav(currentIndex: 0), // ✅ Nav bar cho tab Home
          );
        }

        // ✅ Tính phần trăm đạt được trong ngày
        double percent = (stepService.stepsToday / stepService.dailyGoal).clamp(0.0, 1.0);

        // ✅ Chuyển đổi khoảng cách từ cm sang m
        double distanceInMeters = stepService.totalDistance / 100;

        return Scaffold(
          appBar: AppBar(title: Text("Daily Steps")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Hiển thị vòng tròn phần trăm với bước chân
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

                // ✅ Hiển thị quãng đường đã đi
                Text('Distance: ${distanceInMeters.toStringAsFixed(2)} m',
                    style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),

                // ✅ Hiển thị gia tốc trung bình (đã tính toán để lọc chuyển động không hợp lệ)
                Text('Avg Accel: ${stepService.averageAcceleration.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(currentIndex: 0), // ✅ Nav bar cố định ở dưới cùng
        );
      },
    );
  }
}
