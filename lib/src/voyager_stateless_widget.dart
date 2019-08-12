import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'voyager_argument.dart';
import 'router.dart';
import 'voyager.dart';
import 'plugins/widget_plugin.dart';

/// Widget that allows you embed any path anywhere in the widget tree. The requirement is router
/// supplied in the costructor (e.g. if this is a top widget) or available via `Provider<RouterNG>.of(context)`
class VoyagerStatelessWidget extends StatelessWidget {
  final String path;
  final RouterNG router;
  final bool useCache;
  final VoyagerArgument argument;

  const VoyagerStatelessWidget(
      {@required this.path,
      this.router,
      this.useCache = false,
      this.argument,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _router = router ?? Provider.of<RouterNG>(context);

    var parentVoyager;
    try {
      parentVoyager = useCache ? null : Provider.of<Voyager>(context);
    } catch (t) {
      parentVoyager = null;
    }

    final voyager = useCache
        ? _router.findCached(path)
        : _router.find(path, parent: parentVoyager);

    assert(voyager != null, "voyager instance should not be null");

    final builder = voyager[WidgetPlugin.KEY];

    assert(builder != null,
        "WidgetBuilder of _voyager should not be null, did you forget to add WidgetPlugin?");

    return MultiProvider(
      providers: [
        Provider<Voyager>.value(value: voyager),
        if (router != null) Provider<RouterNG>.value(value: router),
        if (argument != null) Provider<VoyagerArgument>.value(value: argument)
      ],
      child: Builder(builder: builder),
    );
  }
}
