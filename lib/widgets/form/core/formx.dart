import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../common/helper.dart';
import '../../../consts/index.dart';
import 'formx_validator.dart';
part 'formx_field.dart'; // 碎片文件

const Duration _kIOSAnnouncementDelayDuration = Duration(seconds: 1);

/// 字段值转换器，用于将给定的 [IN] 转换成 [OUT]
typedef FieldTransformer<IN, OUT> = OUT? Function(IN value);

class FormX extends StatefulWidget {
  /// 表单子组件
  final Widget child;

  /// 是否开启调试模式（默认：false）
  final bool debug;

  /// 是否启用表单（默认：true，设置为 false 表示查看模式）
  final bool enabled;

  /// 是否开启边输入边校验功能（默认：false）
  final bool validateOnInput;

  /// 是否显示错误信息（默认：false 你需要自己去处理错误展示）
  final bool showErrors;

  /// 表单初始值
  final Map<String, dynamic> initialValue;

  /// 表单组件值发生变更时会回调此函数
  final VoidCallback? onChanged;

  /// 表单页面被关闭是会触发此回调
  /// 老版本使用的是：[WillPopCallback]，以下是新版本中的使用方式；
  final PopInvokedWithResultCallback<Map<String, dynamic>>? onWillPop;

  const FormX({
    super.key,
    required this.child,
    this.debug = false,
    this.enabled = true,
    this.validateOnInput = false,
    this.showErrors = false,
    this.initialValue = const <String, dynamic>{},
    this.onChanged,
    this.onWillPop,
  });

  /// 通过 [context] 向上查找第一个满足 [FormXState] 的 [State] 对象
  static FormXState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<FormXState>();
  }

  @override
  State<StatefulWidget> createState() => FormXState();
}

class FormXState extends State<FormX> {
  /// 用于维护所有表单字段
  final Map<String, FormXFieldState> _fields = {};

  /// 用于存放临时表单值，表单内部流转
  final Map<String, dynamic> _formValues = {};

  /// 用于存放保存后的表单值，可直接用于提交给服务端
  final Map<String, dynamic> _savedValues = {};

  /// 最后一次访问的组件
  FormXFieldState? lastField;

  /// 是否开启调试模式
  bool get debug => widget.debug;

  /// 是否启用表单
  bool get enabled => widget.enabled;

  /// 当前是否是只读模式（查看模式）
  bool get readOnly => !enabled;

  /// 是否启用了边输入边校验
  bool get validateOnInput => widget.validateOnInput;

  /// 是否在页面上展示错误信息
  bool get showErrors => widget.showErrors;

  /// 返回表单中维护的所有字段
  Map<String, FormXFieldState> get fields => Map.unmodifiable(_fields);

  /// 通过指定的字段名获取某个组件对象
  FormXFieldState? getField(String name) => _fields[name];

  /// 用于获取表单保存的临时值
  Map<String, dynamic> get formValue => Map.unmodifiable(_formValues);

  /// 用于获取表单的值（可直接用于提交给服务器）但最好配合 [validate] 校验后再获取
  Map<String, dynamic> get value {
    if (debug) {
      debugPrint("# FromX -> Starts saving ...");
    }
    _fields.forEach((name, field) => field.save());
    return Map.unmodifiable(_savedValues);
  }

  /// 用于获取通过 [validate] 方法校验后的所有错误信息
  /// 如果不想在 UI 中集中展示错误信息，可用此方法获取错误信息后自定义展示。
  Map<String, String> get errors {
    final errorMap = <String, String>{};
    final entries = fields.entries.where((e) => e.value.hasError);
    for (var entry in entries) {
      errorMap[entry.key] = entry.value.errorText!;
    }
    return errorMap;
  }

  /// 用于设置表单的初始值，此方式设置的值无法被重置，如需要设置初始值并重置请使用 [widget.initialValue] 设置。
  set initialValue(Map<String, dynamic> values) {
    if (Helper.isNotEmpty(values)) {
      values.forEach((name, value) {
        _fields[name]?.setValue(value, refresh: true);
      });
    }
  }

  /// 通过指定的字段名获取组件的值（转换后的值）
  dynamic getValue(String name) => _fields[name]?.value;

  /// 通过指定的字段名获取组件的原始值（内部流转的值）
  dynamic getRawValue(String name) => _fields[name]?.rawValue;

  /// 通过指定的字段名获取组件初始值（或者说是默认值）
  dynamic getInitialValue(String name) => widget.initialValue[name];

  /// 通过指定的字段名获取表单的保存值（必须要校验了才会有值）
  dynamic getSavedValue(String name) => _savedValues[name];

  /// 清除上一个组件的焦点（组件需要重写 [unfocus] 方法）
  void clearAnyFocus() => lastField?.unfocus();

  /// 设置某个组件的值
  void setValue<T>(String name, T? value) {
    if (value != null) {
      _fields[name]?.setValue(value, refresh: true);
    }
  }

  /// 校验表单数据
  bool validate() {
    if (readOnly) return false;
    if (debug) {
      debugPrint("## FormX -> Start validating ...");
    }
    _forceRebuild();
    return _validate();
  }

  /// 重置表单
  void reset() {
    if (readOnly) return;
    if (debug) {
      debugPrint("## FormX -> The form is reset.");
    }
    _fields.forEach((name, field) => field.reset());
    _notifyChange();
    _forceRebuild();
  }

  /// 强制重构表单组件（限内部使用）
  /// Consts.doNothing == () {}
  void _forceRebuild() => setState(Consts.doNothing);

  /// 通知表单组件内部发生值变更（限内部使用）
  void _notifyChange() => widget.onChanged?.call();

  /// 保存组件的值（转换后的值）
  void _saveValue(String name, dynamic value) => _savedValues[name] = value;

  /// 保存表单的临时值
  void _setValue(String name, dynamic value) => _formValues[name] = value;

  /// 注册表单组件到当前类，有表单统一维护
  void _register(String name, FormXFieldState field) {
    if (debug) {
      if (_fields[name] != null) {
        debugPrint("## FormX -> Warn! $name is re-registered.");
      }
    }
    _fields[name] = field;
    field.setValue(field.initialValue);
  }

  /// 解绑表单组件
  void _unregister(String name, FormXFieldState field) {
    if (_fields.containsKey(name) && _fields[name] != field) {
      _fields.remove(name);
      _savedValues.remove(name);
      _formValues.remove(name);
    }
  }

  /// 内部校验整个表单
  bool _validate() {
    bool hasError = false;
    String errorMessage = "";
    _fields.forEach((name, field) {
      hasError = !field.validate() || hasError;
      errorMessage += (field.errorText ?? "");
    });
    // 以下源自系统表单的实现（复制过来的）
    // 主要是用于在 IOS 平台之上提供一种无障碍访问方式
    if (errorMessage.isNotEmpty) {
      final TextDirection directionality = Directionality.of(context);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        unawaited(Future<void>(() async {
          await Future<void>.delayed(_kIOSAnnouncementDelayDuration);
          SemanticsService.announce(
            errorMessage,
            directionality,
            assertiveness: Assertiveness.assertive,
          );
        }));
      } else {
        SemanticsService.announce(
          errorMessage,
          directionality,
          assertiveness: Assertiveness.assertive,
        );
      }
    }
    return !hasError;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: widget.onWillPop,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: widget.child,
      ),
    );
  }
}