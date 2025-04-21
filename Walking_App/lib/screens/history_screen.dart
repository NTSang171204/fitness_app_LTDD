import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/widgets/bottom_navigation_bar.dart';

enum ViewMode { Day, Week, Month, Year }

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ViewMode _viewMode = ViewMode.Week;
  String selectedSubPeriod = '';
  List<Map<String, dynamic>> historyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('steps')
        .orderBy('timestamp')
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        historyData = [];
        isLoading = false;
      });
      return;
    }

    List<Map<String, dynamic>> loadedData = snapshot.docs.map((doc) {
      final data = doc.data();
      data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
      return data;
    }).toList();

    setState(() {
      historyData = loadedData;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> _groupData() {
    Map<String, Map<String, dynamic>> grouped = {};

    for (var entry in historyData) {
      DateTime date = entry['timestamp'];
      String key;

      switch (_viewMode) {
        case ViewMode.Day:
          int week = _weekOfYear(date);
          key = '${DateFormat('yyyy-MM-dd').format(date)} (week: $week)';
          break;
        case ViewMode.Week:
          key = '${date.year}-W${_weekOfYear(date)}';
          break;
        case ViewMode.Month:
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          break;
        case ViewMode.Year:
          key = '${date.year}';
          break;
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'key': key,
          'calories': 0.0,
          'distance': 0.0,
          'activeTime': 0.0,
        };
      }

      grouped[key]!['calories'] += (entry['calories'] as num?)?.toDouble() ?? 0.0;
      grouped[key]!['distance'] += (entry['distance'] as num?)?.toDouble() ?? 0.0;
      grouped[key]!['activeTime'] += (entry['steps'] as num?)?.toDouble() ?? 0.0;

    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((k) => grouped[k]!).toList();
  }

  int _weekOfYear(DateTime date) {
    final firstThursday = DateTime(date.year, 1, 4);
    final firstWeekStart = firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final daysDiff = date.difference(firstWeekStart).inDays;
    return ((daysDiff) / 7).floor() + 1;
  }

  void _onRowTap(String key) {
    if (_viewMode == ViewMode.Year) {
      setState(() {
        selectedSubPeriod = key;
        _viewMode = ViewMode.Month;
      });
    } else if (_viewMode == ViewMode.Month) {
      setState(() {
        selectedSubPeriod = key;
        _viewMode = ViewMode.Week;
      });
    } else if (_viewMode == ViewMode.Week) {
      setState(() {
        selectedSubPeriod = key;
        _viewMode = ViewMode.Day;
      });
    }
  }

  List<Map<String, dynamic>> _limitGroupedData(List<Map<String, dynamic>> data) {
    int limit;
    switch (_viewMode) {
      case ViewMode.Day:
        limit = 10;
        break;
      case ViewMode.Week:
        limit = 10;
        break;
      case ViewMode.Month:
        limit = 12;
        break;
      case ViewMode.Year:
        limit = 5;
        break;
    }
    return data.length > limit ? data.sublist(data.length - limit) : data;
  }

  Widget _buildBarChart(List<Map<String, dynamic>> groupedData) {
    final limitedData = _limitGroupedData(groupedData);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: limitedData.map((e) => e['calories'] as double).fold(0.0, (a, b) => a > b ? a : b) + 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  if (index >= 0 && index < limitedData.length) {
                    try {
                        DateTime date = DateTime.parse(limitedData[index]['key'].toString().split(' ').first);
                        return Text('${date.day.toString().padLeft(2, '0')}');
                      } catch (e) {
                        return Text(groupedData[index]['key'].toString().split('-').last);
                      }
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(limitedData.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: limitedData[i]['calories'],
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              )
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildDataRow(Map<String, dynamic> data) {
    return ListTile(
      title: Text(data['key']),
      subtitle: Text(
        'Calories: ${data['calories'].toStringAsFixed(1)}, Distance: ${data['distance'].toStringAsFixed(1)}km, Active Time: ${data['activeTime'].toStringAsFixed(1)} mins',
      ),
      onTap: () => _onRowTap(data['key']),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> groupedData = _groupData();

    return Scaffold(
      appBar: AppBar(
        title: Text("History"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_view_day,
              color: _viewMode == ViewMode.Day ? Colors.blue : Colors.black,
            ),
            onPressed: () => setState(() => _viewMode = ViewMode.Day),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_view_week,
              color: _viewMode == ViewMode.Week ? Colors.blue : Colors.black,
            ),
            onPressed: () => setState(() => _viewMode = ViewMode.Week),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_view_month,
              color: _viewMode == ViewMode.Month ? Colors.blue : Colors.black,
            ),
            onPressed: () => setState(() => _viewMode = ViewMode.Month),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: _viewMode == ViewMode.Year ? Colors.blue : Colors.black,
            ),
            onPressed: () => setState(() => _viewMode = ViewMode.Year),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : historyData.isEmpty
              ? Center(child: Text("Chưa có hoạt động nào"))
              : Column(
                  children: [
                    _buildBarChart(groupedData),
                    Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: groupedData.length,
                        itemBuilder: (ctx, i) => _buildDataRow(groupedData[i]),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: CustomBottomNav(currentIndex: 1),
    );
  }
}
