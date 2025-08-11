import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Clickable.dart';
import '../core/formx.dart';
import 'formx_field_text.dart';

/// 手机号码输入的表单组件
///
/// * @author xbaistack
/// * @source B站/抖音/小红书/公众号（@小白栈记）
class FormXFieldTextMobile extends FormXFieldText<String> {
  /// 倒计时时间（秒）
  final int? countdown;

  /// 开始倒计时的回调通知
  final VoidCallback? onStartCountdown;

  FormXFieldTextMobile({
    super.key,
    required super.name,
    required super.label,
    super.restorationId,
    super.defaultValue,
    super.debug,
    super.enabled,
    super.required,
    super.onSaved,
    super.onReset,
    super.onChanged,
    super.validator,
    super.renderer,
    super.converter,
    super.transformer,
    // FormXFieldDecoration
    super.empty,
    super.placeholder,
    super.left,
    super.leftIcon,
    super.background,
    super.textStyle,
    super.emptyTextStyle,
    super.labelTextStyle,
    super.errorTextStyle,
    super.subtitleTextStyle,
    super.descriptionTextStyle,
    // FormXFieldText
    super.showClear,
    super.maxLength,
    super.focusNode,
    super.textAlign,
    super.inputAction,
    super.controller,
    super.maxLengthEnforcement,
    super.onTap,
    super.onClear,
    super.onEditingComplete,
    super.onSubmitted,
    // FormXFieldTextMobile
    this.countdown,
    this.onStartCountdown,
  }) : super(
          showCounter: false,
          inputType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );

  /// 计时器
  Timer? _timer;

  /// 计数器
  int _counter = -1;

  /// 启动倒计时
  /// - @param [field] 组件状态 State 对象
  void _startCountdown(
      FormXFieldState<FormXFieldText<String>, String, String> field) {
    _counter = countdown ?? 60;
    _timer?.cancel();
    
    // 发送验证码操作
    // 1）你可以直接在这里去发送网络请求；
    // 2）你可以通过 onStartCountdown 回调在外部去发送这个网络请求；
    onStartCountdown?.call();
    // api.sendSms(field.rawValue);
    
    // 创建定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter-- <= 0) timer.cancel();
      field.rebuild();
    });
    
    // 首次刷新页面
    field.rebuild();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
  }

  @override
  EdgeInsets ofBoxPadding(
      FormXFieldState<FormXFieldText<String>, String, String> field) {
    return field.enabled ? insets(top: 0, bottom: 0) : insets();
  }

  @override
  void ofItems(
    List<Widget> items,
    FormXFieldState<FormXFieldText<String>, String, String> field,
  ) {
    // 重用父类（文本组件）的实现逻辑
    super.ofItems(items, field);
    if (field.readOnly) return;
    
  // 右侧的 “发送验证码” 文字标签
    Widget label;
    if (_counter >= 0) {
      label = _ofText("重发（$_counter秒）", Colors.grey);
    } else {
      label = Clickable(
        onTap: () => _startCountdown(field),
        child: _ofText("发送验证码", Colors.blueAccent),
      );
    }

    // 添加文字标签到组件末尾
    items.add(Container(
      padding: EdgeInsets.only(left: padding),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: label,
    ));
  }

  Widget _ofText(String text, Color color) {
    return Text(text, style: textStyle?.copyWith(color: color));
  }
}