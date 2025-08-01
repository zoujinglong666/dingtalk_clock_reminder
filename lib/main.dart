import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'screens/home_screen.dart';
void main()  {
  WidgetsFlutterBinding.ensureInitialized();
   FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'dingtalk_reminder_channel',
      channelName: '钉钉打卡提醒',
      channelDescription: '用于显示钉钉打卡提醒的通知',
      priority: NotificationPriority.LOW,


    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
     autoRunOnBoot: true,
     allowWakeLock: true,
     allowWifiLock: true,
     eventAction: ForegroundTaskEventAction.repeat(1000),
   ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '钉钉打卡提醒',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
