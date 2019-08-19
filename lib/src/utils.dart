import 'package:sprintf/sprintf.dart';
import 'router_context.dart';
import 'dart:convert';

const String _VARIABLE_PREFIX = "%{";
const String _VARIABLE_SUFFIX = "}";

class VoyagerUtils {
  static bool isNullOrBlank(String it) {
    return it == null || it.trim().length == 0;
  }

  static String interpolate(String format, Map<String, dynamic> values) {
    if (isNullOrBlank(format) || !format.contains(_VARIABLE_PREFIX))
      return format;
    String convFormat = format;

    final keys = values.keys.iterator;
    List<String> valueList = new List<String>();

    int currentPos = 0;
    while (keys.moveNext()) {
      String key = keys.current,
          formatKey = "$_VARIABLE_PREFIX$key$_VARIABLE_SUFFIX",
          formatPos = "%$currentPos\$s";
      int index = 0;
      bool replaced = false;
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
      Map<String, dynamic> map = param;
      final keys = map.keys;
      for (String key in keys) {
        final value = map[key];
        if (isListOrMap(value)) {
          interpolateDynamic(value, context);
        } else if (value is String) {
          String newValue = interpolate(value, context.params);
          map[key] = newValue;
        }
      }
    }
  }

  static void interpolateList(List array, RouterContext context) {
    for (int i = 0, n = array.length; i < n; i++) {
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
    return (object as Map).entries.first;
  }

  static copyIt(dynamic config) {
    return json.decode(json.encode(config)) as Map<String, dynamic>;
  }

  static String cleanUrl(String url) {
    String outputUrl = url;
    if (outputUrl.startsWith("/")) {
      outputUrl = outputUrl.substring(1, outputUrl.length);
    }
    if (outputUrl.endsWith("/")) {
      outputUrl = outputUrl.substring(0, outputUrl.length - 1);
    }
    return outputUrl;
  }

  static Uri fromPath(String path) {
    final String cleanedPath = VoyagerUtils.cleanUrl(path);

    return Uri.parse("http://tempuri.org/" + cleanedPath);
  }

  static bool isWildcard(String format) {
    String routerUrl = cleanUrl(format);
    List<String> routerParts = routerUrl.split("/");

    for (String routerPart in routerParts) {
      if (routerPart.length > 2 &&
          routerPart[0] == ':' &&
          routerPart[routerPart.length - 1] == ':') {
        return true;
      }
    }
    return false;
  }
}
