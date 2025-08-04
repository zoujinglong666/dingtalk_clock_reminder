import 'package:bot_toast/bot_toast.dart';
import 'package:dingtalk_clock_reminder/screens/index_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化日期格式化的区域数据
  await initializeDateFormatting('zh_CN');
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
final botToastBuilder = BotToastInit();
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
      builder: (context, child) {
        child = botToastBuilder(context, child);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      home: const MainNavigation(),
    );
  }
}

// 全局颜色常量
const Color primaryColor = Color(0xFF1677FF); // 钉钉蓝色
const Color lightTextColor = Color(0xFF86909C);
const Color backgroundColor = Color(0xFFFFFFFF); // 白色背景

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const IndexPage(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: '打卡',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextColor,
        backgroundColor: backgroundColor,
        elevation: 1,
      ),
    );
  }
}
