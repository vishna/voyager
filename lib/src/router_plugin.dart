import 'router_context.dart';
import 'voyager.dart';

abstract class RouterPlugin {
  const RouterPlugin(this.node);
  final String node;

  void outputFor(RouterContext context, dynamic config, Voyager output);
}
