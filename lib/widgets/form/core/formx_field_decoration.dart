import 'package:flutter/material.dart';

import '../../../common/helper.dart';
import 'formx.dart';

abstract class FormXFieldDecoration<W extends FormXField<W, IN, OUT>, IN, OUT>
    extends FormXField<W, IN, OUT> {
  /// 再查看模式下当组件值为空时用于显示的空占位符（默认："(空)"）
  final String empty;

  /// 文字标签子标题，虽说每个组件都可以设置它，
  /// 但是最好只在开关类组件和选择类组件中使用，否则效果会很丑！
  final String? subtitle;

  /// 组件占位符
  ///
  /// - 输入框：输入框中间的灰色提示文字；
  /// - 选择组件：末尾右侧前头前的提示文字；
  final String? placeholder;

  /// 在最左侧加入一个自定义显示的组件
  final Widget? left;

  /// 在最左侧加入一个字体图标
  final Icon? leftIcon;

  /// 文本标签是否占满左侧空间
  final bool isLabelExpanded;

  /// 组件内部间距（默认：12）
  final padding = 12.0;

  final Color? background;
  final TextStyle? textStyle;
  final TextStyle? emptyTextStyle;
  final TextStyle? labelTextStyle;
  final TextStyle? errorTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextStyle? descriptionTextStyle;

  const FormXFieldDecoration({
    super.key,
    // FormXField
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
    super.renderer,
    super.validator,
    super.converter,
    super.transformer,
    // FormXFieldDecoration
    String? empty,
    this.subtitle,
    this.placeholder,
    this.left,
    this.leftIcon,
    this.isLabelExpanded = false,
    this.background,
    this.textStyle,
    this.emptyTextStyle,
    this.labelTextStyle,
    this.errorTextStyle,
    this.subtitleTextStyle,
    this.descriptionTextStyle,
  }) : empty = empty ?? "(空)";

  /// 用于提供一个快速构建 [EdgeInsets] 的方法，如果对应方位的值未设置的话，则使用 [padding] 值。
  EdgeInsets insets({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? padding,
      top: top ?? padding,
      right: right ?? padding,
      bottom: bottom ?? padding,
    );
  }

  /// 用于设置表单组件的盒子内间距
  EdgeInsets ofBoxPadding(FormXFieldState<W, IN, OUT> field) => insets();

  /// 用于追加组件到 [Row] 中，这的里 [Row] 就是一个横向布局的表单组件
  void ofItems(List<Widget> items, FormXFieldState<W, IN, OUT> field);

  @override
  Widget build(FormXFieldState<W, IN, OUT> field) {
    final items = <Widget>[];
    // final theme = field.context.theme; // ★

    // 表单左侧的小组件（自定义组件 | 图标）
    if (left != null) {
      items.add(left!);
    } else if (leftIcon != null) {
      // items.add(IconTheme(
      //   data: theme.data.iconTheme.copyWith(size: 18), // ★
      //   child: leftIcon!,
      // ));
    }

    // 表单左侧的文本标签（字段名）
    final label = Padding(
      padding: EdgeInsets.only(left: items.isEmpty ? 0 : 5, right: 5),
      child: ofLabel(field),
    );
    items.add(isLabelExpanded ? Expanded(child: label) : label);

    // 添加其它尾部小组件
    ofItems(items, field);

    // 核心表单内容
    Widget input = ofWrapper(
      field,
      Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: items,
      ),
    );

    // 只读模式直接返回
    if (field.readOnly) return input;

    // 表单组件放在上面
    final columns = <Widget>[input];

    // 错误信息放在下面
    if (field.showErrors && field.hasError) {
      columns.add(ofErrorInfo(field));
    }

    // 有错误的时候，需要把错误信息展示出来
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  /// 用于包装表单核心组件，子类可以重写它并绑定点击事件或者自定义处理。
  Widget ofWrapper(FormXFieldState<W, IN, OUT> field, Widget child) {
    return Container(
      color: background ?? Colors.white,
      padding: ofBoxPadding(field),
      child: child,
    );
  }

  /// 用于构建左侧文字标签，如果设置了 [required] 的话，会在文字标签的右侧追加一个小红星 [*]。
  /// 另外，如果设置了 [subtitle] 子标题的话，会在 [label] 的下方添加一个子标题。
  Widget ofLabel(FormXFieldState<W, IN, OUT> field) {
    Widget caption = Text(
      label,
      maxLines: 1,
      style: labelTextStyle,
      overflow: TextOverflow.ellipsis,
    );
    // 必填的星号
    if (this.required && field.enabled) {
      caption = Stack(children: [
        Padding(padding: const EdgeInsets.only(right: 7), child: caption),
        const Positioned(
          right: 0,
          top: 4,
          child: Text(
            "*",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ]);
    }
    // 子标题
    if (Helper.isNotEmpty(subtitle)) {
      caption = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          caption,
          const SizedBox(height: 3),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subtitleTextStyle,
          ),
        ],
      );
    }
    return caption;
  }

  /// 用于构建查看模式下的右侧值回显标签
  Widget ofValueLabel(FormXFieldState<W, IN, OUT> field, String? value) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          value ?? empty,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: field.enabled || field.isNotEmpty ? textStyle : emptyTextStyle,
        ),
      ),
    );
  }

  /// 用于固件错误信息展示组件
  Widget ofErrorInfo(FormXFieldState<W, IN, OUT> field) {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Color(0x12FF5252),
        border: Border(
          top: BorderSide(width: 1, color: Color(0x26FF5252)),
          bottom: BorderSide(width: 1, color: Color(0x26FF5252)),
        ),
      ),
      padding: insets(top: 2, bottom: 3),
      margin: const EdgeInsets.only(bottom: 1),
      child: Text(field.errorText!, style: errorTextStyle),
    );
  }
}