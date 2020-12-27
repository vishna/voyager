import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:voyager/voyager.dart';

/// page plugin, allows voyager to understand page mappings
/// you provide in your yaml file
class PagePlugin extends VoyagerPlugin {
  /// default constructor
  const PagePlugin(this.builders) : super(KEY);

  /// plugin node name
  static const String KEY = "page";

  /// page builder mappings
  final Map<String, VoyagerPageBuilder> builders;

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

  /// default mapping for material page
  static Page<dynamic> defaultMaterial(Widget widget, VoyagerPage page) {
    return MaterialPage<dynamic>(
      key: page.key,
      name: page.path,
      arguments: page.argument,
      child: widget,
    );
  }

  /// default mapping for cupertino page
  static Page<dynamic> defaultCupertino(Widget widget, VoyagerPage page) {
    return CupertinoPage<dynamic>(
      key: page.key,
      name: page.path,
      arguments: page.argument,
      child: widget,
    );
  }
}

/// utility class for easier [WidgetPlugin] creation
class PagePluginBuilder {
  final Map<String, VoyagerPageBuilder> _builders = {};

  /// creates WidgetPlugin
  PagePlugin build() => PagePlugin(_builders);

  /// adds a page mapping to list of page mappings
  PagePluginBuilder add(String type, VoyagerPageBuilder builder) {
    assert(!VoyagerUtils.isNullOrBlank(type),
        "Widget type might not be null or blank");
    assert(_builders[type] == null, "Type $type is already registered.");
    _builders[type] = builder;
    return this;
  }

  /// adds page mappings from another builder to this builder
  PagePluginBuilder addBuilder(PagePluginBuilder builder) {
    _builders.addAll(builder._builders);
    return this;
  }
}
