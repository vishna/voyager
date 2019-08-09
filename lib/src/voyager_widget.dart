import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'voyager.dart';
import 'plugins/widget_plugin.dart';

/// Widget that allows you embed any path anywhere in the widget tree. The requirement is router
/// supplied in the costructor (e.g. if this is a top widget) or available via `Provider<RouterNG>.of(context)`
class VoyagerWidget extends StatelessWidget {
  final String path;
  final RouterNG router;
  final bool useCache;

  VoyagerWidget({@required this.path, this.router, this.useCache = false});

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
        "WidgetBuilder of _voyager should not be null, did you forget to add ScreenPlugin?");

    if (router == null) {
      // this means we inherited router from the context, thus we don't need to provide it to children
      return Provider<Voyager>.value(
        value: voyager,
        child: Builder(builder: builder),
      );
    } else {
      return MultiProvider(
        providers: [
          Provider<Voyager>.value(value: voyager),
          Provider<RouterNG>.value(value: _router)
        ],
        child: Builder(builder: builder),
      );
    }
  }
}
