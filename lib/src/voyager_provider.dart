import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'voyager.dart';
import 'router.dart';

@Deprecated('use provider directly instead')
class VoyagerProvider {
  static Voyager of(BuildContext context) {
    return Provider.of<Voyager>(context);
  }

  static RouterNG routerOf(BuildContext context) {
    return Provider.of<RouterNG>(context);
  }
}
