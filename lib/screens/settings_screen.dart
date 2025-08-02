import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dingtalk_clock_reminder/models/alarm_time.dart';
import 'package:dingtalk_clock_reminder/widgets/tech_widgets.dart';
import 'package:dingtalk_clock_reminder/screens/reminder_settings_screen.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableForegroundService = true;
  bool _skipHolidays = true;
  bool _skipWeekends = true;
  bool _remindInSilentMode = false;
  List<AlarmTime> _alarmTimes = [];

  // 颜色常量 - 与首页统一
  final Color primaryColor = Color(0xFF1677FF); // 与首页相同的蓝色
  final Color lightTextColor = Color(0xFF86909C);
  final Color borderColor = Color(0xFFE5E6EB);

  // 文本样式 - 与首页统一
  final TextStyle smallTextStyle = TextStyle(
    fontSize: 12.0,
    color: Color(0xFF757575),
  );

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      // 根据设置状态启动或停止前台服务
      if (_enableForegroundService) {
        _startForegroundService();
      } else {
        _stopForegroundService();
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _enableForegroundService = prefs.getBool('enableForegroundService') ?? true;
      _skipHolidays = prefs.getBool('skipHolidays') ?? true;
      _skipWeekends = prefs.getBool('skipWeekends') ?? true;
      _remindInSilentMode = prefs.getBool('remindInSilentMode') ?? false;

      // 默认设置两个闹钟时间
      _alarmTimes = [
        AlarmTime(id: 0, time: TimeOfDay(hour: 8, minute: 50), enabled: true),
        AlarmTime(id: 1, time: TimeOfDay(hour: 17, minute: 50), enabled: true),
      ];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableForegroundService', _enableForegroundService);
    await prefs.setBool('skipHolidays', _skipHolidays);
    await prefs.setBool('skipWeekends', _skipWeekends);
    await prefs.setBool('remindInSilentMode', _remindInSilentMode);
  }

  // 启动前台服务
  void _startForegroundService() async {
    await FlutterForegroundTask.startService(
      notificationTitle: '钉钉打卡提醒',
      notificationText: '服务正在运行中',
      notificationIcon: '@mipmap/ic_launcher',
    );
  }

  // 停止前台服务
  void _stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // 增加边距
        child: Column(
          children: [
            // 设置选项 - 使用TechCard包装，与首页风格统一
            Expanded(
              child: ListView(
                children: [
                  SizedBox(height: 12.0), // 添加卡片间距
                  TechCard(
                    child: SwitchListTile(
                      title: Text('通知栏常驻'),
                      subtitle: Text('在通知栏显示常驻提醒'),
                      value: _enableForegroundService,
                      onChanged: (value) {
                        setState(() {
                          _enableForegroundService = value;
                        });
                        _saveSettings();
                        if (value) {
                          _startForegroundService();
                        } else {
                          _stopForegroundService();
                        }
                      },
                      activeColor: primaryColor,
                    ),
                  ),

                  SizedBox(height: 12.0), // 添加项目间距
                  TechCard(
                    child: SwitchListTile(
                      title: Text('节假日跳过'),
                      subtitle: Text('在节假日不提醒打卡'),
                      value: _skipHolidays,
                      onChanged: (value) {
                        setState(() {
                          _skipHolidays = value;
                        });
                        _saveSettings();
                      },
                      activeColor: primaryColor,
                    ),
                  ),

                  SizedBox(height: 12.0), // 添加项目间距
                  TechCard(
                    child: SwitchListTile(
                      title: Text('周末跳过'),
                      subtitle: Text('在周末不提醒打卡'),
                      value: _skipWeekends,
                      onChanged: (value) {
                        setState(() {
                          _skipWeekends = value;
                        });
                        _saveSettings();
                      },
                      activeColor: primaryColor,
                    ),
                  ),

                  SizedBox(height: 12.0), // 添加项目间距
                  TechCard(
                    child: SwitchListTile(
                      title: Text('静音模式提醒'),
                      subtitle: Text('在静音模式下仍然提醒'),
                      value: _remindInSilentMode,
                      onChanged: (value) {
                        setState(() {
                          _remindInSilentMode = value;
                        });
                        _saveSettings();
                      },
                      activeColor: primaryColor,
                    ),
                  ),

                  SizedBox(height: 12.0), // 添加项目间距
                  TechCard(
                    child: ListTile(
                      title: Text('打卡时间设置'),
                      subtitle: Text('设置上班和下班提醒时间'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => AlarmTimesSettingsScreen(
                              alarmTimes: _alarmTimes,
                              onAlarmTimesChanged: (newAlarmTimes) {
                                setState(() {
                                  _alarmTimes = newAlarmTimes;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 12.0), // 添加项目间距
                  TechCard(
                    child: ListTile(
                      title: Text('提醒方式'),
                      subtitle: Text('设置提醒铃声和震动'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => ReminderSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // 底部导航栏已移至main.dart中实现
      
    );
  }
}

class AlarmTimesSettingsScreen extends StatefulWidget {
  final List<AlarmTime> alarmTimes;
  final Function(List<AlarmTime>) onAlarmTimesChanged;

  AlarmTimesSettingsScreen({
    required this.alarmTimes,
    required this.onAlarmTimesChanged,
  });

  @override
  _AlarmTimesSettingsScreenState createState() => _AlarmTimesSettingsScreenState();
}

class _AlarmTimesSettingsScreenState extends State<AlarmTimesSettingsScreen> {
  late List<AlarmTime> _alarmTimes;
  final Color primaryColor = Color(0xFF1677FF); // 与首页相同的蓝色

  @override
  void initState() {
    super.initState();
    _alarmTimes = List.from(widget.alarmTimes);
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTimes[index].time,
    );

    if (picked != null && picked != _alarmTimes[index].time) {
      setState(() {
        _alarmTimes[index] = AlarmTime(
          id: _alarmTimes[index].id,
          time: picked,
          enabled: _alarmTimes[index].enabled,
        );
      });
      widget.onAlarmTimesChanged(_alarmTimes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('打卡时间设置'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // 添加新的闹钟时间
              setState(() {
                _alarmTimes.add(
                  AlarmTime(
                    id: _alarmTimes.length,
                    time: TimeOfDay(hour: 9, minute: 0),
                    enabled: true,
                  ),
                );
              });
              widget.onAlarmTimesChanged(_alarmTimes);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _alarmTimes.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(
                '提醒时间 ${index + 1}',
              ),
              subtitle: Text(
                '${_alarmTimes[index].time.hour}:${_alarmTimes[index].time.minute.toString().padLeft(2, '0')}',
              ),
              trailing: Switch(
                value: _alarmTimes[index].enabled,
                onChanged: (value) {
                  setState(() {
                    _alarmTimes[index] = AlarmTime(
                      id: _alarmTimes[index].id,
                      time: _alarmTimes[index].time,
                      enabled: value,
                    );
                  });
                  widget.onAlarmTimesChanged(_alarmTimes);
                },
                activeColor: primaryColor,
              ),
              onTap: () => _selectTime(index),
            ),
          );
        },
      ),
    );
  }
}