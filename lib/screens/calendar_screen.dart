import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clock_status.dart';
import '../models/daily_clock_data.dart';
import '../widgets/clock_calendar.dart';
import '../widgets/tech_widgets.dart';

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
    // 为指定日期打卡
    Future<void> _markAsClockedForDate(DateTime date, bool isClockIn, {DateTime? customClockTime}) async {
      final prefs = await SharedPreferences.getInstance();
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      // 获取现有的打卡数据
      final clockDataJson = prefs.getString('clock_data');
      Map<String, dynamic> clockDataMap = {};
      if (clockDataJson != null) {
        clockDataMap = jsonDecode(clockDataJson);
      }

      // 设置打卡时间（用户自定义或默认）
      DateTime clockTime;
      if (customClockTime != null) {
        // 使用用户自定义时间
        clockTime = DateTime(date.year, date.month, date.day, customClockTime.hour, customClockTime.minute);
      } else {
        // 使用默认时间
        if (isClockIn) {
          clockTime = DateTime(date.year, date.month, date.day, 9, 0);
        } else {
          clockTime = DateTime(date.year, date.month, date.day, 18, 0);
        }
      }

      DailyClockData dailyData;
      if (clockDataMap.containsKey(dateString)) {
        // 已存在当天数据，更新打卡时间
        final existingData = DailyClockData.fromJson(clockDataMap[dateString]);
        if (isClockIn) {
          dailyData = DailyClockData.clockedIn(
            date: dateString,
            clockInTime: clockTime,
            clockOutTime: existingData.clockOutTime,
          );
        } else {
          // 下班打卡前必须先有上班打卡
          if (existingData.hasClockedIn) {
            dailyData = DailyClockData.clockedIn(
              date: dateString,
              clockInTime: existingData.clockInTime!,
              clockOutTime: clockTime,
            );
          } else {
            // 如果没有上班打卡记录，先创建上班打卡记录（默认9:00）
            dailyData = DailyClockData.clockedIn(
              date: dateString,
              clockInTime: DateTime(date.year, date.month, date.day, 9, 0),
              clockOutTime: clockTime,
            );
          }
        }
      } else {
        // 不存在当天数据，创建新数据
        if (isClockIn) {
          dailyData = DailyClockData.clockedIn(
            date: dateString,
            clockInTime: clockTime,
          );
        } else {
          // 下班打卡前必须先有上班打卡
          dailyData = DailyClockData.clockedIn(
            date: dateString,
            clockInTime: DateTime(date.year, date.month, date.day, 9, 0),
            clockOutTime: clockTime,
          );
        }
      }

      // 更新数据
      clockDataMap[dateString] = dailyData.toJson();
      // 保存回SharedPreferences
      prefs.setString('clock_data', jsonEncode(clockDataMap));
      // 更新UI
      setState(() {
        clockData[date] = dailyData.clockStatus;
      });

      // 显示补卡成功通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('补卡成功'),
        ),
      );
      _loadCurrentMonthClockData();
    }


  // 计算加班时长（小时）
  double _calculateOvertimeHours(DateTime clockOutTime) {
    // 加班起始时间为18:30
    final overtimeStartTime = DateTime(clockOutTime.year, clockOutTime.month, clockOutTime.day, 18, 30);
    // 如果下班时间早于18:30，则没有加班
    if (clockOutTime.isBefore(overtimeStartTime)) {
      return 0.0;
    }

    // 计算加班分钟数
    final minutes = clockOutTime.difference(overtimeStartTime).inMinutes;
    // 按半小时维度统计，向下取整
    // 例如: 160分钟 → 160 / 30 = 5.333 → 5个半小时 → 2.5小时
    final halfHourUnits = minutes ~/ 30;
    return halfHourUnits * 0.5;
  }
  // 加载当月打卡数据
  Future<void> _loadCurrentMonthClockData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final lastDay = DateTime(currentYear, currentMonth + 1, 0).day;
    // 创建新的数据映射，而不是修改现有映射
    final newClockData = <DateTime, ClockStatus>{};
    // 从新的数据结构加载
    final clockDataJson = prefs.getString('clock_data');
    Map<String, dynamic> clockDataMap = {};
    if (clockDataJson != null) {
      clockDataMap = jsonDecode(clockDataJson);
    }

    // 循环加载当月每一天的数据
    for (int day = 1; day <= lastDay; day++) {
      final date = DateTime(currentYear, currentMonth, day);
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      // 检查是否存在当天数据
      if (clockDataMap.containsKey(dateString)) {
        final dailyData = DailyClockData.fromJson(clockDataMap[dateString]);
        // 添加到打卡数据
        newClockData[date] = dailyData.clockStatus;
      }
      // 如果不存在，保持为空，表示未打卡
    }

    // 使用setState更新状态，传入新的映射引用
    setState(() {
      clockData = newClockData;
    });
  }
  // 计算当月总加班时长
  Future<double> _calculateTotalOvertimeHours() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final lastDay = DateTime(currentYear, currentMonth + 1, 0).day;

    double totalOvertime = 0.0;
    // 从数据结构加载
    final clockDataJson = prefs.getString('clock_data');
    Map<String, dynamic> clockDataMap = {};
    if (clockDataJson != null) {
      clockDataMap = jsonDecode(clockDataJson);
    }
    // 循环计算当月每一天的加班时长
    for (int day = 1; day <= lastDay; day++) {
      final date = DateTime(currentYear, currentMonth, day);
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      // 检查是否存在当天数据
      if (clockDataMap.containsKey(dateString)) {
        final dailyData = DailyClockData.fromJson(clockDataMap[dateString]);
        // 如果有下班打卡时间，则计算加班时长
        if (dailyData.clockOutTime != null) {
          totalOvertime += _calculateOvertimeHours(dailyData.clockOutTime!);
        }
      }
    }
    return totalOvertime;
  }

  void _showEditDialog(BuildContext context, DateTime date, {
    DailyClockData? data,
    ClockStatus? status,
  }) {
    final defaultInTime = DateTime(date.year, date.month, date.day, 9, 0);
    final defaultOutTime = DateTime(date.year, date.month, date.day, 18, 0);

    final inController = TextEditingController(
      text: data?.clockInTime != null
          ? DateFormat('HH:mm:ss').format(data!.clockInTime!)
          : DateFormat('HH:mm:ss').format(defaultInTime),
    );

    final outController = TextEditingController(
      text: data?.clockOutTime != null
          ? DateFormat('HH:mm:ss').format(data!.clockOutTime!)
          : DateFormat('HH:mm:ss').format(defaultOutTime),
    );

    Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
      final initialTime = TimeOfDay.now();
      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );

      if (picked != null) {
        final selected = DateTime(date.year, date.month, date.day, picked.hour, picked.minute);
        final formatted = DateFormat('HH:mm:ss').format(selected);
        controller.text = formatted;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(DateFormat('yyyy-MM-dd').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: inController,
              readOnly: true,
              onTap: () => _selectTime(context, inController),
              decoration: const InputDecoration(
                labelText: '上班时间',
                suffixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: outController,
              readOnly: true,
              onTap: () => _selectTime(context, outController),
              decoration: const InputDecoration(
                labelText: '下班时间',
                suffixIcon: Icon(Icons.access_time),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                DateTime? newIn;
                DateTime? newOut;

                if (inController.text.isNotEmpty) {
                  final parts = inController.text.split(':');
                  newIn = DateTime(date.year, date.month, date.day,
                      int.parse(parts[0]), int.parse(parts[1]));
                }
                if (outController.text.isNotEmpty) {
                  final parts = outController.text.split(':');
                  newOut = DateTime(date.year, date.month, date.day,
                      int.parse(parts[0]), int.parse(parts[1]));
                }

                if (newIn != null && newOut != null && !newOut.isAfter(newIn)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('下班时间必须晚于上班时间')),
                  );
                  return;
                }

                if (newIn != null) {
                  await _markAsClockedForDate(date, true, customClockTime: newIn);
                }

                if (newOut != null) {
                  if (newIn == null && data?.clockInTime == null) {
                    final defaultIn = DateTime(date.year, date.month, date.day, 9, 0);
                    await _markAsClockedForDate(date, true, customClockTime: defaultIn);
                  }
                  await _markAsClockedForDate(date, false, customClockTime: newOut);
                }

                Navigator.pop(context);
              } catch (e) {
                print('保存失败: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存失败，请检查时间格式')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClockCalendar(
              clockData: clockData,
              cellSize: cellSize,
              cellSpacing: 4.0,
              borderRadius: borderRadius,
              verticalLayout: verticalLayout,
              onTap: (date) async {
                // 只允许查看今天和之前的日期
                if (date.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('只能查看今天和之前日期的打卡记录')),
                  );
                  return;
                }

                final status = clockData[date];
                final prefs = await SharedPreferences.getInstance();
                final clockDataJson = prefs.getString('clock_data');
                DailyClockData? dailyData;

                if (clockDataJson != null) {
                  final clockDataMap = jsonDecode(clockDataJson);
                  final dateString = DateFormat('yyyy-MM-dd').format(date);
                  if (clockDataMap.containsKey(dateString)) {
                    dailyData = DailyClockData.fromJson(clockDataMap[dateString]);
                  }
                }

                _showEditDialog(context, date, status: status, data: dailyData);
              },
            ),
            const SizedBox(height: 10.0),
            TechCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                [
                  const Text('当月加班统计', style: subtitleStyle),
                  const SizedBox(height: 10),
                  FutureBuilder<double>(
                    future: _calculateTotalOvertimeHours(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('加载中...', style: bodyStyle);
                      } else if (snapshot.hasError) {
                        return const Text('计算失败', style: bodyStyle);
                      } else {
                        final totalOvertime = snapshot.data ?? 0.0;
                        return Text(
                          '总加班时长: ${totalOvertime.toStringAsFixed(1)}小时',
                          style: const TextStyle(
                            fontSize: 16,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('加班计算规则: 从18:30开始计算，按半小时维度统计', style: bodyStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}