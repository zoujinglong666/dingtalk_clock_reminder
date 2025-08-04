class Helper {
  Helper._();

  /// 用于判断给定的 A, B 是否是同一个类型，或者 A 是 B 的子类。
  static bool sameType<A, B>() {
    if (A == B || A is B) return true;
    String type = A.toString();
    String target = B.toString();
    return type == target || type == "$target?";
  }

  /// 返回当前系统时间戳
  static int timestamp() => DateTime.now().millisecondsSinceEpoch;
  static bool isEmpty(dynamic input) {
    if (input == null) return true;
    if (input is String || input is List || input is Map) {
      return input.isEmpty;
    }
    return false;
  }
  static bool isNotEmpty(dynamic input) {
    if (input == null) return false;
    if (input is String || input is List || input is Map) {
      return input.isNotEmpty;
    }
    return true;
  }
  /// 检查值是否包含指定的项目
  static bool contains(dynamic value, List<String>? items) {
    if (value == null || Helper.isEmpty(items)) return false;

    if (value is String) {
      // 如果值是字符串，检查是否包含items中的任何一项
      for (String item in items!) {
        if (value.contains(item)) {
          return true;
        }
      }
    } else if (value is List) {
      // 如果值是列表，检查是否包含items中的任何一项
      for (String item in items!) {
        if (value.contains(item)) {
          return true;
        }
      }
    } else if (value is Map) {
      // 如果值是Map，检查键是否包含items中的任何一项
      for (String item in items!) {
        if (value.keys.contains(item)) {
          return true;
        }
      }
    }

    return false;
  }

  static List<OUT>? listConverter<IN, OUT>(List<IN>? list) {
    if (isEmpty(list)) return null;
    if (IN == OUT) return list as List<OUT>;
    return list!.map((item) => converter<IN, OUT>(item)).toList();
  }

  static Set<OUT>? setConverter<IN, OUT>(Set<IN>? set) {
    if (isEmpty(set)) return null;
    if (IN == OUT) return set as Set<OUT>;
    return set!.map((item) => converter<IN, OUT>(item)).toSet();
  }

  static OUT converter<IN, OUT>(IN? value) {
    // Basic judgment
    if (value == null) return null as OUT;
    if (IN == OUT || value is OUT) return value as OUT;

    // to String
    if (sameType<OUT, String>()) {
      return value.toString() as OUT;
    }

    // to int
    if (sameType<OUT, int>()) {
      // boolean -> int
      if (value is bool || sameType<IN, bool>()) {
        return (value == true ? 1 : 0) as OUT;
      }
      // num -> int
      if (value is num || sameType<IN, num>()) {
        return (value as num).toInt() as OUT;
      }
      // string -> int
      if (value is String || sameType<IN, String>()) {
        return int.parse(value.toString()) as OUT;
      }
      // datetime -> int
      if (value is DateTime || sameType<IN, DateTime>()) {
        return (value as DateTime).millisecondsSinceEpoch as OUT;
      }
    }

    // to double
    else if (sameType<OUT, double>()) {
      // boolean -> double
      if (value is bool || sameType<IN, bool>()) {
        return (value == true ? 1.0 : 0.0) as OUT;
      }
      // num -> double
      if (value is num || sameType<IN, num>()) {
        return (value as num).toDouble() as OUT;
      }
      // string -> double
      if (value is String || sameType<IN, String>()) {
        return double.parse(value.toString()) as OUT;
      }
      // datetime -> double
      if (value is DateTime || sameType<IN, DateTime>()) {
        return (value as DateTime).millisecondsSinceEpoch.toDouble() as OUT;
      }
    }

    // to boolean
    else if (sameType<OUT, bool>()) {
      // num -> boolean
      if (value is num || sameType<IN, num>()) {
        return ((value as num) > 0) as OUT;
      }
      if (value is String || sameType<IN, String>()) {
        String v = value.toString().toLowerCase();
        return (v == "true" || v == "y" || v == "yes") as OUT;
      }
    }

    // to DateTime
    else if (sameType<OUT, DateTime>()) {
      // int -> DateTime
      if (value is num || sameType<IN, num>()) {
        return DateTime.fromMillisecondsSinceEpoch((value as num).toInt())
        as OUT;
      }
      // String -> DateTime
      if (value is String || sameType<IN, String>()) {
        return DateTime.parse(value as String) as OUT;
      }
    }

    // IN -> OUT
    return value as OUT;
  }
}