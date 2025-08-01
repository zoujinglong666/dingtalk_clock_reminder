class ClockRecord {
  final int id;
  final DateTime time;
  final ClockStatus status;
  
  ClockRecord({
    required this.id,
    required this.time,
    required this.status,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'status': status.index,
    };
  }
  
  factory ClockRecord.fromJson(Map<String, dynamic> json) {
    return ClockRecord(
      id: json['id'],
      time: DateTime.parse(json['time']),
      status: ClockStatus.values[json['status']],
    );
  }
}

enum ClockStatus {
  success,
  failed,
  pending,
}