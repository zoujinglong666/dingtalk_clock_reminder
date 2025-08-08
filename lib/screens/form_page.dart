import 'package:dingtalk_clock_reminder/widgets/Button.dart';
import 'package:dingtalk_clock_reminder/widgets/Clickable.dart';
import 'package:dingtalk_clock_reminder/widgets/form/core/formx_validator.dart';
import 'package:dingtalk_clock_reminder/widgets/form/formx_inputs.dart';
import 'package:dingtalk_clock_reminder/widgets/form/formx_widget.dart';
import 'package:flutter/material.dart';


class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<StatefulWidget> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  late final FormController controller = FormController();

  bool enabled = true;
  Map<String, dynamic> initialValue = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("小白栈记"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Clickable(
              onTap: () => setState(() {
                enabled = !enabled;
                initialValue = controller.getValue();
              }),
              child: Text(enabled ? "查看" : "编辑"),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FormInput(
              enabled: enabled,
              controller: controller,
              showErrors: true,
              validateOnInput: true,
              initialValue: initialValue,
              children: [
                Input.leading("输入类组件"),
                Input.text(
                  name: "username",
                  label: "用户名",
                  placeholder: "请输入用户名",
                  required: true,
                  validator: [
                    Validator.limited(3, 10),
                    Validator.excludes(["admin"]),
                  ],
                ),
                Input.password(
                  name: "password",
                  label: "密码",
                  required: true,
                  hideOnDisabled: true,
                ),
                Input.password(
                  name: "re-password",
                  label: "确认密码",
                  required: true,
                  hideOnDisabled: true,
                  validator: [
                    Validator.equals(controller.form, "password"),
                  ],
                ),
                Input.spacer(),
                Input.textarea(
                  name: "textarea",
                  label: "备注信息",
                  placeholder: "请输入你的备注信息",
                  maxLines: 5,
                  maxLength: 100,
                  showCounter: true,
                ),
                Input.leading("验证码"),
                Input.mobile(
                  name: "mobile",
                  label: "手机号码",
                  placeholder: "请输入你的手机号码",
                  maxLength: 11,
                  required: true,
                  // hideOnDisabled: true,
                ),
                Input.spacer(hideOnDisabled: true),
                Input.text(
                  name: "smsCode",
                  label: "验证码",
                  placeholder: "请输入你收到的6位验证码",
                  maxLength: 6,
                  showCounter: false,
                  required: true,
                  hideOnDisabled: true,
                ),
                Input.captcha(
                  name: "captcha",
                  label: "图形验证码",
                  placeholder: "请输入右侧图片上的字符",
                  maxLength: 4,
                  hideOnDisabled: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Row(children: [
              Flexible(
                child: Button(
                  text: "校验",
                  radius: BorderRadius.circular(6),
                  onTap: (btn) {
                    if (controller.validate()) {
                    } else {
                      final errors = controller.getErrors();
                      print("---------------- Validate ----------------");
                      errors.forEach((k, v) => print("$k : $v"));
                      print("------------------------------------------");
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 2,
                child: Button(
                  text: "提取表单数据",
                  radius: BorderRadius.circular(6),
                  onTap: (btn) {
                    print("------------------- FormValue --------------------");
                    controller.getValue().forEach((k, v) => print("$k : $v"));
                    print("--------------------------------------------------");
                  },
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Button(
                  text: "重置",
                  radius: BorderRadius.circular(6),
                  onTap: (btn) => controller.reset(),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}