import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DingtalkService {
  static const String DINGTALK_PACKAGE_NAME = 'com.alibaba.android.rimet';
  static const MethodChannel _channel = const MethodChannel('dingtalk_service');
  
  Future<bool> isDingtalkInstalled() async {
    try {
      bool isInstalled = await _channel.invokeMethod('isAppInstalled', {'packageName': DINGTALK_PACKAGE_NAME});
      return isInstalled;
    } on PlatformException catch (e) {
      print("Error checking if Dingtalk is installed: ${e.message}");
      return false;
    }
  }
  
  Future<void> openDingtalk() async {
    try {
      await _channel.invokeMethod('openApp', {'packageName': DINGTALK_PACKAGE_NAME});
    } on PlatformException catch (e) {
      print("Error opening Dingtalk: ${e.message}");
      // 如果无法直接打开，尝试通过 URL Scheme 打开
      final Uri dingtalkUri = Uri(scheme: 'dingtalk', host: '');
      if (await canLaunchUrl(dingtalkUri)) {
        await launchUrl(dingtalkUri);
      }
    }
  }
  
  Future<void> installDingtalk() async {
    // 跳转到应用市场下载钉钉
    final Uri marketUri = Uri(
      scheme: 'market',
      host: 'details',
      queryParameters: {'id': DINGTALK_PACKAGE_NAME},
    );
    
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri);
    } else {
      // 如果无法打开应用市场，跳转到钉钉官网
      final Uri websiteUri = Uri.parse('https://www.dingtalk.com/download');
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri);
      }
    }
  }
  
  // 尝试跳转到打卡页面（可能不总是有效）
  Future<void> openClockInPage() async {
    // 这是一个尝试性的实现，实际效果可能因钉钉版本而异
    // 尝试使用不同的URI格式跳转到钉钉打卡页面
    final Uri clockInUri = Uri(
      scheme: 'dingtalk',
      host: 'dingtalkclient',
      path: '/checkin',
    );

    if (await canLaunchUrl(clockInUri)) {
      await launchUrl(clockInUri);
    } else {
      // 如果 URI Scheme 无效，则直接打开钉钉
      await openDingtalk();
    }

  }
}