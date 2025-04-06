import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<bool> _selectedToggle = [true, false, false]; // Mặc định chọn "Week"
  String _currentMode = "Week"; // Trạng thái mặc định: hiển thị theo "Day"

  @override
  void initState() {
    super.initState();

    // Gửi sự kiện kiểm tra Firebase Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'history_screen_opened',
      parameters: {
        'screen': 'HistoryScreen',
        'opened_at': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("History"), backgroundColor: Colors.blue),
      body: Column(
        children: [
          SizedBox(height: 10),
          Image.asset('assets/heart_good.png', height: 120), // Đặt ảnh vào assets
          SizedBox(height: 10),

          // Nút chọn Week / Month / Year
          ToggleButtons(
            borderRadius: BorderRadius.circular(20),
            selectedColor: Colors.white,
            fillColor: Colors.blue,
            color: Colors.black,
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Week")),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Month")),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Year")),
            ],
            isSelected: _selectedToggle,
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < _selectedToggle.length; i++) {
                  _selectedToggle[i] = (i == index);
                }
                // Cập nhật chế độ hiển thị
                _currentMode = (index == 0) ? "Week" : (index == 1) ? "Month" : "Year";
              });
            },
          ),
          SizedBox(height: 10),

          // Hàng tiêu đề cố định (tuỳ theo chế độ)
          Container(
            color: Colors.lightBlue[100],
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _getHeaders(), // Lấy tiêu đề theo chế độ
            ),
          ),

          // Danh sách cuộn dọc
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _getDataRows(), // Lấy dữ liệu theo chế độ
              ),
            ),
          ),
        ],
      ),

      // Thanh điều hướng
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Mặc định chọn "History"
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, "/dailySteps");
          } else if (index == 2) {
            Navigator.pushNamed(context, "/profile");
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Trả về tiêu đề bảng dựa trên chế độ hiện tại
  List<Widget> _getHeaders() {
    if (_currentMode == "Week") {
      return ["Day", "Calories", "Distance (m)", "Active time (m)"].map(_headerText).toList();
    } else if (_currentMode == "Month") {
      return ["Week", "Calories", "Distance (m)", "Active time (m)"].map(_headerText).toList();
    } else {
      return ["Month", "Calories", "Distance (m)", "Active time (m)"].map(_headerText).toList();
    }
  }

  // Trả về dữ liệu theo chế độ hiển thị
  List<Widget> _getDataRows() {
    if (_currentMode == "Week") {
      return List.generate(7, (index) => _buildDataRow("Day ${index + 1}", index)); // 7 ngày
    } else if (_currentMode == "Month") {
      return List.generate(4, (index) => _buildDataRow("Week ${index + 1}", index)); // 4 tuần
    } else {
      return List.generate(12, (index) => _buildDataRow("Month ${index + 1}", index)); // 12 tháng
    }
  }

  // Widget tiêu đề bảng
  Widget _headerText(String text) {
    return Expanded(
      child: Center(
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget dòng dữ liệu
  Widget _buildDataRow(String label, int index) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _dataText(label),
          _dataText('${100 + index * 5}'),
          _dataText('2000'),
          _dataText('${15 - index * 0.5}'),
        ],
      ),
    );
  }

  // Widget ô dữ liệu
  Widget _dataText(String text) {
    return Expanded(
      child: Center(
        child: Text(text),
      ),
    );
  }
}
