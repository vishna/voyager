import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../router_context.dart';
import '../router_plugin.dart';
import '../voyager.dart';

class ScreenPlugin extends RouterPlugin {
  static const String KEY_SCREEN_BUILDER = "screenBuilder";

  final Map<String, WidgetBuilder> builders;

  ScreenPlugin(this.builders) : super("screen");

  @override
  void outputFor(RouterContext context, config, Voyager output) {
    if (config is String) {
      final builder = builders[config];
      if (builder != null) {
        output[KEY_SCREEN_BUILDER] = builder;
      } else {
        throw FlutterError("No builder for $config defined.");
      }
    }
  }
}

class ScreenProvider {
  static WidgetBuilder ofVoyager(Voyager voyager) {
    return voyager[ScreenPlugin.KEY_SCREEN_BUILDER];
  }

  static WidgetBuilder of(BuildContext context) {
    return ofVoyager(Provider.of<Voyager>(context));
  }
}
