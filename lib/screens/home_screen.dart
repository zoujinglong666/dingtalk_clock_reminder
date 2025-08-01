import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../services/dingtalk_service.dart';
import '../services/background_task_service.dart';
import '../models/clock_record.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final AlarmService _alarmService = AlarmService();
  final DingtalkService _dingtalkService = DingtalkService();
  
  bool _isDingtalkInstalled = false;
  List<ClockRecord> _clockRecords = [];
  List<DateTime> _alarmTimes = [];
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
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
  
  Future<void> _loadAlarmTimes() async {
    final prefs = await SharedPreferences.getInstance();
    // 默认设置两个闹钟时间：上班时间 08:50 和下班时间 17:50
    setState(() {
      _alarmTimes = [
        DateTime(2024, 1, 1, 8, 50),
        DateTime(2024, 1, 1, 17, 50),
      ];
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('钉钉打卡提醒'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 钉钉状态
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '钉钉状态',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isDingtalkInstalled ? Icons.check_circle : Icons.error,
                          color: _isDingtalkInstalled ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isDingtalkInstalled ? '已安装' : '未安装',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: _isDingtalkInstalled 
                            ? _dingtalkService.openDingtalk 
                            : _dingtalkService.installDingtalk,
                          child: Text(_isDingtalkInstalled ? '打开钉钉' : '下载钉钉'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 下次打卡时间
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '下次打卡时间',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _alarmTimes.isNotEmpty 
                        ? '${_alarmTimes[0].hour}:${_alarmTimes[0].minute.toString().padLeft(2, '0')}'
                        : '未设置',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // 本周打卡记录
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本周打卡记录',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    // 简化显示，实际项目中可以使用 ListView 或其他更好的方式展示
                    Text('暂无记录'),
                  ],
                ),
              ),
            ),
            
            Spacer(),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _dingtalkService.openDingtalk,
                  icon: Icon(Icons.open_in_new),
                  label: Text('打开钉钉'),
                ),
                ElevatedButton.icon(
                  onPressed: _markAsClocked,
                  icon: Icon(Icons.check),
                  label: Text('我已打卡'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _markAsClocked() async {
    // 记录打卡
    final now = DateTime.now();
    final record = ClockRecord(id: DateTime.now().millisecondsSinceEpoch, time: now, status: ClockStatus.success);
    
    setState(() {
      _clockRecords.add(record);
    });
    
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    // 简化实现，实际项目中需要更复杂的序列化
    
    // 发送通知确认
    await _notificationService.showNotification(
      id: 0,
      title: '打卡成功',
      body: '您已在 ${now.hour}:${now.minute.toString().padLeft(2, '0')} 完成打卡',
    );
  }
}