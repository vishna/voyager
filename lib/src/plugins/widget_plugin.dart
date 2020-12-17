import 'package:flutter/widgets.dart';
import 'package:voyager/voyager.dart';

/// widget plugin, allows voyager to understand widget mappings
/// you provide in your yaml file
class WidgetPlugin extends VoyagerPlugin {
  /// default constructor
  const WidgetPlugin(this.builders) : super(KEY);

  /// plugin node name
  static const String KEY = "widget";

  /// widget builder mappings
  final Map<String, WidgetBuilder> builders;

  @override
  void outputFor(VoyagerContext context, dynamic config, Voyager output) {
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

/// utility class for easier [WidgetPlugin] creation
class WidgetPluginBuilder {
  final Map<String, WidgetBuilder> _builders = {};

  /// creates WidgetPlugin
  WidgetPlugin build() => WidgetPlugin(_builders);

  /// adds a widget mapping to list of widget mappings
  WidgetPluginBuilder add<T extends Widget>(WidgetBuilder builder,
      {List<String>? aliases}) {
    final type = VoyagerUtils.stringTypeOf<T>();
    if (type == "Widget") {
      /// method used without specifying T
      throw ArgumentError(
          "Use addMethod if you can't provide Widget class as T parameter");
    }
    return addMethod(builder, type, aliases: aliases);
  }

  /// adds a widget mapping to list of widget mappings
  WidgetPluginBuilder addMethod(WidgetBuilder builder, String type,
      {List<String>? aliases}) {
    assert(!VoyagerUtils.isNullOrBlank(type),
        "Widget type might not be null or blank");
    assert(_builders[type] == null, "Type $type is already registered.");
    aliases?.forEach((alias) {
      assert(
          _builders[alias] == null, "Alias $alias for $type is already used.");
      _builders[alias] = builder;
    });
    _builders[type] = builder;
    return this;
  }

  /// adds widget mappings from another builder to this builder
  WidgetPluginBuilder addBuilder(WidgetPluginBuilder builder) {
    _builders.addAll(builder._builders);
    return this;
  }
}
