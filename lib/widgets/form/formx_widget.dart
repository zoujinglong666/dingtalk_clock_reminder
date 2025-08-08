import 'package:flutter/material.dart';

import 'core/formx.dart';
import 'formx_inputs.dart';

// @FormControler
/// 表单控制器，用于控制或者和表单交互。
///
/// * @author xbaistack
/// * @source B站/抖音/小红书/公众号（@小白栈记）
class FormController {
  final VoidCallback? onChanged;
  final PopInvokedWithResultCallback? onWillPop;
  late final GlobalKey<FormXState> _formKey = GlobalKey();

  FormController({this.onChanged, this.onWillPop});

  /// 获取表单 State 对象
  FormXState? get form => _formKey.currentState;

  /// 执行表单验证，返回 [true] 代表验证通过。
  bool validate() => form?.validate() ?? false;

  /// 重置表单到初始状态
  void reset() => form?.reset();

  /// 获取指定 [name] 的表单 [State] 对象
  T? getField<T>(String name) => form?.getField(name) as T?;

  /// 动态设置某一个表单的值
  void setValue<T>(String name, T value) => form?.setValue(name, value);

  /// 动态设置表单的初始化，注意：此方式无法使用 [reset] 重置功能，
  /// 需要使用重置，请通过 [FormInput] 的 [initialValue] 进行设置。
  void setInitialValue(Map<String, dynamic> values) =>
      form?.initialValue = values;

  /// 获取表单中所有验证不通过的错误信息，前提是必须先调用 [validate] 验证方法哈，否则将会得到一个空集合。
  Map<String, dynamic> getErrors() => form?.errors ?? {};

  /// 获取表单中所有字段的值，获取前最要先使用 [validate] 去验证是否合法~
  Map<String, dynamic> getValue() => form?.value ?? {};

  /// 获取指定表单保存的值
  dynamic getValueBy(String name) => form?.getValue(name);

  /// 获取指定表单保存的临时值
  dynamic getRawValueBy(String name) => form?.getRawValue(name);

  /// 清除表单中最后一个持有焦点的输入组件的焦点
  void clearFocus() => form?.clearAnyFocus();
}

/// 核心表单组件，用于提供表单管理和统一控制。
///
/// * @author xbaistack
/// * @source B站/抖音/小红书/公众号（@小白栈记）
final class FormInput extends StatelessWidget {
  /// 是否开启 debug 调试模式
  final bool debug;

  /// 是否启用表单编辑模式，如果设置为 [false] 表示只读模式。
  final bool enabled;

  /// 是否启用边输入边验证模式
  final bool validateOnInput;

  /// 是否在页面上显示验证提示信息
  final bool showErrors;

  /// 空值时的占位文字信息
  final String? empty;

  /// 表单的初始化值
  final Map<String, dynamic> initialValue;

  /// 表单核心控制器，可以通过 [FormController] 去控制表单的各种行为。
  final FormController? controller;

  /// 核心的表单列表
  final List<Input> children;

  FormInput({
    super.key,
    this.debug = false,
    this.enabled = true,
    this.validateOnInput = false,
    this.showErrors = false,
    this.empty,
    this.initialValue = const <String, dynamic>{},
    this.controller,
    required List<Input> children,
  }) : children = filtering(enabled, children);

  late Color background;
  late TextStyle textStyle;
  late TextStyle emptyTextStyle;
  late TextStyle labelTextStyle;
  late TextStyle errorTextStyle;
  late TextStyle subtitleTextStyle;
  late TextStyle descriptionTextStyle;

  /// 样式由内部统一初始化
  /// 如果想通过构造去传的话，可以自己改造一下~
  void initialize(BuildContext context) {
    background = Colors.white;
    textStyle = const TextStyle(fontSize: 14);
    emptyTextStyle = textStyle.copyWith(color: const Color(0xFFD5D5D5));
    labelTextStyle = textStyle.copyWith(color: const Color(0xFF585858));
    errorTextStyle = const TextStyle(fontSize: 12, color: Colors.redAccent);
    subtitleTextStyle =
        textStyle.copyWith(fontSize: 12, color: const Color(0xFF888888));
    descriptionTextStyle = textStyle.copyWith(color: const Color(0xFF626262));
  }

  @override
  Widget build(BuildContext context) {
    initialize(context);
    return FormX(
      key: controller?._formKey,
      enabled: enabled,
      showErrors: showErrors,
      initialValue: initialValue,
      validateOnInput: validateOnInput,
      onChanged: controller?.onChanged,
      onWillPop: controller?.onWillPop,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ofItems(context),
        ),
      ),
    );
  }

  /// 构建所有表单和自定义组件
  List<Widget> ofItems(BuildContext context) {
    final items = <Widget>[];
    for (int index = 0, size = children.length; index < size; index++) {
      // 添加所有表单组件（或者自定义组件）
      items.add(children[index].build(context, this, index));
      // 为中间每一项添加一条分隔线
      if (index < size - 1) {
        items.add(const SizedBox(
          width: double.infinity,
          height: 0.5,
          child: ColoredBox(color: Color(0xFFE0E0E0)),
        ));
      }
    }
    return items;
  }

  /// 根据当前表单的 [enabled] 属性决定构建哪些表单组件，
  /// 组件可通过 [showOnEnabled] 或者 [hideOnDisabled] 决定在合适的场景中渲染出来。
  static List<Input> filtering(bool enabled, List<Input> children) {
    final newList = <Input>[];
    for (int index = 0, size = children.length; index < size; index++) {
      final input = children[index];

      if (enabled) {
        if (input.showOnEnabled) {
          newList.add(input);
        }
        continue;
      }
      if (!input.hideOnDisabled) {
        newList.add(input);
      }
    }
    return newList;
  }



}