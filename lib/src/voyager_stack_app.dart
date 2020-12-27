import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

/// Provides declarative API on top of Navigator 2.0
/// and Voyager library
class VoyagerStackApp extends StatefulWidget {
  /// default constructor
  const VoyagerStackApp({
    Key? key,
    required this.router,
    required this.createApp,
    required this.stack,
    required this.onBackPressed,
    this.onNewPage,
    this.onInitialPage,
    this.routeType = VoyagerRouteType.material,
  }) : super(key: key);

  /// router instance
  final VoyagerRouter router;

  /// declarative stack
  final VoyagerStack stack;

  /// handle back event
  final VoidCallback onBackPressed;

  /// triggered when new page event happens on system level
  final void Function(VoyagerStackItem page)? onNewPage;

  /// triggered when initial page event happens on system level
  final void Function(VoyagerStackItem page)? onInitialPage;

  /// route type (material or cupertino)
  final VoyagerRouteType routeType;

  /// pass [parser] and [delegate] to [MaterialApp.router] or [CupertinoApp.router]
  final Widget Function(
    BuildContext context,
    VoyagerInformationParser parser,
    VoyagerDelegate delegate,
  ) createApp;

  @override
  _VoyagerStackAppState createState() => _VoyagerStackAppState();
}

class _VoyagerStackAppState extends State<VoyagerStackApp> {
  late VoyagerDelegate delegate;
  late VoyagerInformationParser parser;

  @override
  void initState() {
    super.initState();
    delegate = VoyagerDelegate(
      widget.router,
      onBackPressed: widget.onBackPressed,
      onNewPage: widget.onNewPage,
      routeType: widget.routeType,
      onInitialPage: widget.onInitialPage,
    );
    delegate.stack = widget.stack;
    parser = const VoyagerInformationParser();
  }

  @override
  void didUpdateWidget(VoyagerStackApp oldWidget) {
    if (oldWidget.stack != widget.stack) {
      delegate.stack = widget.stack;
    }
    if (oldWidget.onBackPressed != widget.onBackPressed) {
      delegate.onBackPressed = widget.onBackPressed;
    }
    if (oldWidget.router != widget.router) {
      delegate.router = widget.router;
    }
    if (oldWidget.routeType != widget.routeType) {
      delegate.routeType = widget.routeType;
    }
    if (oldWidget.onNewPage != widget.onNewPage) {
      delegate.onNewPage = widget.onNewPage;
    }
    if (oldWidget.onInitialPage != widget.onInitialPage) {
      delegate.onInitialPage = widget.onInitialPage;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Provider<VoyagerRouter>.value(
      value: widget.router,
      child: Builder(builder: (context) {
        return widget.createApp(context, parser, delegate);
      }),
    );
  }
}