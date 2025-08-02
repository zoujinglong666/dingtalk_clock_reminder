import 'package:flutter/material.dart';

// 钉钉风格颜色主题
const Color primaryColor = Color(0xFF1677FF); // 钉钉蓝色
const Color secondaryColor = Color(0xFF4080FF);
const Color backgroundColor = Color(0xFFFFFFFF); // 白色背景
const Color cardColor = Color(0xFFF5F7FA);
const Color textColor = Color(0xFF333333);
const Color accentColor = Color(0xFF00B42A);
const Color lightTextColor = Color(0xFF666666);

// 文本样式
const TextStyle subtitleStyle = TextStyle(
  color: textColor,
  fontSize: 16,
  fontWeight: FontWeight.bold,
);

const TextStyle bodyStyle = TextStyle(
  color: lightTextColor,
  fontSize: 14,
);

/// 科技风格卡片组件
class TechCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const TechCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 科技风格线条装饰
class TechLine extends StatelessWidget {
  final double width;
  final Color color;
  final double height;

  const TechLine({
    Key? key,
    this.width = double.infinity,
    this.color = primaryColor,
    this.height = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0),
            color,
            color.withOpacity(0),
          ],
          stops: const [0, 0.5, 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}