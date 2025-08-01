import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_time.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableForegroundService = true;
  bool _skipHolidays = true;
  bool _skipWeekends = true;
  bool _remindInSilentMode = false;
  List<AlarmTime> _alarmTimes = [];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 通知栏常驻开关
            SwitchListTile(
              title: Text('通知栏常驻'),
              subtitle: Text('在通知栏显示常驻提醒'),
              value: _enableForegroundService,
              onChanged: (value) {
                setState(() {
                  _enableForegroundService = value;
                });
                _saveSettings();
              },
            ),
            
            Divider(),
            
            // 节假日跳过开关
            SwitchListTile(
              title: Text('节假日跳过'),
              subtitle: Text('在节假日不提醒打卡'),
              value: _skipHolidays,
              onChanged: (value) {
                setState(() {
                  _skipHolidays = value;
                });
                _saveSettings();
              },
            ),
            
            Divider(),
            
            // 周末跳过开关
            SwitchListTile(
              title: Text('周末跳过'),
              subtitle: Text('在周末不提醒打卡'),
              value: _skipWeekends,
              onChanged: (value) {
                setState(() {
                  _skipWeekends = value;
                });
                _saveSettings();
              },
            ),
            
            Divider(),
            
            // 静音模式提醒开关
            SwitchListTile(
              title: Text('静音模式提醒'),
              subtitle: Text('在静音模式下仍然提醒'),
              value: _remindInSilentMode,
              onChanged: (value) {
                setState(() {
                  _remindInSilentMode = value;
                });
                _saveSettings();
              },
            ),
            
            Divider(),
            
            // 打卡时间设置
            ListTile(
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
            
            Divider(),
            
            // 提醒方式设置
            ListTile(
              title: Text('提醒方式'),
              subtitle: Text('设置提醒铃声和震动'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 跳转到提醒方式设置页面
              },
            ),
          ],
        ),
      ),
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
          return ListTile(
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
            ),
            onTap: () => _selectTime(index),
          );
        },
      ),
    );
  }
}