import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

/// wrap [VoyagerWidget] with a [Page]
typedef VoyagerPageBuilder = Page<dynamic> Function(
    Widget widget, ValueKey key);

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
    this.ignoreInitialPath = true,
    this.routeType = VoyagerRouteType.material,
  }) : super(key: key);

  /// router instance
  final VoyagerRouter router;

  /// declarative stack
  final VoyagerStack stack;

  /// handle back event
  final VoidCallback onBackPressed;

  /// triggered when new page event happens on system level (e.g. initial path)
  final void Function(VoyagerPage page)? onNewPage;

  /// route type (material or cupertino)
  final VoyagerRouteType routeType;

  /// initial path
  final bool ignoreInitialPath;

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
      ignoreInitialPath: widget.ignoreInitialPath,
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

/// Voyager's implementation of navigation parser. Essentially translates
/// [RouteInformation] to/from [VoyagerPage]
class VoyagerInformationParser extends RouteInformationParser<VoyagerPage> {
  /// default constructor
  const VoyagerInformationParser();
  //final VoyagerRouter _router;

  @override
  Future<VoyagerPage> parseRouteInformation(
      RouteInformation routeInformation) async {
    return VoyagerPage(routeInformation.location!);
  }

  @override
  RouteInformation restoreRouteInformation(VoyagerPage configuration) {
    return RouteInformation(location: configuration.path);
  }
}

/// an outcome of parsing [RouteInformation]
@immutable
class VoyagerPage implements VoyagerStackItem {
  /// default constructor
  const VoyagerPage(this.path, {this.argument});

  /// path representing this page
  final String path;

  /// page argument
  final VoyagerArgument? argument;

  @override
  List<Page> toList(VoyagerRouter router, VoyagerPageBuilder pageBuilder) {
    final widget = VoyagerWidget(
      path: path,
      router: router,
      argument: argument,
    );

    final key = ValueKey(path);

    return [pageBuilder(widget, key)];
  }

  @override
  List<String> toPathList() => [path];
}

/// Voyager delegate for the Navigator 2.0 [Router]
class VoyagerDelegate extends RouterDelegate<VoyagerPage>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<VoyagerPage> {
  /// default constructor
  VoyagerDelegate(this._voyagerRouter,
      {List<VoyagerPage>? initialStackPages,
      this.onBackPressed,
      this.onNewPage,
      this.ignoreInitialPath = true,
      VoyagerRouteType routeType = VoyagerRouteType.material,
      GlobalKey<NavigatorState>? navigatorKey})
      : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _routeType = routeType,
        _stack = VoyagerStack<dynamic>(initialStackPages ?? []);

  /// global navigator key used by this delegate
  @override
  final GlobalKey<NavigatorState> navigatorKey;
  VoyagerRouter _voyagerRouter;
  VoyagerRouteType _routeType;

  /// if you want to handle back press manually, provide a callback here,
  /// otherwise [VoyagerStack.removeLast] method is used
  VoidCallback? onBackPressed;

  /// pass this to intecept [setNewRoutePath]
  void Function(VoyagerPage page)? onNewPage;

  VoyagerStack _stack;

  /// returns an immutable instance of current navigation stack
  VoyagerStack get stack => _stack;

  /// WORKAROUND for initialPath
  /// https://github.com/flutter/flutter/issues/71106
  final bool ignoreInitialPath;

  /// sets new navigation stack for this delegate
  set stack(VoyagerStack value) {
    _stack = value;
    notifyListeners();
  }

  /// update router instance for this delegate
  set router(VoyagerRouter value) {
    _voyagerRouter = value;
    notifyListeners();
  }

  /// returns current default routeType for this delegate
  VoyagerRouteType get routeType => _routeType;

  /// update router instance for this delegate
  set routeType(VoyagerRouteType value) {
    _routeType = value;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _stack.toList(
          _voyagerRouter,
          _routeType == VoyagerRouteType.material
              ? _defaultMaterial
              : _defaultCupertino),
      onPopPage: (route, dynamic result) {
        if (!route.didPop(result)) {
          return false;
        }

        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          // Update the list of pages by removing the last page
          stack = stack.removeLast();
        }

        return true;
      },
    );
  }

  @override
  Future<void> setInitialRoutePath(VoyagerPage configuration) async {
    if (!ignoreInitialPath) {
      await super.setInitialRoutePath(configuration);
    }
  }

  @override
  Future<void> setNewRoutePath(VoyagerPage configuration) async {
    if (onNewPage != null) {
      onNewPage!(configuration);
      return;
    }
    stack = stack.mutate((stackInfo) {
      stackInfo.add(configuration);
    });
  }
}

Page<dynamic> _defaultMaterial(Widget widget, ValueKey key) {
  return MaterialPage<dynamic>(
    key: key,
    child: widget,
  );
}

Page<dynamic> _defaultCupertino(Widget widget, ValueKey key) {
  return CupertinoPage<dynamic>(
    key: key,
    child: widget,
  );
}

/// voyager stack basic building bloc
abstract class VoyagerStackItem {
  /// converts the state to a list that can be used by e.g. [Navigator]
  List<Page<dynamic>> toList(
      VoyagerRouter router, VoyagerPageBuilder pageBuilder);

  /// converts the stack to a list of paths
  List<String> toPathList();
}

/// respresents the state of navigation
@immutable
class VoyagerStack<T> implements VoyagerStackItem {
  /// default constructor
  const VoyagerStack(this._items, {VoyagerStackScope<T>? scope})
      : _scope = scope;
  final List<VoyagerStackItem> _items;
  final VoyagerStackScope<T>? _scope;

  /// creates a new copy of [VoyagerStack] with applied [mutation]
  VoyagerStack<T> mutate(void Function(List<VoyagerStackItem> items) mutation) {
    final _newItems = List<VoyagerStackItem>.from(_items);
    mutation(_newItems);
    return VoyagerStack<T>(_newItems, scope: _scope);
  }

  /// whether or not this stack is empty
  bool get isEmpty => _items.isEmpty;

  /// should be called whenever this stack is removed
  void onRemove() {
    if (_scope != null && _scope!.onRemove != null) {
      _scope!.onRemove!(_scope!.value);
    }
  }

  /// removes last item of the stack and if it's an instance of [VoyagerStack]
  /// calls a [VoyagerStackScope.onRemove] if it's registered
  VoyagerStack<T> removeLast() {
    if (_items.isEmpty) {
      return this;
    }
    final stack = mutate((items) {
      var lastItem = items.last;
      final lastIndex = items.length - 1;
      if (lastItem is VoyagerStack) {
        lastItem = lastItem.removeLast();
        if (lastItem.isEmpty) {
          lastItem.onRemove();
          items.removeLast();
        } else {
          items[lastIndex] = lastItem;
        }
      } else {
        items.removeLast();
      }
    });
    return stack;
  }

  /// converts the state to a list that can be used by e.g. [Navigator]
  @override
  List<Page<dynamic>> toList(
      VoyagerRouter router, VoyagerPageBuilder pageBuilder) {
    final pages = <Page<dynamic>>[];
    var innerPageBuilder = pageBuilder;
    if (_scope != null) {
      innerPageBuilder = (widget, key) {
        final widgetWithScope = Provider<VoyagerStackScope<T>>.value(
          value: _scope!,
          child: widget,
        );
        return pageBuilder(widgetWithScope, key);
      };
    }
    for (final item in _items) {
      pages.addAll(item.toList(router, innerPageBuilder));
    }
    return pages;
  }

  @override
  List<String> toPathList() {
    final paths = <String>[];
    for (final item in _items) {
      paths.addAll(item.toPathList());
    }
    return paths;
  }
}

/// a [VoyagerStack] can expose a scope to all its items
class VoyagerStackScope<T> {
  /// default constructor
  const VoyagerStackScope(this.value, {this.onRemove});

  /// scope value
  final T value;

  /// callback for when value is removed from stack
  final void Function(T value)? onRemove;
}

/// VoyagerDelegate extension on build context
extension VoyagerStackScopeContextExtension on BuildContext {
  /// obtain a [T] value via [VoyagerStackScope] provided in the given [BuildContext]
  T voyagerScope<T>() =>
      Provider.of<VoyagerStackScope<T>>(this, listen: false).value;
}
