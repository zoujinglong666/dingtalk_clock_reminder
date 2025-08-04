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
    final day = DateTime.parse(date);
    final workStartTime = DateTime(day.year, day.month, day.day, 9, 0, 59);
    // 判断是否迟到（9:00:59后）
    // 严格判定：大于9:00:59才算迟到
    final isLate = clockInTime.isAfter(workStartTime);

    // 判断是否早退（18:00前）
    bool isEarlyLeave = false;
    if (clockOutTime != null) {
      final workEndTime = DateTime(day.year, day.month, day.day, 18, 0);
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



  DailyClockData copyWith({
    String? date,
    bool? hasClockedIn,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    bool? isLate,
    bool? isEarlyLeave,
  }) {
    return DailyClockData(
      date: date ?? this.date,
      hasClockedIn: hasClockedIn ?? this.hasClockedIn,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      isLate: isLate ?? this.isLate,
      isEarlyLeave: isEarlyLeave ?? this.isEarlyLeave,
    );
  }
  static bool checkIsLate(String date, DateTime clockInTime) {
    final day = DateTime.parse(date);
    final threshold = DateTime(day.year, day.month, day.day, 9, 0, 59);
    return clockInTime.isAfter(threshold);
  }

  static bool checkIsEarlyLeave(String date, DateTime clockOutTime) {
    final day = DateTime.parse(date);
    final threshold = DateTime(day.year, day.month, day.day, 18, 0);
    return clockOutTime.isBefore(threshold);
  }
  DailyClockData updateStatus() {
    return DailyClockData(
      date: date,
      hasClockedIn: hasClockedIn,
      clockInTime: clockInTime,
      clockOutTime: clockOutTime,
      isLate: clockInTime != null ? DailyClockData.checkIsLate(date, clockInTime!) : false,
      isEarlyLeave: clockOutTime != null ? DailyClockData.checkIsEarlyLeave(date, clockOutTime!) : false,
    );
  }

}