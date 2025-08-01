import 'package:flutter/material.dart';

class AlarmTime {
  final int id;
  final TimeOfDay time;
  final bool enabled;
  
  AlarmTime({
    required this.id,
    required this.time,
    required this.enabled,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'enabled': enabled,
    };
  }
  
  factory AlarmTime.fromJson(Map<String, dynamic> json) {
    return AlarmTime(
      id: json['id'],
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      enabled: json['enabled'],
    );
  }
}