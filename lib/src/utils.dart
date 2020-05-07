import 'dart:convert';
import 'package:sprintf/sprintf.dart';
import 'package:voyager/voyager.dart';

const String _VARIABLE_PREFIX = "%{";
const String _VARIABLE_SUFFIX = "}";

// ignore: avoid_classes_with_only_static_members
class VoyagerUtils {
  static bool isNullOrBlank(String it) {
    return it == null || it.trim().isEmpty;
  }

  static String interpolate(String format, Map<String, dynamic> values) {
    if (isNullOrBlank(format) || !format.contains(_VARIABLE_PREFIX))
      return format;
    var convFormat = format;

    final keys = values.keys.iterator;
    final valueList = <String>[];

    var currentPos = 0;
    while (keys.moveNext()) {
      final key = keys.current,
          formatKey = "$_VARIABLE_PREFIX$key$_VARIABLE_SUFFIX",
          formatPos = "%$currentPos\$s";
      var index = 0;
      var replaced = false;
      while ((index = convFormat.indexOf(formatKey, index)) != -1) {
        convFormat =
            convFormat.replaceRange(index, index + formatKey.length, formatPos);
        index += formatPos.length;
        replaced = true;
      }

      if (replaced) {
        valueList.add(values[key]);
        ++currentPos;
      }
    }

    try {
      return sprintf(convFormat, valueList);
    } catch (e) {
      return null;
    }
  }

  static void interpolateDynamic(dynamic param, RouterContext context) {
    if (param is List) {
      interpolateList(param, context);
    } else if (param is Map) {
      final Map<String, dynamic> map = param;
      final keys = map.keys;
      for (final key in keys) {
        final dynamic value = map[key];
        if (isListOrMap(value)) {
          interpolateDynamic(value, context);
        } else if (value is String) {
          final newValue = interpolate(value, context.params);
          map[key] = newValue;
        }
      }
    }
  }

  static void interpolateList(List array, RouterContext context) {
    final n = array.length;
    for (var i = 0; i < n; i++) {
      dynamic o = array[i];

      if (isListOrMap(o)) {
        interpolateDynamic(o, context);
      } else if (o is String) {
        o = interpolate(o, context.params);
        array[i] = o;
      }
    }
  }

  static bool isTuple(dynamic object) {
    return object is Map && object.keys.length == 1;
  }

  static bool isListOrMap(Object object) {
    return object is Map || object is List;
  }

  static MapEntry<String, dynamic> tuple(dynamic object) {
    if (!isTuple(object)) {
      throw ArgumentError("$object is not a tuple");
    }
    return object.entries.first;
  }

  static Map<String, dynamic> copyIt(Map<String, dynamic> config) {
    return json.decode(json.encode(config));
  }

  static String cleanUrl(String url) {
    var outputUrl = url;
    if (outputUrl.startsWith("/")) {
      outputUrl = outputUrl.substring(1, outputUrl.length);
    }
    if (outputUrl.endsWith("/")) {
      outputUrl = outputUrl.substring(0, outputUrl.length - 1);
    }
    return outputUrl;
  }

  static Uri fromPath(String path) {
    final cleanedPath = VoyagerUtils.cleanUrl(path);

    return Uri.parse("http://tempuri.org/" + cleanedPath);
  }

  static bool isWildcard(String format) {
    final routerUrl = cleanUrl(format);
    final routerParts = routerUrl.split("/");

    for (final routerPart in routerParts) {
      if (routerPart.length > 2 &&
          routerPart[0] == ':' &&
          routerPart[routerPart.length - 1] == ':') {
        return true;
      }
    }
    return false;
  }

  /// Necessary to obtain generic [Type]
  /// https://github.com/dart-lang/sdk/issues/11923
  static String stringTypeOf<T>() {
    final className = T.toString();
    return deobfuscate(className);
  }

  static String deobfuscate(String className) {
    return _obfuscationMap[className] ?? className;
  }

  /// If you're targeting WEB use this method to register class symbols used by navigation map.
  /// dart2js is obfuscating class names thus making it impossible to resolve them during runtime
  /// in the release mode
  static void addObfuscationMap(Map<Type, String> map) {
    map.forEach((key, value) {
      _obfuscationMap[key.toString()] = value;
    });
  }

  static final _obfuscationMap = <String, String>{};
}
