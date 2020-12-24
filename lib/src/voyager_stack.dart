import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

// ignore_for_file: avoid_as

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

/// Voyager's implementation of navigation parser. Essentially translates
/// [RouteInformation] to/from [VoyagerPage]
class VoyagerInformationParser
    extends RouteInformationParser<VoyagerStackItem> {
  /// default constructor
  const VoyagerInformationParser();

  @override
  Future<VoyagerStackItem> parseRouteInformation(
      RouteInformation routeInformation) async {
    if (routeInformation.state != null) {
      return VoyagerAdapter.fromJson(
          routeInformation.state as Map<String, dynamic>);
    }
    return VoyagerPage(routeInformation.location!);
  }

  @override
  RouteInformation restoreRouteInformation(VoyagerStackItem configuration) {
    final paths = configuration.toPathList();

    return RouteInformation(
        location: paths.isNotEmpty ? paths.last : null,
        state: VoyagerAdapter.toJson(configuration));
  }
}

/// an outcome of parsing [RouteInformation]
@immutable
class VoyagerPage extends Equatable implements VoyagerStackItem {
  /// default constructor
  const VoyagerPage(this.path, {this.argument});

  /// path representing this page
  final String path;

  /// page argument
  final VoyagerArgument? argument;

  @override
  List<Page> toList(VoyagerRouter router, VoyagerPageBuilder pageBuilder,
      {List<Object>? scopes}) {
    var innerPageBuilder = pageBuilder;
    if (scopes != null && scopes.isNotEmpty) {
      innerPageBuilder = (widget, key) {
        final widgetWithScope = Provider<VoyagerScope>.value(
          value: VoyagerScope(scopes),
          child: widget,
        );
        return pageBuilder(widgetWithScope, key);
      };
    }

    final widget = VoyagerWidget(
      path: path,
      router: router,
      argument: argument,
    );

    final key = ValueKey(path);

    return [innerPageBuilder(widget, key)];
  }

  @override
  List<String> toPathList() => [path];

  /// [VoyagerPage] serialization adapter
  static final adapter = VoyagerAdapter<VoyagerPage>(serialize: (dynamic page) {
    return <String, dynamic>{
      "path": page.path,
      "argument": VoyagerAdapter.toJson(page.argument?.value)
    };
  }, deserialize: (json) {
    final String path = json["path"];
    final dynamic? argumentValue =
        VoyagerAdapter.fromJson(json["argument"] as Map<String, dynamic>?);
    return VoyagerPage(path,
        argument:
            argumentValue != null ? VoyagerArgument(argumentValue) : null);
  });

  @override
  List<Object?> get props => [path, argument?.value];

  @override
  bool? get stringify => true;
}

/// Voyager delegate for the Navigator 2.0 [Router]
class VoyagerDelegate extends RouterDelegate<VoyagerStackItem>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<VoyagerStackItem> {
  /// default constructor
  VoyagerDelegate(this._voyagerRouter,
      {VoyagerStack? initialStack,
      this.onBackPressed,
      this.onNewPage,
      this.onInitialPage,
      VoyagerRouteType routeType = VoyagerRouteType.material,
      GlobalKey<NavigatorState>? navigatorKey})
      : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _routeType = routeType,
        _stack = initialStack ?? const VoyagerStack([]);

  /// global navigator key used by this delegate
  @override
  final GlobalKey<NavigatorState> navigatorKey;
  VoyagerRouter _voyagerRouter;
  VoyagerRouteType _routeType;

  /// if you want to handle back press manually, provide a callback here,
  /// otherwise [VoyagerStack.removeLast] method is used
  VoidCallback? onBackPressed;

  /// pass this to intecept [setNewRoutePath]
  void Function(VoyagerStackItem page)? onNewPage;

  /// pass this to intecept [setInitialRoutePath]
  /// Kind of WORKAROUND for initialPath
  /// https://github.com/flutter/flutter/issues/71106
  void Function(VoyagerStackItem page)? onInitialPage;

  VoyagerStack _stack;

  /// returns an immutable instance of current navigation stack
  VoyagerStack get stack => _stack;

  /// sets new navigation stack for this delegate
  set stack(VoyagerStack value) {
    if (value == _stack) {
      return;
    }
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
  Future<void> setInitialRoutePath(VoyagerStackItem configuration) async {
    if (onInitialPage != null) {
      onInitialPage!(configuration);
      return;
    }
    await super.setInitialRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(VoyagerStackItem configuration) async {
    if (onNewPage != null) {
      onNewPage!(configuration);
      return;
    }
    stack = stack.mutate((stackInfo) {
      stackInfo.add(configuration);
    });
  }

  @override
  VoyagerStackItem? get currentConfiguration => _stack;
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
      VoyagerRouter router, VoyagerPageBuilder pageBuilder,
      {List<Object>? scopes});

  /// converts the stack to a list of paths
  List<String> toPathList();
}

/// respresents the state of navigation
@immutable
class VoyagerStack extends Equatable implements VoyagerStackItem {
  /// default constructor
  const VoyagerStack(this._items, {Object? scope}) : _scope = scope;
  final List<VoyagerStackItem> _items;
  final Object? _scope;

  /// creates a new copy of [VoyagerStack] with applied [mutation]
  VoyagerStack mutate(void Function(List<VoyagerStackItem> items) mutation) {
    final _newItems = List<VoyagerStackItem>.from(_items);
    mutation(_newItems);
    return VoyagerStack(_newItems, scope: _scope);
  }

  /// whether or not this stack is empty
  bool get isEmpty => _items.isEmpty;

  /// should be called whenever this stack is removed
  void onRemove() {
    final s = _scope;
    if (s is VoyagerScopeRemovable) {
      s.onScopeRemoved();
    }
  }

  /// removes last item of the stack and if it's an instance of [VoyagerStack]
  /// calls a [VoyagerStackScope.onRemove] if it's registered
  VoyagerStack removeLast() {
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
      VoyagerRouter router, VoyagerPageBuilder pageBuilder,
      {List<Object>? scopes}) {
    final pages = <Page<dynamic>>[];
    if (_scope != null) {
      scopes = List<Object>.from(scopes ?? <Object>[]);
      scopes.add(_scope!);
    }
    for (final item in _items) {
      pages.addAll(item.toList(router, pageBuilder, scopes: scopes));
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

  /// [VoyagerStack] serialization adapter
  static final adapter =
      VoyagerAdapter<VoyagerStack>(serialize: (dynamic stack) {
    return <String, dynamic>{
      "items":
          stack._items.map((dynamic it) => VoyagerAdapter.toJson(it)).toList(),
      "scope": VoyagerAdapter.toJson(stack._scope)
    };
  }, deserialize: (json) {
    final dynamic? scope =
        VoyagerAdapter.fromJson(json["scope"] as Map<String, dynamic>?);
    final itemsJson = json['items'] as List<dynamic>;
    final items = itemsJson
        .map<dynamic>((dynamic it) => VoyagerAdapter.fromJson(it))
        .toList()
        .cast<VoyagerStackItem>();
    return VoyagerStack(items, scope: scope);
  });

  @override
  List<Object?> get props => [_items, _scope];

  @override
  bool? get stringify => true;
}

/// a [VoyagerStack] can expose a scope to all its items
class VoyagerScope {
  /// default constructor
  const VoyagerScope(this.values);

  /// scope value
  final List<dynamic> values;
}

/// [VoyagerStack] extension on build context
extension VoyagerStackScopeContextExtension on BuildContext {
  /// obtain a [T] value via [VoyagerStackScope] provided in the given [BuildContext]
  T voyagerScope<T>() => Provider.of<VoyagerScope>(this, listen: false)
      .values
      .firstWhere((dynamic it) => it is T);
}

/// use this interface to free up scope if necessary
abstract class VoyagerScopeRemovable {
  /// on scope removed callback
  void onScopeRemoved();
}
