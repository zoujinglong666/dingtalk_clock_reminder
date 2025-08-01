import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:isolate';

import '../data/holidays.dart';

class BackgroundTaskService {
  static void startBackgroundTask() {
    FlutterForegroundTask.startService(
      notificationTitle: '钉钉打卡提醒',
      notificationText: '服务正在运行中',
      callback: _backgroundTaskCallback,
    );
  }

  static void stopBackgroundTask() {
    FlutterForegroundTask.stopService();
  }

  static void _backgroundTaskCallback() {
    FlutterForegroundTask.setTaskHandler(_TaskHandler());
  }
}

class _TaskHandler extends TaskHandler {
  int _eventCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('后台任务已启动: $timestamp');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    _eventCount++;
    print('后台任务执行 ($_eventCount): $timestamp');

    await _checkAndSendReminder();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('后台任务已销毁: $timestamp，是否超时：$isTimeout');
  }

  @override
  void onButtonPressed(String id) {
    print('通知按钮被点击: $id');
    // 可通过 sendPort 向主 isolate 发送事件
  }

  Future<void> _checkAndSendReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final workStartTime = DateTime(now.year, now.month, now.day, 8, 50);
    final workEndTime = DateTime(now.year, now.month, now.day, 17, 50);

    if (!_isWorkday(now)) return;

    final reminderTimeStart = workStartTime.subtract(Duration(minutes: 10));
    final reminderTimeEnd = workEndTime.subtract(Duration(minutes: 10));

    if (now.isAfter(reminderTimeStart) && now.isBefore(workStartTime)) {
      print("即将上班，发送提醒...");
      // TODO: 调用通知逻辑
    } else if (now.isAfter(reminderTimeEnd) && now.isBefore(workEndTime)) {
      print("即将下班，发送提醒...");
      // TODO: 调用通知逻辑
    }
  }

  bool _isWorkday(DateTime date) {
    if (Holidays.isHoliday(date)) return false;
    return date.weekday >= 1 && date.weekday <= 5;
  }
  @override
  void onRepeatEvent(DateTime timestamp) {
    // 你可以在这里添加周期性逻辑
  }

}
