
class ClockRecord {
  final int id;
  final DateTime time;
  final ClockStatus status;
  final ClockType type;
  
  ClockRecord({
    required this.id,
    required this.time,
    required this.status,
    required this.type,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'status': status.index,
      'type': type.index,
    };
  }
  
  factory ClockRecord.fromJson(Map<String, dynamic> json) {
    return ClockRecord(
      id: json['id'],
      time: DateTime.parse(json['time']),
      status: ClockStatus.values[json['status']],
      type: ClockType.values[json['type']],
    );
  }
}

enum ClockStatus {
  success,
  failed,
  pending,
}

enum ClockType {
  clockIn,
  clockOut,
}