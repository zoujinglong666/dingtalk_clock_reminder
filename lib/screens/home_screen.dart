import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clock_record.dart';
import '../models/daily_clock_data.dart';
import '../services/alarm_service.dart';
import '../services/background_task_service.dart';
import '../services/dingtalk_service.dart';
import '../services/notification_service.dart';
import '../widgets/date_picker/date_picker.dart';


// 钉钉风格颜色主题
const Color primaryColor = Color(0xFF1677FF); // 钉钉蓝色
const Color secondaryColor = Color(0xFF4080FF);
const Color backgroundColor = Color(0xFFFFFFFF); // 白色背景
const Color cardColor = Color(0xFFF5F7FA);
const Color textColor = Color(0xFF333333);
const Color lightTextColor = Color(0xFF86909C);
const Color accentColor = Color(0xFF00B42A);
const Color successColor = Color(0xFF00B42A);
const Color errorColor = Color(0xFFF53F3F);
const Color borderColor = Color(0xFFE5E6EB);

// 自定义文本样式
const TextStyle titleStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: textColor,
);

const TextStyle subtitleStyle = TextStyle(
  fontSize: 16,
  color: textColor,
  fontWeight: FontWeight.w500,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 14,
  color: textColor,
);

const TextStyle clockStyle = TextStyle(
  fontSize: 42,
  fontWeight: FontWeight.bold,
  color: primaryColor,
  letterSpacing: 1.5,
);

const TextStyle smallTextStyle = TextStyle(
  fontSize: 12,
  color: lightTextColor,
);


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _currentTime = DateTime.now();
  late Timer _timer;
  final NotificationService _notificationService = NotificationService();
  final AlarmService _alarmService = AlarmService();
  final DingtalkService _dingtalkService = DingtalkService();
  final List<ClockRecord> _clockRecords = [];
  List<DateTime> _alarmTimes = [];
  bool _isDingtalkInstalled = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // 初始化定时器，每秒更新时间并检查打卡状态
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _currentTime = DateTime.now();
      });

      // 检查是否正好是18:00，确保及时更新下班打卡状态
      if (_currentTime.hour == 18 && _currentTime.minute == 0 && _currentTime.second == 0) {
        await _loadClockStatus();
      }

      // 每60秒重新加载一次打卡状态，确保状态与时间匹配
      else if (_currentTime.second == 0) {
        await _loadClockStatus();
      }
    });
  }

  Future<void> _initializeApp() async {
    // 初始化通知服务
    await _notificationService.initialize();

    // 请求必要权限
    await _requestPermissions();

    // 检查钉钉是否安装
    bool installed = await _dingtalkService.isDingtalkInstalled();
    setState(() {
      _isDingtalkInstalled = installed;
    });



    // 加载闹钟时间
    await _loadAlarmTimes();

    // 启动前台服务
    await _startForegroundService();

    // 设置闹钟
    await _scheduleAlarms();
  }

  Future<void> _requestPermissions() async {
    // 请求通知权限
    await _notificationService.requestPermission();

    // 请求闹钟权限
    await Permission.scheduleExactAlarm.request();

    // 请求前台服务权限
    await Permission.systemAlertWindow.request();
  }

  // 打卡状态
  bool _hasClockedIn = false; // 是否已上班打卡
  DateTime? _lastClockInTime; // 最后一次上班打卡时间
  DateTime? _lastClockOutTime; // 最后一次下班打卡时间
  bool _isLate = false; // 是否迟到
  bool _isEarlyLeave = false; // 是否早退

  Future<void> _loadAlarmTimes() async {
    // 根据今天的日期设置上下班时间
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 9, 0);  // 上班
    final todayEnd = DateTime(now.year, now.month, now.day, 18, 0);   // 下班
    setState(() {
      _alarmTimes = [todayStart, todayEnd];
    });
    // 加载打卡状态
    await _loadClockStatus();
  }


  Future<void> _loadClockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // 加载今天的打卡状态
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // 从新的数据结构加载
    final clockDataJson = prefs.getString('clock_data');
    Map<String, dynamic> clockDataMap = {};
    if (clockDataJson != null) {
      clockDataMap = jsonDecode(clockDataJson);
    }
    
    setState(() {
      if (clockDataMap.containsKey(today)) {
        final dailyData = DailyClockData.fromJson(clockDataMap[today]);
        _hasClockedIn = dailyData.hasClockedIn;
        _lastClockInTime = dailyData.clockInTime;
        _lastClockOutTime = dailyData.clockOutTime;
        _isLate = dailyData.isLate;
        _isEarlyLeave = dailyData.isEarlyLeave;
      } else {
        // 不存在当天数据
        _hasClockedIn = false;
        _lastClockInTime = null;
        _lastClockOutTime = null;
        _isLate = false;
        _isEarlyLeave = false;
      }
    });
  }

  Future<void> _scheduleAlarms() async {
    for (int i = 0; i < _alarmTimes.length; i++) {
      await _alarmService.scheduleAlarm(i, _alarmTimes[i]);
    }
  }

  // 显示下班补卡时间选择器
  Future<void> _showClockOutOptions() async {
    final initialTime = const TimeOfDay(hour: 18, minute: 0);

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
      final clockTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      await _markAsClockedOut(clockTime);
    }
  }

  // 下班补卡实现
  Future<void> _markAsClockedOut(DateTime clockTime) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 获取现有的打卡数据
    final clockDataJson = prefs.getString('clock_data');
    Map<String, dynamic> clockDataMap = {};
    if (clockDataJson != null) {
      clockDataMap = jsonDecode(clockDataJson);
    }

    DailyClockData dailyData;
    if (clockDataMap.containsKey(today)) {
      // 已存在当天数据，更新下班打卡时间
      final existingData = DailyClockData.fromJson(clockDataMap[today]);
      if (existingData.hasClockedIn) {
        // 已经上班打卡，直接更新下班时间
        dailyData = DailyClockData.clockedIn(
          date: today,
          clockInTime: existingData.clockInTime!,
          clockOutTime: clockTime,
        );
      } else {
        // 没有上班打卡记录，先创建上班打卡记录（默认9:00）
        dailyData = DailyClockData.clockedIn(
          date: today,
          clockInTime: DateTime.now().copyWith(hour: 9, minute: 0),
          clockOutTime: clockTime,
        );
      }
    } else {
      // 不存在当天数据，创建新数据（包括默认上班打卡）
      dailyData = DailyClockData.clockedIn(
        date: today,
        clockInTime: DateTime.now().copyWith(hour: 9, minute: 0),
        clockOutTime: clockTime,
      );
    }

    // 更新数据
    clockDataMap[today] = dailyData.toJson();

    // 保存回SharedPreferences
    prefs.setString('clock_data', jsonEncode(clockDataMap));

    // 更新UI
    setState(() {
      _lastClockOutTime = clockTime;
      _isEarlyLeave = clockTime.hour < 18 || (clockTime.hour == 18 && clockTime.minute < 0);
    });

    // 显示补卡成功通知
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('下班补卡成功'),
      ),
    );
  }

  Future<void> _startForegroundService() async {
    // 初始化前台任务
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service',
        channelDescription: '钉钉打卡提醒前台服务',
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
        eventAction: ForegroundTaskEventAction.once(),
      ),
    );

    // 使用 BackgroundTaskService 启动前台任务
    BackgroundTaskService.startBackgroundTask();
  }


  void _showEditClockTimeDialog(BuildContext context, ClockType type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 加载 clockData
    final clockDataJson = prefs.getString('clock_data');
    Map<String, dynamic> clockDataMap = {};
    if (clockDataJson != null) {
      clockDataMap = jsonDecode(clockDataJson);
    }

    if (clockDataMap.containsKey(today)) {
      final dailyData = DailyClockData.fromJson(clockDataMap[today]);
      _hasClockedIn = dailyData.hasClockedIn;
      _lastClockInTime = dailyData.clockInTime;
      _lastClockOutTime = dailyData.clockOutTime;
      _isLate = dailyData.isLate;
      _isEarlyLeave = dailyData.isEarlyLeave;
    }

    final DateTime? initialDateTime =
    type == ClockType.clockIn ? _lastClockInTime : _lastClockOutTime ??
        DateTime.now();

    final String title = type == ClockType.clockIn
        ? "编辑上班打卡时间"
        : "编辑下班打卡时间";

    AppDatePicker.show(
      context: context,
      mode: AppDatePickerMode.editTime,
      title: title,
      initialDateTime: initialDateTime,
      onConfirm: (picked) async {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        setState(() {
          DateTime selectedTime;
          if (picked is Map<String, int>) {
            selectedTime = DateTime(
              todayDate.year,
              todayDate.month,
              todayDate.day,
              picked['hour'] ?? 0,
              picked['minute'] ?? 0,
            );
          } else if (picked is DateTime) {
            selectedTime = DateTime(
              todayDate.year,
              todayDate.month,
              todayDate.day,
              picked.hour,
              picked.minute,
            );
          } else {
            print("⚠️ 未知返回类型: $picked");
            return;
          }

          if (type == ClockType.clockIn) {
            _lastClockInTime = selectedTime;
          } else {
            _lastClockOutTime = selectedTime;
          }

          // 判断迟到（> 9:01）
          final lateThreshold = DateTime(
              todayDate.year, todayDate.month, todayDate.day, 9, 1);
          _isLate = _lastClockInTime != null &&
              _lastClockInTime!.isAfter(lateThreshold);

          // 判断早退（< 18:00）
          final earlyLeaveThreshold = DateTime(
              todayDate.year, todayDate.month, todayDate.day, 18, 0);
          _isEarlyLeave =
              _lastClockOutTime != null &&
                  _lastClockOutTime!.isBefore(earlyLeaveThreshold);
        });

        final updatedDailyData = DailyClockData(
          date: today,
          hasClockedIn: _lastClockInTime != null,
          clockInTime: _lastClockInTime,
          clockOutTime: _lastClockOutTime,
          isLate: _isLate,
          isEarlyLeave: _isEarlyLeave,
        );

        clockDataMap[today] = updatedDailyData.toJson();
        await prefs.setString('clock_data', jsonEncode(clockDataMap));

        print("✅ ${type == ClockType.clockIn
            ? "上班"
            : "下班"}时间已保存: ${type == ClockType.clockIn
            ? _lastClockInTime
            : _lastClockOutTime}");
        print("⏰ 是否迟到: $_isLate, 是否早退: $_isEarlyLeave");
      },
    );
  }



  @override
  void dispose() {
    _timer.cancel(); // 取消定时器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: const BackButton(color: textColor),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 打卡状态卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 上班打卡
                  Expanded(
                      child: InkWell(
                        onTap: () {
                          _showEditClockTimeDialog(context, ClockType.clockIn);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('上班09:00', style: bodyStyle),
                            const SizedBox(height: 4),
                            Row(

                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _hasClockedIn ? Icons.check_circle : Icons
                                      .circle_outlined,
                                  color: _hasClockedIn
                                      ? successColor
                                      : borderColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                  [
                                    Text(
                                      _hasClockedIn
                                          ? '${_lastClockInTime!.hour.toString()
                                          .padLeft(2, '0')}:${_lastClockInTime!
                                          .minute.toString().padLeft(
                                          2, '0')}已打卡'
                                          : '未打卡',
                                      style: TextStyle(
                                        color: _hasClockedIn
                                            ? successColor
                                            : lightTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (_hasClockedIn && _isLate)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: errorColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              2),
                                        ),
                                        child: const Text(
                                          '迟到',
                                          style: TextStyle(
                                            color: errorColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                  ),
                  const VerticalDivider(
                    color: borderColor,
                    width: 1,
                    thickness: 1,
                  ),
                  // 下班打卡
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // 打卡
                        _showEditClockTimeDialog(context, ClockType.clockOut);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('下班18:00', style: bodyStyle),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _lastClockOutTime != null
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: _lastClockOutTime != null
                                    ? successColor
                                    : borderColor,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                [
                                  GestureDetector(
                                    child: Text(
                                      _lastClockOutTime != null
                                          ? '${_lastClockOutTime!.hour
                                          .toString().padLeft(
                                          2, '0')}:${_lastClockOutTime!.minute
                                          .toString().padLeft(2, '0')}已打卡'
                                          : '未打卡',
                                      style: TextStyle(
                                        color: _hasClockedIn
                                            ? successColor
                                            : lightTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (_lastClockOutTime != null &&
                                      _isEarlyLeave)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDD6B20)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Text(
                                        '早退',
                                        style: TextStyle(
                                          color: Color(0xFFDD6B20),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 大型打卡按钮
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (_hasClockedIn) {
                        _markAsClocked(isClockIn: false);
                      } else {
                        _markAsClocked(isClockIn: true);
                      }
                      if (_isDingtalkInstalled) {
                        await _dingtalkService.openClockInPage();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('未检测到钉钉应用，请先安装钉钉'),
                          ),
                        );
                        await _dingtalkService.installDingtalk();
                      }
                    },
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _hasClockedIn
                                ? '下班打卡'
                                : '上班打卡',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                        DateFormat('HH:mm:ss').format(_currentTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 标记打卡
  Future<void> _markAsClocked({required bool isClockIn}) async {
    if (isClockIn && _hasClockedIn) {
      await _notificationService.showNotification(
        id: 0,
        title: '提示',
        body: '您今天已经完成上班打卡',
      );
      return;
    }

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final todayDate = DateTime(now.year, now.month, now.day);
    final prefs = await SharedPreferences.getInstance();

    final clockDataJson = prefs.getString('clock_data');
    Map<String, dynamic> clockDataMap = {};
    if (clockDataJson != null) {
      clockDataMap = jsonDecode(clockDataJson);
    }

    DailyClockData dailyData;
    DateTime? clockInTime;
    DateTime? clockOutTime;
    bool isLate = false;
    bool isEarlyLeave = false;

    if (isClockIn) {
      clockInTime = now;
      // 判断是否迟到（> 9:01）
      final lateThreshold = DateTime(todayDate.year, todayDate.month, todayDate.day, 9, 1);
      isLate = clockInTime.isAfter(lateThreshold);

      dailyData = DailyClockData(
        date: today,
        hasClockedIn: true,
        clockInTime: clockInTime,
        isLate: isLate, isEarlyLeave: false,
      );
    } else {
      clockOutTime = now;

      if (clockDataMap.containsKey(today)) {
        final existingData = DailyClockData.fromJson(clockDataMap[today]);
        clockInTime = existingData.clockInTime;
        isLate = existingData.isLate;

        // 判断是否早退（< 18:00）
        final earlyThreshold = DateTime(todayDate.year, todayDate.month, todayDate.day, 18, 0);
        isEarlyLeave = clockOutTime.isBefore(earlyThreshold);

        dailyData = DailyClockData(
          date: today,
          hasClockedIn: clockInTime != null,
          clockInTime: clockInTime,
          clockOutTime: clockOutTime,
          isLate: isLate,
          isEarlyLeave: isEarlyLeave,
        );
      } else {
        // 异常情况：下班打卡但没有上班记录
        clockInTime = now.subtract(const Duration(hours: 9));
        final lateThreshold = DateTime(todayDate.year, todayDate.month, todayDate.day, 9, 1);
        isLate = clockInTime.isAfter(lateThreshold);

        final earlyThreshold = DateTime(todayDate.year, todayDate.month, todayDate.day, 18, 0);
        isEarlyLeave = clockOutTime.isBefore(earlyThreshold);

        dailyData = DailyClockData(
          date: today,
          hasClockedIn: true,
          clockInTime: clockInTime,
          clockOutTime: clockOutTime,
          isLate: isLate,
          isEarlyLeave: isEarlyLeave,
        );
      }
    }

    // 更新本地数据
    clockDataMap[today] = dailyData.toJson();
    await prefs.setString('clock_data', jsonEncode(clockDataMap));

    // 更新 UI 状态
    setState(() {
      if (isClockIn) {
        _hasClockedIn = true;
        _lastClockInTime = clockInTime;
        _isLate = isLate;
      } else {
        _lastClockOutTime = clockOutTime;
        _isEarlyLeave = isEarlyLeave;
      }

      _clockRecords.add(ClockRecord(
        id: now.millisecondsSinceEpoch,
        time: now,
        status: ClockStatus.success,
        type: isClockIn ? ClockType.clockIn : ClockType.clockOut,
      ));
    });

    // 通知用户
    await _notificationService.showNotification(
      id: 0,
      title: isClockIn ? '上班打卡成功' : '下班打卡成功',
      body: '您已在 ${now.hour}:${now.minute.toString().padLeft(2, '0')} 完成${isClockIn ? '上班' : '下班'}打卡',
    );
  }

}