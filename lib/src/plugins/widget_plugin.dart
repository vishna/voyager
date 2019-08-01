import 'package:flutter/widgets.dart';
import '../router_context.dart';
import '../router_plugin.dart';
import '../voyager.dart';

class WidgetPlugin extends RouterPlugin {
  static const String KEY = "widget";

  final Map<String, WidgetBuilder> builders;

  WidgetPlugin(this.builders) : super(KEY);

  @override
  void outputFor(RouterContext context, config, Voyager output) {
    if (config is String) {
      final builder = builders[config];
      if (builder != null) {
        output[KEY] = builder;
      } else {
        throw FlutterError("No builder for $config defined.");
      }
    }
  }
}
