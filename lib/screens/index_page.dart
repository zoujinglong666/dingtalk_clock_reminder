import 'package:dingtalk_clock_reminder/widgets/form/core/formx.dart';
import 'package:flutter/material.dart';

import '../widgets/myForm.dart';
import '../widgets/myform_field.dart';
class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<StatefulWidget> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("小白栈记")),
      body: const FormX(child: ),
    );
  }
}