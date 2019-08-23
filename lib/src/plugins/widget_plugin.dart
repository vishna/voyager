import 'package:flutter/widgets.dart';
import 'package:voyager/src/utils.dart';
import '../router_context.dart';
import '../router_plugin.dart';
import '../voyager.dart';

class WidgetPlugin extends RouterPlugin {
  WidgetPlugin(this.builders) : super(KEY);
  static const String KEY = "widget";

  final Map<String, WidgetBuilder> builders;

  @override
  void outputFor(RouterContext context, dynamic config, Voyager output) {
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

class WidgetPluginBuilder {
  final Map<String, WidgetBuilder> _builders = {};
  WidgetPlugin build() => WidgetPlugin(_builders);

  WidgetPluginBuilder add<T extends Widget>(WidgetBuilder builder,
      {List<String> aliases}) {
    final type = _typeOf<T>().toString();
    if (type == "Widget") {
      /// method used without specifying T
      throw ArgumentError(
          "Use addMethod if you can't provide Widget class as T parameter");
    }
    return addMethod(builder, type, aliases: aliases);
  }

  WidgetPluginBuilder addMethod(WidgetBuilder builder, String type,
      {List<String> aliases}) {
    assert(builder != null, "Builder must be provided");
    assert(!VoyagerUtils.isNullOrBlank(type),
        "Widget type might not be null or blank");
    assert(_builders[type] == null, "Type $type is already registered.");
    _builders[type] = builder;
    aliases?.forEach((alias) {
      assert(
          _builders[alias] == null, "Alias $alias for $type is already used.");
      _builders[alias] = builder;
    });
    return this;
  }
}

/// Necessary to obtain generic [Type]
/// https://github.com/dart-lang/sdk/issues/11923
Type _typeOf<T>() => T;
