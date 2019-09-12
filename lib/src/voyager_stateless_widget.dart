import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'plugins/widget_plugin.dart';
import 'router.dart';
import 'voyager.dart';
import 'voyager_argument.dart';

/// Widget that allows you embed any path anywhere in the widget tree. The requirement is router
/// supplied in the costructor (e.g. if this is a top widget) or available via `Provider<RouterNG>.of(context)`
///
/// You can set [VoyagerStatelessWidget.useCache] to true but bear in mind this makes [Voyager] instance shared
/// accross [VoyagerStatelessWidget]. Additionally such [Voyager] doesn't hold reference to parent. If you need
/// parent reference, use [Provider.of<VoyagerParent>(context)].
class VoyagerStatelessWidget extends StatelessWidget {
  const VoyagerStatelessWidget(
      {@required this.path,
      this.router,
      this.useCache = false,
      this.argument,
      Key key})
      : super(key: key);

  final String path;
  final Router router;
  final bool useCache;
  final VoyagerArgument argument;

  @override
  Widget build(BuildContext context) {
    final _router = router ?? Provider.of<Router>(context);

    Voyager parentVoyager;
    try {
      parentVoyager = useCache ? null : Provider.of<Voyager>(context);
    } catch (t) {
      parentVoyager = null;
    }

    final voyager = useCache
        ? _router.findCached(path)
        : _router.find(path, parent: parentVoyager);

    final WidgetBuilder builder = voyager[WidgetPlugin.KEY];

    assert(builder != null,
        "WidgetBuilder of _voyager should not be null, did you forget to add WidgetPlugin?");

    return MultiProvider(
      providers: [
        Provider<Voyager>.value(value: voyager),
        if (useCache)
          Provider<VoyagerParent>.value(
              value: VoyagerParent(safeParent(context))),
        if (router != null) Provider<Router>.value(value: router),
        if (argument != null) Provider<VoyagerArgument>.value(value: argument)
      ],
      child: Builder(builder: builder),
    );
  }

  static Voyager safeParent(BuildContext context) {
    try {
      return Provider.of<Voyager>(context);
    } catch (_) {
      return null;
    }
  }
}

/// this is only exposed when using cache in statless widget
class VoyagerParent {
  const VoyagerParent(this.value);
  final Voyager value;
}
