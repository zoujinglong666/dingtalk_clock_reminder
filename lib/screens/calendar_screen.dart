import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/clock_calendar.dart';
import '../widgets/tech_widgets.dart';
import '../models/clock_status.dart'; // 导入ClockStatus类

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Map<DateTime, ClockStatus> clockData = {};
  bool verticalLayout = true;
  double cellSize = 24.0;
  double borderRadius = 4.0;
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCurrentMonthClockData();
  }

  // 加载当月打卡数据
  Future<void> _loadCurrentMonthClockData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final lastDay = DateTime(currentYear, currentMonth + 1, 0).day;

    // 清空现有数据
    clockData.clear();

    // 循环加载当月每一天的数据
    for (int day = 1; day <= lastDay; day++) {
      final date = DateTime(currentYear, currentMonth, day);
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      // 尝试从SharedPreferences获取打卡记录
      final clockInTimeString = prefs.getString('clock_in_$dateString');
      final clockOutTimeString = prefs.getString('clock_out_$dateString');

      if (clockInTimeString != null && clockOutTimeString != null) {
        // 解析打卡时间
        final clockInTime = DateTime.parse(clockInTimeString);
        final clockOutTime = DateTime.parse(clockOutTimeString);

        // 判断是否迟到或早退
        // 这里假设上班时间是9:00，下班时间是18:00
        final workStartTime = DateTime(currentYear, currentMonth, day, 9, 0);
        final workEndTime = DateTime(currentYear, currentMonth, day, 18, 0);

        final isLate = clockInTime.isAfter(workStartTime);
        final isEarlyLeave = clockOutTime.isBefore(workEndTime);

        // 添加到打卡数据
        clockData[date] = ClockStatus(isLate: isLate, isEarlyLeave: isEarlyLeave);
      }
    }

    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '打卡日历',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 颜色说明
            TechCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                [
                  const Text('打卡状态说明', style: subtitleStyle),
                  const SizedBox(height: 10),
                  Row(
                    children:
                    [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBEDF0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('未打卡', style: bodyStyle),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children:
                    [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A936F),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('全勤(无迟到早退)', style: bodyStyle),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children:
                    [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('迟到', style: bodyStyle),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children:
                    [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDD6B20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('早退', style: bodyStyle),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children:
                    [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC026D3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('迟到+早退', style: bodyStyle),
                    ],
                  ),
                ],
              ),
            ),
            // 打卡日历
            Expanded(
              child: ClockCalendar(
                clockData: clockData,
                cellSize: cellSize,
                cellSpacing: 4.0,
                borderRadius: borderRadius,
                verticalLayout: verticalLayout,
                onTap: (date) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('点击了 ${DateFormat('yyyy-MM-dd').format(date)}'),
                    ),
                  );
                },
                onLongPress: (date) {
                  final status = clockData[date];
                  String statusText = '未打卡';
                  if (status != null) {
                    if (status.isFullAttendance) {
                      statusText = '全勤(无迟到早退)';
                    } else if (status.isLate && status.isEarlyLeave) {
                      statusText = '迟到+早退';
                    } else if (status.isLate) {
                      statusText = '迟到';
                    } else if (status.isEarlyLeave) {
                      statusText = '早退';
                    }
                  }
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(DateFormat('yyyy-MM-dd').format(date)),
                      content: Text('打卡状态: $statusText'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}