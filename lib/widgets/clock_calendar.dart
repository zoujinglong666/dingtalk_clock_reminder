import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tech_widgets.dart';
import '../models/clock_status.dart'; // 导入ClockStatus类

/// 打卡日历组件
class ClockCalendar extends StatefulWidget {
  // 数据参数
  final Map<DateTime, ClockStatus> clockData; // 日期 -> 打卡状态

  // 样式参数
  final double cellSize; // 单元格大小
  final double cellSpacing; // 单元格间距
  final double borderRadius; // 单元格圆角半径
  final Color defaultColor; // 默认颜色(无打卡)
  final Color fullAttendanceColor; // 全勤颜色(绿色)
  final Color lateColor; // 迟到颜色(红色)
  final Color earlyLeaveColor; // 早退颜色(橙色)
  final Color lateAndEarlyLeaveColor; // 迟到+早退颜色(紫色)
  final bool verticalLayout; // 是否垂直布局

  // 回调函数
  final Function(DateTime)? onTap; // 点击回调
  final Function(DateTime)? onLongPress; // 长按回调

  const ClockCalendar({
    super.key,
    required this.clockData,
    this.cellSize = 24.0,
    this.cellSpacing = 4.0,
    this.borderRadius = 4.0,
    this.defaultColor = const Color(0xFFEBEDF0),
    this.fullAttendanceColor = const Color(0xFF1A936F),
    this.lateColor = const Color(0xFFE53E3E),
    this.earlyLeaveColor = const Color(0xFFDD6B20),
    this.lateAndEarlyLeaveColor = const Color(0xFFC026D3),
    this.verticalLayout = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  _ClockCalendarState createState() => _ClockCalendarState();
}

class _ClockCalendarState extends State<ClockCalendar> {
  // 获取当前日期
  DateTime currentDate = DateTime.now();
  List<Widget> monthWidgets = [];

  @override
  void initState() {
    super.initState();
    _generateCalendarWidgets();
  }

  @override
  void didUpdateWidget(ClockCalendar oldWidget) {
    if (oldWidget.clockData != widget.clockData ||
        oldWidget.cellSize != widget.cellSize ||
        oldWidget.verticalLayout != widget.verticalLayout) {
      _generateCalendarWidgets();
    }
    super.didUpdateWidget(oldWidget);
  }

  // 生成日历组件
  void _generateCalendarWidgets() {
    monthWidgets = [];
    // 只生成当前月份的日历
    monthWidgets.add(_buildMonthCalendar(currentDate.month));
    setState(() {});
  }

  // 构建单个月份的日历
  Widget _buildMonthCalendar(int month) {
    // 获取月份的第一天是星期几
    final firstDay = DateTime(currentDate.year, month, 1);
    final lastDay = DateTime(currentDate.year, month + 1, 0);
    final firstDayOfWeek = firstDay.weekday; // 1-7, Monday is 1
    final daysInMonth = lastDay.day;
    // 计算需要多少行
    final rows = ((firstDayOfWeek - 1) + daysInMonth) / 7;
    final totalRows = rows.ceil();
    // 生成日期网格
    List<Widget> cells = [];

    // 填充前导空白
    for (int i = 1; i < firstDayOfWeek; i++) {
      cells.add(_buildEmptyCell());
    }

    // 填充日期单元格
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentDate.year, month, day);
      cells.add(_buildDateCell(date));
    }

    // 月份标题
    final monthTitle = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        DateFormat('MMMM yyyy', 'zh_CN').format(DateTime(currentDate.year, month)),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    // 星期标题
    final weekTitles = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final weekday = (index + 1) % 7; // 0-6, Monday is 0
        return Flexible(
          fit: FlexFit.loose,
          child: Center(
            child: Text(
              ['一', '二', '三', '四', '五', '六', '日'][weekday],
              style: const TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );

    // 日期网格
    final dateGrid = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: widget.cellSpacing,
      crossAxisSpacing: widget.cellSpacing,
      childAspectRatio: 1.0,
      children: cells,
    );
    // 组合月份日历
    return TechCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          monthTitle,
          weekTitles,
          const SizedBox(height: 8.0),
          dateGrid,
        ],
      ),
    );
  }

  // 构建空白单元格
  Widget _buildEmptyCell() {
    return Container(
      width: widget.cellSize,
      height: widget.cellSize,
      decoration: BoxDecoration(
        color: widget.defaultColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }

  // 构建日期单元格
  Widget _buildDateCell(DateTime date) {
    // 检查是否有打卡数据
    final clockStatus = widget.clockData[date];
    // 确定颜色
    Color cellColor = widget.defaultColor;
    if (clockStatus != null) {
      if (clockStatus.isFullAttendance) {
        cellColor = widget.fullAttendanceColor; // 全勤(绿色)
      } else if (clockStatus.isLate && clockStatus.isEarlyLeave) {
        cellColor = widget.lateAndEarlyLeaveColor; // 迟到+早退(紫色)
      } else if (clockStatus.isLate) {
        cellColor = widget.lateColor; // 迟到(红色)
      } else if (clockStatus.isEarlyLeave) {
        cellColor = widget.earlyLeaveColor; // 早退(橙色)
      }
    }

    return GestureDetector(
      onTap: () => widget.onTap?.call(date),
      onLongPress: () => widget.onLongPress?.call(date),
      child: Container(
        width: widget.cellSize,
        height: widget.cellSize,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        // 显示日期(可选)
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 12,
              color: clockStatus != null ? Colors.white : textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.verticalLayout
        ? SingleChildScrollView(
            child: Column(children: monthWidgets),
          )
        : Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: monthWidgets,
                  ),
                ),
              ),
            ],
          );
  }
}