import 'package:flutter/material.dart' hide Router;
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

/// Just like [VoyagerStatelessWidget] but stateful. It has additional parameter called `keepAlive` which is usefull
/// when embedding the widget in things like `TabBarView`. Most of the time you don't want this. Retains [Voyager]
/// unless path or router changes
class VoyagerWidget extends StatefulWidget {
  const VoyagerWidget(
      {@required this.path,
      this.keepAlive = false,
      this.router,
      this.argument,
      Key key})
      : super(key: key);
  final String path;
  final bool keepAlive;
  final Router router;
  final VoyagerArgument argument;

  @override
  State<StatefulWidget> createState() =>
      _VoyagerWidgetState(keepAlive: keepAlive);
}

class _VoyagerWidgetState extends State<VoyagerWidget>
    with AutomaticKeepAliveClientMixin<VoyagerWidget> {
  _VoyagerWidgetState({this.keepAlive});
  String _path;
  Voyager _voyager;
  final bool keepAlive;
  Router _lastRouter;

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
    Router router;
    try {
      router = Provider.of<Router>(context, listen: false);
      hasRouterProvider = true;
    } catch (t) {
      router = widget.router;
    }

    assert(router != null, "router instance should not be null");

    Voyager parentVoyager;
    try {
      parentVoyager = context.voyager;
    } catch (t) {
      parentVoyager = null;
    }

    if (_voyager == null || _lastRouter != router) {
      _lastRouter = router;
      _voyager = _lastRouter.find(_path,
          parent: parentVoyager, argument: widget.argument);
    }

    assert(_voyager != null, "voyager instance should not be null");

    final WidgetBuilder builder = _voyager[WidgetPlugin.KEY];

    assert(builder != null,
        "WidgetBuilder of _voyager should not be null, did you forget to add WidgetPlugin?");

    return MultiProvider(
      providers: [
        Provider<Voyager>.value(value: _voyager),
        if (!hasRouterProvider) Provider<Router>.value(value: router),
        if (widget.argument != null)
          Provider<VoyagerArgument>.value(value: widget.argument)
      ],
      child: Builder(builder: builder),
    );
  }

  @override
  void didUpdateWidget(VoyagerWidget oldWidget) {
    if (oldWidget.path != widget.path || oldWidget.router != widget.router) {
      _path = widget.path;
      _voyager = null;
      _lastRouter = null;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _voyager?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => keepAlive;
}
