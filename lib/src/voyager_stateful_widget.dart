import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'voyager.dart';
import 'plugins/widget_plugin.dart';

/// Just like [VoyagerWidget] but stateful. It has additional parameter called `keepAlive` which is usefull
/// when embedding the widget in things like `TabBarView`. Most of the time you don't want this. Retains [Voyager]
/// unless path or router changes
class VoyagerStatefulWidget extends StatefulWidget {
  final String path;
  final bool keepAlive;
  final RouterNG router;

  VoyagerStatefulWidget(
      {@required this.path, this.keepAlive = false, this.router});

  @override
  State<StatefulWidget> createState() =>
      VoyagerWidgetState(keepAlive: keepAlive);
}

class VoyagerWidgetState extends State<VoyagerStatefulWidget>
    with AutomaticKeepAliveClientMixin<VoyagerStatefulWidget> {
  String _path;
  Voyager _voyager;
  final keepAlive;
  RouterNG _lastRouter;

  VoyagerWidgetState({this.keepAlive});

  @override
  void initState() {
    super.initState();
    _path = widget.path;
  }

  @override
  Widget build(BuildContext context) {
    if (keepAlive) {
      super.build(context); // this must be called
    }

    var hasRouterProvider = false;
    var router;
    try {
      router = Provider.of<RouterNG>(context);
      hasRouterProvider = true;
    } catch (t) {
      router = widget.router;
    }

    assert(router != null, "router instance should not be null");

    var parentVoyager;
    try {
      parentVoyager = Provider.of<Voyager>(context);
    } catch (t) {
      parentVoyager = null;
    }

    if (_voyager == null || _lastRouter != router) {
      _lastRouter = router;
      _voyager = _lastRouter.find(_path, parent: parentVoyager);
    }

    assert(_voyager != null, "voyager instance should not be null");

    final builder = _voyager[WidgetPlugin.KEY];

    assert(builder != null,
        "WidgetBuilder of _voyager should not be null, did you forget to add WidgetPlugin?");

    if (hasRouterProvider) {
      return Provider<Voyager>.value(
        value: _voyager,
        child: Builder(builder: builder),
      );
    } else {
      return MultiProvider(
        providers: [
          Provider<Voyager>.value(value: _voyager),
          Provider<RouterNG>.value(value: router)
        ],
        child: Builder(builder: builder),
      );
    }
  }

  @override
  void didUpdateWidget(VoyagerStatefulWidget oldWidget) {
    if (oldWidget.path != widget.path || oldWidget.router != widget.router) {
      _path = widget.path;
      _voyager = null;
      _lastRouter = null;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get wantKeepAlive => keepAlive;
}
