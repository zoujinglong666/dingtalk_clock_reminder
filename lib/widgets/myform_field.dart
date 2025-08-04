import 'package:flutter/material.dart';
import 'myForm.dart';

class MyFormField extends StatefulWidget {
  const MyFormField({super.key});

  @override
  State<StatefulWidget> createState() => MyFormFieldState();
}

class MyFormFieldState extends State<MyFormField> {

  void test() {
    print(":3：子组件的测试方法");
  }

  @override
  void initState() {
    super.initState();
    print("1：初始化");
    MyForm.maybeOf(context)?.test(this);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}