import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/tech_widgets.dart';
import '../services/notification_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  _ReminderSettingsScreenState createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  // 颜色常量 - 与其他页面统一
  final Color primaryColor = Color(0xFF1677FF);
  final Color lightTextColor = Color(0xFF86909C);
  final Color borderColor = Color(0xFFE5E6EB);

  // 提醒设置选项
  bool _enableVibration = true;
  bool _enableSound = true;
  String _selectedRingtone = '';
  double _volume = 1.0; // 0.0 到 1.0 之间

  // 通知服务
  final NotificationService _notificationService = NotificationService();

  // 可用铃声列表
  final List<String> _ringtones = [
    'dingdong',
    'soft_music',
    'classic_alarm',
    'natural_sound'
  ];

  // 显示给用户的铃声名称
  final List<String> _ringtoneDisplayNames = [
    '叮咚声',
    '柔和音乐',
    '经典闹钟',
    '自然声音'
  ];

  // 获取铃声显示名称
  String getRingtoneDisplayName(String ringtoneKey) {
    final index = _ringtones.indexOf(ringtoneKey);
    return index != -1 ? _ringtoneDisplayNames[index] : ringtoneKey;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _notificationService.initialize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableVibration = prefs.getBool('enableVibration') ?? true;
      _enableSound = prefs.getBool('enableSound') ?? true;
      _selectedRingtone = prefs.getString('selectedRingtone')??'';
      _volume = prefs.getDouble('reminderVolume') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableVibration', _enableVibration);
    await prefs.setBool('enableSound', _enableSound);
    await prefs.setString('selectedRingtone', _selectedRingtone);
    await prefs.setDouble('reminderVolume', _volume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('提醒方式设置'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  SizedBox(height: 12.0),
                  TechCard(
                    child: SwitchListTile(
                      title: Text('声音提醒'),
                      subtitle: Text('开启或关闭提醒声音'),
                      value: _enableSound,
                      onChanged: (value) {
                        setState(() {
                          _enableSound = value;
                        });
                        _saveSettings();
                      },
                      activeColor: primaryColor,
                    ),
                  ),

                  if (_enableSound) ...[
                    SizedBox(height: 12.0),
                    TechCard(
                      child: ListTile(
                        title: Text('选择铃声'),
                        subtitle: Text(_selectedRingtone),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () => _showRingtonePicker(),
                      ),
                    ),

                    SizedBox(height: 12.0),
                    TechCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('提醒音量', style: TextStyle(fontSize: 16.0)),
                          ),
                          Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: '${(_volume * 100).round()}%',
                            onChanged: (value) {
                        setState(() {
                          _volume = value;
                        });
                        _saveSettings();
                        _notificationService.updateNotificationVolume(value);
                      },
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 12.0),
                  TechCard(
                    child: SwitchListTile(
                      title: Text('震动提醒'),
                      subtitle: Text('开启或关闭提醒震动'),
                      value: _enableVibration,
                      onChanged: (value) {
                        setState(() {
                          _enableVibration = value;
                        });
                        _saveSettings();
                      },
                      activeColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRingtonePicker() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('选择铃声'),
          children: _ringtones.map((ringtone) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ringtone),
              child: ListTile(
                title: Text(getRingtoneDisplayName(ringtone)),
                trailing: ringtone == _selectedRingtone
                    ? Icon(Icons.check, color: primaryColor)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedRingtone = selected;
      });
      _saveSettings();
    }
  }
}