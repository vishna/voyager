import 'router_context.dart';
import 'voyager.dart';

abstract class RouterPlugin<VoyagerExtended extends Voyager> {
  const RouterPlugin(this.node);
  final String node;

  void outputFor(RouterContext context, dynamic config, VoyagerExtended output);
}

abstract class RouterObjectPlugin<T> extends RouterPlugin<Voyager> {
  RouterObjectPlugin(String node) : super(node);

  T buildObject(RouterContext context, dynamic config);

  void onDispose(T t) {}

  @override
  void outputFor(RouterContext context, dynamic config, Voyager output) {
    final object = buildObject(context, config);
    output[node] = object;
    output.onDispose(() {
      onDispose(object);
    });
  }
}
