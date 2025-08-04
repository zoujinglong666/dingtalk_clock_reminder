import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/formx.dart';
import 'core/formx_validator.dart';
import 'fields/formx_field_text.dart';
import 'formx_widget.dart';


/// 自定义构建器
typedef InputBuilder = Widget Function(
    BuildContext context, // 上下文构建对象
    FormInput parent, // 父表单组件
    int index, // 当前被渲染的循环下标
    );

/// 表单核心组件类，使用方式如下：
/// ```dart
/// // 通用化组件
/// Input.spacer(); // 构建一个空白组件
/// Input.leading(...); // 表单分组标签
/// Input.customize(...); // 自定义（直接传 Widget）
/// Input.builder(...); // 自定义（可以使用组件内部的配置参数）
///
/// // 输入类组件
/// Input.text(...); // 普通文本输入
/// Input.textarea(...); // 文本域
/// ```

class Input<T> {
  /// 直接定义组件内容
  final Widget? child;

  /// 通过回调函数的方式去构建组件内容
  final InputBuilder? builder;

  /// 调试标签
  final Object? debugLabel;

  /// 动态显示控制，仅在 [enabled] 为 [true] 的场景下显示。
  final bool showOnEnabled;

  /// 动态显示控制，仅在 [enabled] 为 [false] 的场景下显示。
  final bool hideOnDisabled;

  const Input({
    this.child,
    this.builder,
    this.debugLabel,
    bool? showOnEnabled,
    bool? hideOnDisabled,
  })  : showOnEnabled = showOnEnabled ?? true,
        hideOnDisabled = hideOnDisabled ?? false;

  @override
  String toString() {
    return debugLabel == null
        ? super.toString()
        : "$runtimeType -> <$debugLabel>";
  }

  /// 核心构建方法
  /// 构建顺序：child → builder → const SizedBox.shrink()
  Widget build(BuildContext context, FormInput parent, int index) {
    return child ??
        builder?.call(context, parent, index) ??
        const SizedBox.shrink();
  }

  /// 用于生成上下相邻的表单组件之间的空白
  /// 可用于在视觉上进行区分
  factory Input.spacer({
    double height = 12,
    bool? showOnEnabled,
    bool? hideOnDisabled,
  }) {
    return Input(
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
      debugLabel: "Spacer($height)",
      child: SizedBox(height: height),
    );
  }

  /// 通过 [InputBuilder] 回调的方式构建自定义组件内容
  factory Input.builder({
    required InputBuilder builder,
    bool? showOnEnabled,
    bool? hideOnDisabled,
  }) {
    return Input(
      builder: builder,
      debugLabel: "Builder",
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
    );
  }

  /// 通过直接传入 [Widget] 的方式构建自定义组件内容
  factory Input.customize({
    required Widget child,
    bool? showOnEnabled,
    bool? hideOnDisabled,
  }) {
    return Input(
      child: child,
      debugLabel: "Customize($child)",
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
    );
  }

  /// 用于构建表单视觉分组的标签文本
  factory Input.leading(
      String text, {
        bool? showOnEnabled,
        bool? hideOnDisabled,
      }) {
    return Input(
      debugLabel: "Leading($text)",
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
      builder: (ctx, parent, index) => Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: index == 0 ? 5 : 12,
          bottom: 5,
        ),
        child: Text(
          text,
          style: parent.descriptionTextStyle,
        ),
      ),
    );
  }

  /// 用于构建文本表单组件
  factory Input.text({
    Key? key,
    required String name,
    required String label,
    String? restorationId,
    String? defaultValue,
    String? placeholder,
    bool? debug,
    bool? enabled,
    bool required = false,
    bool showClear = true,
    bool showCounter = true,
    bool? showOnEnabled,
    bool? hideOnDisabled,
    int? maxLength,
    Widget? left,
    Icon? leftIcon,
    FocusNode? focusNode,
    TextAlign textAlign = TextAlign.start,
    TextInputType? inputType,
    TextInputAction? inputAction,
    TextEditingController? controller,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    VoidCallback? onClear,
    ValueChanged<String?>? onSaved,
    ValueChanged<String?>? onReset,
    ValueChanged<String?>? onChanged,
    ValueChanged<String?>? onSubmitted,
    VoidCallback? onEditingComplete,
    List<Validator<String>>? validator,
    FieldTransformer<String, String>? renderer,
    FieldTransformer<String, String>? converter,
    FieldTransformer<String, String>? transformer,
  }) {
    return Input(
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
      debugLabel: "FormXFieldText($name)",
      builder: (ctx, parent, index) => FormXFieldText(
        key: key,
        name: name,
        label: label,
        left: left,
        leftIcon: leftIcon,
        empty: parent.empty,
        defaultValue: defaultValue,
        placeholder: placeholder,
        debug: debug ?? parent.debug,
        required: required,
        enabled: enabled ?? parent.enabled,
        restorationId: restorationId,
        showClear: showClear,
        showCounter: showCounter,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        focusNode: focusNode,
        textAlign: textAlign,
        inputAction: inputAction,
        inputType: inputType,
        inputFormatters: inputFormatters,
        controller: controller,
        validator: validator,
        renderer: renderer,
        converter: converter,
        transformer: transformer,
        background: parent.background,
        textStyle: parent.textStyle,
        emptyTextStyle: parent.emptyTextStyle,
        subtitleTextStyle: parent.subtitleTextStyle,
        labelTextStyle: parent.labelTextStyle,
        errorTextStyle: parent.errorTextStyle,
        descriptionTextStyle: parent.descriptionTextStyle,
        onTap: onTap,
        onSaved: onSaved,
        onReset: onReset,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
      ),
    );
  }

  /// 用于构建密码表单输入组件
  factory Input.password({
    Key? key,
    required String name,
    required String label,
    String? restorationId,
    String? placeholder,
    bool? debug,
    bool? enabled,
    bool required = false,
    bool showClear = true,
    bool? showOnEnabled,
    bool? hideOnDisabled,
    int? maxLength,
    Widget? left,
    Icon? leftIcon,
    FocusNode? focusNode,
    TextAlign textAlign = TextAlign.start,
    TextInputType? inputType,
    TextInputAction? inputAction,
    TextEditingController? controller,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    VoidCallback? onClear,
    ValueChanged<String?>? onSaved,
    ValueChanged<String?>? onReset,
    ValueChanged<String?>? onChanged,
    ValueChanged<String?>? onSubmitted,
    VoidCallback? onEditingComplete,
    List<Validator<String>>? validator,
    FieldTransformer<String, String>? renderer,
    FieldTransformer<String, String>? converter,
    FieldTransformer<String, String>? transformer,
  }) {
    return Input(
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
      debugLabel: "FormXFieldText($name)",
      builder: (ctx, parent, index) => FormXFieldText(
        key: key,
        name: name,
        label: label,
        left: left,
        leftIcon: leftIcon,
        empty: parent.empty,
        placeholder: placeholder,
        debug: debug ?? parent.debug,
        required: required,
        enabled: enabled ?? parent.enabled,
        restorationId: restorationId,
        showClear: showClear,
        showCounter: false,
        password: true,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        focusNode: focusNode,
        textAlign: textAlign,
        inputAction: inputAction,
        inputType: inputType,
        inputFormatters: inputFormatters,
        controller: controller,
        validator: validator,
        renderer: renderer,
        converter: converter,
        transformer: transformer,
        background: parent.background,
        textStyle: parent.textStyle,
        emptyTextStyle: parent.emptyTextStyle,
        subtitleTextStyle: parent.subtitleTextStyle,
        labelTextStyle: parent.labelTextStyle,
        errorTextStyle: parent.errorTextStyle,
        descriptionTextStyle: parent.descriptionTextStyle,
        onTap: onTap,
        onSaved: onSaved,
        onReset: onReset,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
      ),
    );
  }

  /// 用于构建多行文本（文本域）表单组件
  factory Input.textarea({
    Key? key,
    required String name,
    required String label,
    String? restorationId,
    String? placeholder,
    bool? debug,
    bool? enabled,
    bool? showCounter,
    bool required = false,
    bool showClear = true,
    bool? showOnEnabled,
    bool? hideOnDisabled,
    int? maxLines,
    int? maxLength,
    Widget? left,
    Icon? leftIcon,
    FocusNode? focusNode,
    TextAlign textAlign = TextAlign.start,
    TextInputType? inputType,
    TextInputAction? inputAction,
    TextEditingController? controller,
    MaxLengthEnforcement? maxLengthEnforcement,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    VoidCallback? onClear,
    ValueChanged<String?>? onSaved,
    ValueChanged<String?>? onReset,
    ValueChanged<String?>? onChanged,
    ValueChanged<String?>? onSubmitted,
    VoidCallback? onEditingComplete,
    List<Validator<String>>? validator,
    FieldTransformer<String, String>? renderer,
    FieldTransformer<String, String>? converter,
    FieldTransformer<String, String>? transformer,
  }) {

    //todo 需要改造成文本域组件
    return Input(
      showOnEnabled: showOnEnabled,
      hideOnDisabled: hideOnDisabled,
      debugLabel: "FormXFieldTextArea($name)",
      builder: (ctx, parent, index) => FormXFieldText(
        key: key,
        name: name,
        label: label,
        left: left,
        leftIcon: leftIcon,
        empty: parent.empty,
        placeholder: placeholder,
        debug: debug ?? parent.debug,
        required: required,
        enabled: enabled ?? parent.enabled,
        restorationId: restorationId,
        showCounter: showCounter,
        // maxLines: maxLines,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        focusNode: focusNode,
        textAlign: textAlign,
        inputAction: inputAction,
        inputType: inputType,
        inputFormatters: inputFormatters,
        controller: controller,
        validator: validator,
        renderer: renderer,
        converter: converter,
        transformer: transformer,
        background: parent.background,
        textStyle: parent.textStyle,
        emptyTextStyle: parent.emptyTextStyle,
        subtitleTextStyle: parent.subtitleTextStyle,
        labelTextStyle: parent.labelTextStyle,
        errorTextStyle: parent.errorTextStyle,
        descriptionTextStyle: parent.descriptionTextStyle,
        onTap: onTap,
        onSaved: onSaved,
        onReset: onReset,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
      ),
    );
  }
}