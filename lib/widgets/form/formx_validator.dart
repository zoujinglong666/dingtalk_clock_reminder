import '../../common/helper.dart';
import 'core/formx.dart';

/// 表单校验器，使用方式如下：
/// ```dart
///   Validator.reqiured(),
///   Validator.limited(3),
///   Validator.equals(form, 'password'),
///   Validator.includes<String>(["admin"]),
///   Validator.excludes<String>(["admin"]),
///   Validator.isUrl().
/// ```
///
/// * @author xbaistack
/// * @source B站/抖音/小红书/公众号（@小白栈记）
abstract class Validator<T> {
  const Validator();

  /// 用于返回校验器的名字，主要用途是拿来做区分，
  /// 比如在众多规则之中判断是否存在某一个校验规则之类的。
  /// 以下是默认实现，对于复杂的校验器的话，可以重写覆盖此方法的实现。
  String name() {
    var typeName = runtimeType.toString().substring(1); // _Required
    final index = typeName.indexOf('<'); // _Required<T>
    if (index > 0) {
      typeName = typeName.substring(0, index);
    }
    return typeName.toLowerCase();
  }

  /// 核心验证方法
  ///
  /// - @param [label] - 文字标签；
  /// - @param [value] - 被校验的值；
  /// - @return 校验不通过时的错误信息；
  String? validate(String label, T? value);

  /// 必填校验规则
  static Validator<T> required<T>() => _Required<T>();

  /// 包含校验规则：```Validator.includes<T>([...])```
  static Validator<T> includes<T>(List<T> items) => _Includes(items);

  /// 不包含校验规则：```Validator.excludes<T>([...])```
  static Validator<T> excludes<T>(List<T> items) => _Excludes(items);

  /// 字符串长度校验：```Validator.limited(3, 10)```
  static Validator<String> limited(int min, [int? max]) {
    return _LengthLimited(min, max);
  }

  /// 校验字符串是否是一个 URL：```Validator.isUrl(["http", "https"])```
  static Validator<String> isUrl([List<String>? protocols]) {
    return _IsUrl(protocols ?? const <String>["http", "https"]);
  }

  /// 校验给定的值是否和表单中另一个 [fieldName] 对应的值相同
  static Validator<T> equals<T>(FormXState? form, String fieldName) {
    return _Equals(form, fieldName);
  }
}

/// 必填校验
class _Required<T> extends Validator<T> {
  const _Required();

  @override
  String? validate(String label, T? value) {
    if (Helper.isEmpty(value)) {
      return "$label不能为空！";
    }
    return validateIt(label, value as T);
  }

  String? validateIt(String label, T value) {}
}

/// 包含校验，输入内容必须包含指定 [items] 列表的每一项
class _Includes<IN> extends _Required<IN> {
  final List<IN> items;

  const _Includes(this.items);

  @override
  String? validateIt(String label, IN value) {
    if (!Helper.contains(value, items.cast<String>())) {
      return "$label中必须包含（${items.join('，')}）等字符。";
    }
  }
}

/// 非包含校验，输入的内容不能出现指定 [items] 列表的任一一项。
class _Excludes<IN> extends _Required<IN> {
  final List<IN> items;

  const _Excludes(this.items);

  @override
  String? validateIt(String label, IN value) {
    if (Helper.contains(value, items.cast<String>())) {
      return "$label中不能包含（${items.join('，')}）等字符。";
    }
  }
}

/// 字符输入长度限制
class _LengthLimited extends _Required<String> {
  final int min;
  final int? max;

  const _LengthLimited(this.min, this.max);

  @override
  String? validateIt(String label, String value) {
    final length = value.length;
    if (length < min) return "$label最小需要输入$min个字符！";
    if (max != null && length > max!) return "$label最多只能输入$max个字符！";
  }
}

/// 是否是 URL 验证
class _IsUrl extends _Required<String> {
  final List<String> protocols;

  const _IsUrl(this.protocols);

  @override
  String? validateIt(String label, String value) {
    final uri = Uri.tryParse(value);
    if ((uri == null || Helper.isEmpty(uri.host)) ||
        (Helper.isNotEmpty(uri.scheme) && !protocols.contains(uri.scheme))) {
      return "$label不是一个标准的URL地址";
    }
  }
}

/// 值对比验证，可以和表单中存在的其他组件输入的值进行比对。
class _Equals<T> extends _Required<T> {
  final FormXState? form;
  final String fieldName;

  const _Equals(this.form, this.fieldName);

  @override
  String? validateIt(String label, T value) {
    if (form != null) {
      final another = form!.getValue(fieldName);
      if (another != value) {
        final field = form!.getField(fieldName);
        return "$label和${field?.widget.label}的值必须一致";
      }
    }
  }
}