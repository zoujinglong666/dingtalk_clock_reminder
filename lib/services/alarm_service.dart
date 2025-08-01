import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/holidays.dart';

class AlarmService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // 初始化闹钟管理器
    await AndroidAlarmManager.initialize();
  }
  
  Future<void> scheduleAlarm(int id, DateTime time) async {
    // 设置每天重复的闹钟
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      id,
      _alarmCallback,
      wakeup: true,
      exact: true,
      startAt: DateTime.now().add(Duration(
        hours: time.hour - DateTime.now().hour,
        minutes: time.minute - DateTime.now().minute,
      )),
    );
  }
  
  Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
  
  Future<void> cancelAllAlarms() async {
    await AndroidAlarmManager.initialize();
  }
  
  // 检查今天是否应该发送提醒
  static Future<bool> shouldSendReminderToday() async {
    final now = DateTime.now();
    
    // 检查是否是节假日
    if (Holidays.isHoliday(now)) {
      return false;
    }
    
    // 检查是否是周末
    final prefs = await SharedPreferences.getInstance();
    final skipWeekends = prefs.getBool('skipWeekends') ?? true;
    
    if (skipWeekends && (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday)) {
      return false;
    }
    
    return true;
  }
}

// 闹钟回调函数
void _alarmCallback() async {
  // 检查今天是否应该发送提醒
  if (!await AlarmService.shouldSendReminderToday()) {
    return;
  }
  
  // 发送通知提醒用户打卡
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'dingtalk_clock_reminder_reminder',
    '钉钉打卡提醒',
    channelDescription: '钉钉打卡提醒通知',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    // 添加按钮
    actions: [
      AndroidNotificationAction('open_dingtalk', '打开钉钉'),
      AndroidNotificationAction('mark_clocked', '我已打卡'),
    ],
  );
  
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);
      
  notificationsPlugin.show(
    0,
    '钉钉打卡提醒',
    '请记得打卡哦！',
    notificationDetails,
  );
}