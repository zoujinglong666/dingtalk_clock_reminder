import 'package:flutter/material.dart';

import 'myform_field.dart';

class MyForm extends StatefulWidget {
  final Widget child;
  const MyForm({super.key, required this.child});

  // 核心代码
  static MyFormState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MyFormState>();
  }

  @override
  State<StatefulWidget> createState() => MyFormState();
}

class MyFormState extends State<MyForm> {
  @override
  Widget build(BuildContext context) => widget.child;

  void test(MyFormFieldState field) {
    print("2：父组件的测试方法");
    field.test();
  }
}