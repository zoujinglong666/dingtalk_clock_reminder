import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // 初始化通知插件
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        
    await _notificationsPlugin.initialize(initializationSettings);
  }
  
  Future<void> requestPermission() async {
    // 请求通知权限
    await Permission.notification.request();
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'dingtalk_clock_reminder',
      '钉钉打卡提醒',
      channelDescription: '钉钉打卡提醒通知',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
        
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
  
  Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
  }) async {
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
        
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}