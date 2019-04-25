import 'package:flutter/widgets.dart';

import '../router_plugin.dart';
import '../router_context.dart';
import '../utils.dart';
import '../voyager_provider.dart';
import '../voyager.dart';

const _KEY_TYPE = "type";

class TypePlugin extends RouterPlugin {
  TypePlugin() : super(_KEY_TYPE);

  @override
  void outputFor(RouterContext context, config, Voyager output) {
    String type = config.toString();
    if (VoyagerUtils.isNullOrBlank(type)) return;
    output[_KEY_TYPE] = type;
  }
}

class TypeProvider {
  static String of(BuildContext context) {
    return VoyagerProvider.of(context)[_KEY_TYPE];
  }
}
