import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../services/dingtalk_service.dart';
import '../services/background_task_service.dart';
import '../models/clock_record.dart';

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
  bool _isBluetoothConnected = true; // 蓝牙连接状态
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

    // 加载打卡记录
    await _loadClockRecords();

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

  Future<void> _loadClockRecords() async {
    final prefs = await SharedPreferences.getInstance();
    // 简化实现，实际项目中需要更复杂的序列化/反序列化
    setState(() {
      // _clockRecords = ...;
    });
  }

  // 打卡状态
  bool _hasClockedIn = false; // 是否已上班打卡
  DateTime? _lastClockInTime; // 最后一次上班打卡时间
  DateTime? _lastClockOutTime; // 最后一次下班打卡时间

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
    setState(() {
      _hasClockedIn = prefs.getBool('clock_in_$today') ?? false;
      final lastClockInStr = prefs.getString('clock_in_time_$today');
      _lastClockInTime = lastClockInStr != null
          ? DateTime.parse(lastClockInStr)
          : null;
      final lastClockOutStr = prefs.getString('clock_out_$today');
      _lastClockOutTime = lastClockOutStr != null
          ? DateTime.parse(lastClockOutStr)
          : null;
    });
  }

  Future<void> _scheduleAlarms() async {
    for (int i = 0; i < _alarmTimes.length; i++) {
      await _alarmService.scheduleAlarm(i, _alarmTimes[i]);
    }
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('上班09:00', style: bodyStyle),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasClockedIn ? Icons.check_circle : Icons.circle_outlined,
                              color: _hasClockedIn ? successColor : borderColor,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _hasClockedIn
                                  ? '${_lastClockInTime!.hour.toString().padLeft(2, '0')}:${_lastClockInTime!.minute.toString().padLeft(2, '0')}已打卡'
                                  : '未打卡',
                              style: TextStyle(
                                color: _hasClockedIn ? successColor : lightTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    color: borderColor,
                    width: 1,
                    thickness: 1,
                  ),
                  // 下班打卡
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('下班18:00', style: bodyStyle),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _lastClockOutTime != null ? Icons.check_circle : Icons.circle_outlined,
                              color: _lastClockOutTime != null ? successColor : borderColor,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _lastClockOutTime != null
                                  ? '${_lastClockOutTime!.hour.toString().padLeft(2, '0')}:${_lastClockOutTime!.minute.toString().padLeft(2, '0')}已打卡'
                                  : '未打卡',
                              style: TextStyle(
                                color: _lastClockOutTime != null ? successColor : lightTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                    onTap: () {
                      if (_hasClockedIn) {
                        _markAsClocked(isClockIn: false);
                      } else {
                        _markAsClocked(isClockIn: true);
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 200,
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
                  const SizedBox(height: 20),
                  // 蓝牙连接状态
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: _isBluetoothConnected ? primaryColor : lightTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isBluetoothConnected
                            ? '蓝牙已连接'
                            : '蓝牙未连接',
                        style: smallTextStyle,
                      ),
                    ],
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
    // 判断是否是上班打卡且已打卡
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
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (isClockIn) {
        _hasClockedIn = true;
        _lastClockInTime = now;
        prefs.setBool('clock_in_$today', true);
        prefs.setString('clock_in_time_$today', now.toIso8601String());
      } else {
        // 允许随时打下班卡，并覆盖之前的打卡时间
        _lastClockOutTime = now;
        prefs.setString('clock_out_$today', now.toIso8601String());
      }

      // 添加打卡记录
      final record = ClockRecord(
        id: now.millisecondsSinceEpoch,
        time: now,
        status: ClockStatus.success,
        type: isClockIn ? ClockType.clockIn : ClockType.clockOut
      );
      _clockRecords.add(record);
    });

    // 发送通知确认
    await _notificationService.showNotification(
      id: 0,
      title: isClockIn ? '上班打卡成功' : '下班打卡成功',
      body: '您已在 ${now.hour}:${now.minute.toString().padLeft(2, '0')} 完成${isClockIn ? '上班' : '下班'}打卡',
    );
  }
}