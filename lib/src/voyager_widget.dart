import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

/// Just like [VoyagerStatelessWidget] but stateful. It has additional parameter called `keepAlive` which is usefull
/// when embedding the widget in things like `TabBarView`. Most of the time you don't want this. Retains [Voyager]
/// unless path or router changes
class VoyagerWidget extends StatefulWidget {
  /// default constructor
  const VoyagerWidget(
      {required this.path,
      this.keepAlive = false,
      this.router,
      this.argument,
      Key? key})
      : super(key: key);

  /// this widget's path
  final String path;

  /// whether or not this widget should be kept alive
  final bool keepAlive;

  /// instance or router, pass if it's not exposed via provider
  final VoyagerRouter? router;

  /// argument, if any
  final VoyagerArgument? argument;

  @override
  State<StatefulWidget> createState() =>
      _VoyagerWidgetState(keepAlive: keepAlive);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('path', path));
    properties.add(DiagnosticsProperty<VoyagerArgument>('argument', argument));
    properties.add(DiagnosticsProperty<bool>('keepAlive', keepAlive));
  }
}

class _VoyagerWidgetState extends State<VoyagerWidget>
    with AutomaticKeepAliveClientMixin<VoyagerWidget> {
  _VoyagerWidgetState({required this.keepAlive});

  Voyager? _voyager;
  final bool keepAlive;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (keepAlive) {
      super.build(context); // this must be called
    }

    VoyagerRouter router;

    if (widget.router != null) {
      router = widget.router!;
    } else {
      router = Provider.of<VoyagerRouter>(context, listen: false);
    }

    if (_voyager == null) {
      Voyager? parentVoyager;
      try {
        parentVoyager = context.voyager;
      } catch (t) {
        parentVoyager = null;
      }

      _voyager = router.find(widget.path,
          parent: parentVoyager, argument: widget.argument);
    }

    assert(_voyager != null, "voyager instance should not be null");

    final WidgetBuilder? builder = _voyager![WidgetPlugin.KEY];

    assert(builder != null,
        "WidgetBuilder of _voyager should not be null, did you forget to add WidgetPlugin?");

    return MultiProvider(
      providers: [
        Provider<Voyager>.value(value: _voyager!),
        Provider<VoyagerArgument?>.value(value: widget.argument)
      ],
      child: Builder(builder: builder!),
    );
  }

  @override
  void didUpdateWidget(VoyagerWidget oldWidget) {
    if (oldWidget.path != widget.path || oldWidget.router != widget.router) {
      _voyager?.dispose();
      _voyager = null;
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
