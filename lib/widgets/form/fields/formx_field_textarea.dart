import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/helper.dart';
import '../../input_text/index.dart';
import '../core/formx.dart';
import '../core/formx_field_decoration.dart';
import 'formx_field_text.dart';


/// 文本域输入表单组件

class FormXFieldTextArea<OUT>
    extends FormXFieldDecoration<FormXFieldTextArea<OUT>, String, OUT> {
  final bool? password;
  final bool? showClear;
  final bool? showCounter;

  final int? maxLength;
  final int? maxLines;
  final FocusNode? focusNode;

  final TextAlign textAlign;
  final TextInputType? inputType;
  final TextInputAction? inputAction;
  final TextEditingController? controller;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final List<TextInputFormatter>? inputFormatters;

  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  const FormXFieldTextArea({
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
    this.password,
    this.showClear,
    this.showCounter,
    this.maxLength,
    this.maxLines,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.inputType,
    this.inputAction,
    this.controller,
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.onTap,
    this.onClear,
    this.onEditingComplete,
    this.onSubmitted,
  }) : super(isLabelExpanded: false);

  @override
  EdgeInsets ofBoxPadding(
      FormXFieldState<FormXFieldTextArea<OUT>, String, OUT> field) {
    return field.enabled ? EdgeInsets.only(left: padding) : insets();
  }

  @override
  void ofItems(
      List<Widget> items,
      FormXFieldState<FormXFieldTextArea<OUT>, String, OUT> field,
      ) {
    // 如果当前是只读模式就直接渲染值就行了
    if (field.readOnly) {
      return items.add(super.ofValueLabel(field, field.rawValue));
    }
    // 编辑模式下我们需要将 InputText 输入组件组装到容器中
    final state = field as FormXFieldTextAreaState;
    items.add(Expanded(
      child: InputText(
        enabled: field.enabled,
        readOnly: field.readOnly,
        password: password ?? false,
        showClear: showClear ?? true,
        showCounter: showCounter ?? true,
        controller: state.controller,
        focusNode: state.focusNode,
        initialValue: field.rawValue,
        textAlign: textAlign,
        textStyle: textStyle,
        inputType: inputType,
        inputAction: inputAction,
        inputFormatters: inputFormatters,
        placeholder: field.readOnly && field.isEmpty ? empty : placeholder,
        maxLength: maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
        enableInteractiveSelection: field.enabled,
        padding: insets(left: 3),
        onTap: onTap,
        onClear: onClear,
        onSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
      ),
    ));
  }

  @override
  State<StatefulWidget> createState() => FormXFieldTextAreaState<OUT>();
}

class FormXFieldTextAreaState<OUT>
    extends FormXFieldState<FormXFieldTextArea<OUT>, String, OUT> {
  late FocusNode focusNode;
  late FocusAttachment focusAttachment;
  late TextEditingController controller;

  void clear() => controller.clear();

  void focus() {
    if (!focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(focusNode);
    }
  }

  @override
  void unfocus() {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }

  @override
  void setValue(String? inputValue, {bool refresh = false}) {
    super.setValue(inputValue, refresh: refresh);
    if (initialized) {
      _updateControllerValue(inputValue);
    }
  }
  
  @override
  void reset() {
    super.reset();
    // 在重置时更新controller的值，避免controller与rawValue不同步
    if (initialized) {
      _updateControllerValue(initialValue);
    }
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TextEditingController(text: rawValue);
    controller.addListener(_handleValueChanged);
    focusNode = widget.focusNode ?? FocusNode(debugLabel: widget.name);
    focusNode.addListener(_handleFocusChanged);
    focusAttachment = focusNode.attach(context);
  }

  @override
  void didUpdateWidget(covariant FormXFieldTextArea<OUT> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      focusNode.removeListener(_handleFocusChanged);
      focusNode = widget.focusNode ?? FocusNode(debugLabel: widget.name);
      focusNode.addListener(_handleFocusChanged);
      focusAttachment = focusNode.attach(context);
    }
    if (widget.controller != oldWidget.controller) {
      controller.removeListener(_handleValueChanged);
      controller = widget.controller ?? TextEditingController(text: rawValue);
      controller.addListener(_handleValueChanged);
    }
  }

  @override
  void dispose() {
    focusAttachment.detach();
    if (widget.controller == null) {
      controller.dispose();
    }
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleValueChanged() {
    if (controller.text != (rawValue ?? '')) {
      super.setValue(controller.text, refresh: true);
    }
  }

  void _handleFocusChanged() {
    if (focusNode.hasFocus) {
      form?.lastField = this;
    }
  }

  void _updateControllerValue(String? value) {
    if (controller.text != value) {
      if (Helper.isEmpty(value)) {
        controller.clear();
      } else {
        controller.text = value!;
      }
    }
  }
}