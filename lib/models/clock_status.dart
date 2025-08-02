class ClockStatus {
  final bool isLate; // 是否迟到
  final bool isEarlyLeave; // 是否早退

  ClockStatus({required this.isLate, required this.isEarlyLeave});
  // 判断是否全勤(没迟到且没早退)
  bool get isFullAttendance => !isLate && !isEarlyLeave;
}