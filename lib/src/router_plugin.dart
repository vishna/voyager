import 'router_context.dart';
import 'voyager.dart';

abstract class RouterPlugin {
  final String node;

  RouterPlugin(this.node);

  void outputFor(RouterContext context, dynamic config, Voyager output);
}
