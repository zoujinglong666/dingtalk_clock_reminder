import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../widgets/clock_calendar.dart';
import '../widgets/tech_widgets.dart';
import '../models/clock_status.dart';
import '../models/daily_clock_data.dart';
import 'dart:convert';

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
          content: Text('${isClockIn ? '上班' : '下班'}补卡成功'),
        ),
      );
    }

    // 显示时间选择器
    Future<DateTime?> _showTimePicker(BuildContext context, bool isClockIn) async {
      final initialTime = isClockIn ? 
          const TimeOfDay(hour: 9, minute: 0) : 
          const TimeOfDay(hour: 18, minute: 0);

      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      }
      return null;
    }

    // 同时补卡方法
    Future<void> _markAsClockedInAndOutForDate(DateTime date, DateTime clockInTime, DateTime clockOutTime) async {
      // 先补上班卡
      await _markAsClockedForDate(date, true, customClockTime: clockInTime);
      // 再补下班卡
      await _markAsClockedForDate(date, false, customClockTime: clockOutTime);
    }

    // 补卡选项对话框
    Future<void> _showClockInOptions(DateTime date) async {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('补卡 - ${DateFormat('yyyy-MM-dd').format(date)}'),
         content: const Text('请选择补卡类型'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('取消'),
           ),
           TextButton(
             onPressed: () async {
               Navigator.pop(context);
               final clockTime = await _showTimePicker(context, true);
               if (clockTime != null) {
                 await _markAsClockedForDate(date, true, customClockTime: clockTime);
               }
             },
             child: const Text('上班打卡'),
           ),
           TextButton(
             onPressed: () async {
               Navigator.pop(context);
               final clockTime = await _showTimePicker(context, false);
               if (clockTime != null) {
                 await _markAsClockedForDate(date, false, customClockTime: clockTime);
               }
             },
             child: const Text('下班打卡'),
           ),
           TextButton(
             onPressed: () async {
               Navigator.pop(context);
               final clockInTime = await _showTimePicker(context, true);
               if (clockInTime != null) {
                 final clockOutTime = await _showTimePicker(context, false);
                 if (clockOutTime != null) {
                   // 确保下班时间晚于上班时间
                   if (clockOutTime.isAfter(clockInTime)) {
                     await _markAsClockedInAndOutForDate(date, clockInTime, clockOutTime);
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('下班时间必须晚于上班时间')),
                     );
                   }
                 }
               }
             },
             child: const Text('同时补卡'),
           ),
         ],
       ),
     );
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
                  // 只允许查看今天和之前的日期
                  if (date.isAfter(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('只能查看今天和之前日期的打卡记录')),
                    );
                    return;
                  }

                  final status = clockData[date];
                  String statusText = '未打卡';
                  String clockInTime = '未打卡';
                  String clockOutTime = '未打卡';
                  String overtimeHours = '0小时';

                  if (status != null) {
                    // 获取对应的DailyClockData
                    final prefs = SharedPreferences.getInstance();
                    prefs.then((prefs) {
                      final clockDataJson = prefs.getString('clock_data');
                      if (clockDataJson != null) {
                        final clockDataMap = jsonDecode(clockDataJson);
                        final dateString = DateFormat('yyyy-MM-dd').format(date);
                        if (clockDataMap.containsKey(dateString)) {
                          final dailyData = DailyClockData.fromJson(clockDataMap[dateString]);
                          if (dailyData.hasClockedIn) {
                            clockInTime = DateFormat('HH:mm:ss').format(dailyData.clockInTime!);
                          }
                          if (dailyData.clockOutTime != null) {
                            clockOutTime = DateFormat('HH:mm:ss').format(dailyData.clockOutTime!);
                            // 计算加班时长
                            final overtime = _calculateOvertimeHours(dailyData.clockOutTime!);
                            overtimeHours = '${overtime.toStringAsFixed(1)}小时';
                          }

                          // 更新状态文本
                          if (status.isFullAttendance) {
                            statusText = '全勤(无迟到早退)';
                          } else if (status.isLate && status.isEarlyLeave) {
                            statusText = '迟到+早退';
                          } else if (status.isLate) {
                            statusText = '迟到';
                          } else if (status.isEarlyLeave) {
                            statusText = '早退';
                          }

                          // 显示弹窗
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(DateFormat('yyyy-MM-dd').format(date)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('打卡状态: $statusText'),
                                  const SizedBox(height: 8),
                                  Text('上班时间: $clockInTime'),
                                  const SizedBox(height: 8),
                                  Text('下班时间: $clockOutTime'),
                                  const SizedBox(height: 8),
                                  Text('加班时长: $overtimeHours'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    });
                  } else {
                    // 未打卡情况，显示补卡选项
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(DateFormat('yyyy-MM-dd').format(date)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('打卡状态: $statusText'),
                            const SizedBox(height: 8),
                            Text('上班时间: $clockInTime'),
                            const SizedBox(height: 8),
                            Text('下班时间: $clockOutTime'),
                            const SizedBox(height: 8),
                            Text('加班时长: $overtimeHours'),
                            const SizedBox(height: 16),
                            const Text('该日期未打卡，是否进行补卡？'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _showClockInOptions(date);
                            },
                            child: const Text('补卡'),
                          ),
                        ],
                      ),
                    );
                  }
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
            // 加班统计
            const SizedBox(height: 16),
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