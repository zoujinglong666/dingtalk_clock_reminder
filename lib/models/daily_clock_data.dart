import 'package:intl/intl.dart';
import 'clock_status.dart';

class DailyClockData {
  final String date; // 日期格式: yyyy-MM-dd
  final bool hasClockedIn; // 是否已打卡
  final DateTime? clockInTime; // 打卡时间
  final DateTime? clockOutTime; // 下班打卡时间
  final bool isLate; // 是否迟到
  final bool isEarlyLeave; // 是否早退

  DailyClockData({
    required this.date,
    required this.hasClockedIn,
    this.clockInTime,
    this.clockOutTime,
    required this.isLate,
    required this.isEarlyLeave,
  });

  // 从JSON创建DailyClockData
  factory DailyClockData.fromJson(Map<String, dynamic> json) {
    return DailyClockData(
      date: json['date'],
      hasClockedIn: json['hasClockedIn'],
      clockInTime: json['clockInTime'] != null ? DateTime.parse(json['clockInTime']) : null,
      clockOutTime: json['clockOutTime'] != null ? DateTime.parse(json['clockOutTime']) : null,
      isLate: json['isLate'],
      isEarlyLeave: json['isEarlyLeave'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'hasClockedIn': hasClockedIn,
      'clockInTime': clockInTime?.toIso8601String(),
      'clockOutTime': clockOutTime?.toIso8601String(),
      'isLate': isLate,
      'isEarlyLeave': isEarlyLeave,
    };
  }

  // 获取打卡状态
  ClockStatus get clockStatus {
    return ClockStatus(isLate: isLate, isEarlyLeave: isEarlyLeave);
  }

  // 创建一个新的DailyClockData实例，表示未打卡
  factory DailyClockData.unclocked(String date) {
    return DailyClockData(
      date: date,
      hasClockedIn: false,
      clockInTime: null,
      clockOutTime: null,
      isLate: false,
      isEarlyLeave: false,
    );
  }

  // 创建一个新的DailyClockData实例，表示已打卡
  factory DailyClockData.clockedIn({
    required String date,
    required DateTime clockInTime,
    DateTime? clockOutTime,
  }) {
    // 判断是否迟到（9:00:59后）
    final workStartTime = DateTime.parse(date).copyWith(hour: 9, minute: 0, second: 59);
    // 严格判定：大于9:00:59才算迟到
    final isLate = clockInTime.isAfter(workStartTime);

    // 判断是否早退（18:00前）
    bool isEarlyLeave = false;
    if (clockOutTime != null) {
      final workEndTime = DateTime.parse(date).copyWith(hour: 18, minute: 0);
      // 严格判定：小于18:00才算早退
      isEarlyLeave = clockOutTime.isBefore(workEndTime);
    }

    return DailyClockData(
      date: date,
      hasClockedIn: true,
      clockInTime: clockInTime,
      clockOutTime: clockOutTime,
      isLate: isLate,
      isEarlyLeave: isEarlyLeave,
    );
  }
}