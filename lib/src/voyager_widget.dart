import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import 'voyager.dart';
import 'plugins/screen_plugin.dart';

/// Widget that allows you embed any path anywhere in the widget tree. The requirement is router
/// supplied in the costructor (e.g. if this is a top widget) or available via `VoyagerProvider.routerOf(context)`
/// Additionally you might want to set `keepAlive` to true if you embed this in e.g. `TabBarView`
class VoyagerWidget extends StatefulWidget {
  final String path;
  final bool keepAlive;
  final RouterNG router;

  VoyagerWidget({this.path, this.keepAlive = false, this.router});

  @override
  State<StatefulWidget> createState() =>
      VoyagerWidgetState(keepAlive: keepAlive);

  static VoyagerWidget fromPath(BuildContext context, String path) =>
      VoyagerWidget(path: path, router: Provider.of<RouterNG>(context));
}

class VoyagerWidgetState extends State<VoyagerWidget>
    with AutomaticKeepAliveClientMixin<VoyagerWidget> {
  String _path;
  final keepAlive;
  RouterNG _router;
  Voyager _voyager;

  VoyagerWidgetState({this.keepAlive});

  @override
  void initState() {
    super.initState();
    _router = widget.router;
    _path = widget.path;
  }

  @override
  Widget build(BuildContext context) {
    if (keepAlive) {
      super.build(context); // this must be called
    }
    final router = _router ?? Provider.of<RouterNG>(context);
    final parentVoyager = _router == null ? Provider.of<Voyager>(context) : null;

    _voyager = _voyager ?? router.find(_path, parent: parentVoyager);

    assert(_voyager != null, "voyager instance should not be null");

    final builder = ScreenProvider.ofVoyager(_voyager);

    assert(builder != null,
        "WidgetBuilder of _voyager should not be null, did you forget to add ScreenPlugin?");

    final child = builder(context);

    assert(child != null, "WidgetBuilder failed to create widget");

    return MultiProvider(
      providers: [
        Provider<Voyager>.value(value: _voyager),
        Provider<RouterNG>.value(value: router)
      ],
      child: child,
    );
  }

  @override
  void didUpdateWidget(VoyagerWidget oldWidget) {
    if (oldWidget.path != widget.path) {
      setState(() {
        _path = widget.path;
        _voyager = null;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get wantKeepAlive => keepAlive;
}
