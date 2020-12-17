import 'package:voyager/voyager.dart';

/// [VoyagerPlugin] allows parsing nodes located under individual paths
/// and putting them inside [Voyager] instance
abstract class VoyagerPlugin<VoyagerExtended extends Voyager> {
  /// default constructor
  const VoyagerPlugin(this.node);

  /// name of node this plugin is handling in the navigation schema
  final String node;

  /// build output
  void outputFor(
      VoyagerContext context, dynamic config, VoyagerExtended output);
}

/// just like [VoyagerPlugin] but expects you to produce an instance of [T]
/// allows performing disposal thru [onDispose] method
abstract class VoyagerObjectPlugin<T> extends VoyagerPlugin<Voyager> {
  /// default constructor
  const VoyagerObjectPlugin(String node) : super(node);

  /// build object
  T buildObject(VoyagerContext context, dynamic config);

  /// override if you need to dispose object
  void onDispose(T t) {}

  @override
  void outputFor(VoyagerContext context, dynamic config, Voyager output) {
    final object = buildObject(context, config);
    output[node] = object;
    output.onDispose(() {
      onDispose(object);
    });
  }
}
