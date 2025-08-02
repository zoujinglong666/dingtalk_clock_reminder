import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _setupNotificationChannels();
  }

  Future<void> _setupNotificationChannels() async {
    // 加载用户提醒设置以获取当前音量
    final settings = await _loadReminderSettings();
    final double volume = settings['volume'];

    // 创建主要通知渠道
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'dingtalk_clock_reminder',
      '钉钉打卡提醒',
      description: '钉钉打卡提醒通知',
      importance: Importance.max,
    );

    // 创建提醒通知渠道
    final AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'dingtalk_clock_reminder_reminder',
      '钉钉打卡提醒',
      description: '钉钉打卡提醒通知',
      importance: Importance.max,
    );

    // 注册通知渠道
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      await androidImplementation.createNotificationChannel(reminderChannel);
    }
  }

  // 更新通知渠道音量
  Future<void> updateNotificationVolume(double volume) async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      // 更新主要通知渠道
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'dingtalk_clock_reminder',
          '钉钉打卡提醒',
          description: '钉钉打卡提醒通知',
          importance: Importance.max,
        ),
      );

      // 更新提醒通知渠道
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          'dingtalk_clock_reminder_reminder',
          '钉钉打卡提醒',
          description: '钉钉打卡提醒通知',
          importance: Importance.max,
        ),
      );
    }
  }

  // 加载用户提醒设置
  Future<Map<String, dynamic>> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enableSound': prefs.getBool('enableSound') ?? true,
      'enableVibration': prefs.getBool('enableVibration') ?? true,
      'selectedRingtone': prefs.getString('selectedRingtone') ?? '默认铃声',
      'volume': prefs.getDouble('reminderVolume') ?? 1.0,
    };
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
    // 加载用户提醒设置
    final settings = await _loadReminderSettings();
    
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'dingtalk_clock_reminder',
      '钉钉打卡提醒',
      channelDescription: '钉钉打卡提醒通知',
      importance: Importance.max,
      playSound: settings['enableSound'],
      enableVibration: settings['enableVibration'],
      enableLights: true,
      // 根据选择的铃声设置声音
      sound: settings['enableSound'] 
          ? RawResourceAndroidNotificationSound(settings['selectedRingtone'])
          : null,
    );
    
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
        
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
  
  Future<void> showReminderNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 加载用户提醒设置
    final settings = await _loadReminderSettings();
    
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'dingtalk_clock_reminder_reminder',
      '钉钉打卡提醒',
      channelDescription: '钉钉打卡提醒通知',
      importance: Importance.max,
      playSound: settings['enableSound'],
      enableVibration: settings['enableVibration'],
      enableLights: true,
      // 根据选择的铃声设置声音
      sound: settings['enableSound'] 
          ? RawResourceAndroidNotificationSound(settings['selectedRingtone'])
          : null,
      // 添加按钮
      actions: [
        AndroidNotificationAction('open_dingtalk', '打开钉钉'),
        AndroidNotificationAction('mark_clocked', '我已打卡'),
      ],
    );
    
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
        
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}