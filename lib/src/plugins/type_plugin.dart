import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../router_plugin.dart';
import '../router_context.dart';
import '../utils.dart';
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
    return Provider.of<Voyager>(context)[_KEY_TYPE];
  }
}
