import 'package:flutter/foundation.dart';
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
    this.defaultPageBuilder = PagePlugin.defaultMaterial,
    this.transitionDelegate = const DefaultTransitionDelegate<dynamic>(),
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

  /// default page builder (e.g. material or cupertino)
  final VoyagerPageBuilder defaultPageBuilder;

  /// transition delegate
  final TransitionDelegate transitionDelegate;

  /// pass [parser] and [delegate] to [MaterialApp.router] or [CupertinoApp.router]
  final Widget Function(
    BuildContext context,
    VoyagerInformationParser parser,
    VoyagerDelegate delegate,
  ) createApp;

  @override
  _VoyagerStackAppState createState() => _VoyagerStackAppState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<VoyagerStack>('stack', stack));
  }
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
      defaultPageBuilder: widget.defaultPageBuilder,
      onInitialPage: widget.onInitialPage,
    );
    delegate.stack = widget.stack;
    delegate.transitionDelegate = widget.transitionDelegate;
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
    if (oldWidget.defaultPageBuilder != widget.defaultPageBuilder) {
      delegate.defaultPageBuilder = widget.defaultPageBuilder;
    }
    if (oldWidget.onNewPage != widget.onNewPage) {
      delegate.onNewPage = widget.onNewPage;
    }
    if (oldWidget.onInitialPage != widget.onInitialPage) {
      delegate.onInitialPage = widget.onInitialPage;
    }
    if (oldWidget.transitionDelegate != widget.transitionDelegate) {
      delegate.transitionDelegate = widget.transitionDelegate;
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
