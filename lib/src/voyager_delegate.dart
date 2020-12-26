import 'package:voyager/voyager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
