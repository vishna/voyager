import 'package:voyager/voyager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// allows wrapping widget around navigator returned by [VoyagerDelegate]
typedef VoyagerDelegateNavigatorWrapper = Widget Function(
    BuildContext context, Navigator navigator, VoyagerDelegate delegate);

/// Voyager delegate for the Navigator 2.0 [Router]
class VoyagerDelegate extends RouterDelegate<VoyagerStackItem>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<VoyagerStackItem> {
  /// default constructor
  VoyagerDelegate(this._voyagerRouter,
      {VoyagerStack? initialStack,
      this.onBackPressed,
      this.onNewPage,
      this.onInitialPage,
      VoyagerPageBuilder defaultPageBuilder = PagePlugin.defaultMaterial,
      VoyagerDelegateNavigatorWrapper? navigatorWrapper,
      GlobalKey<NavigatorState>? navigatorKey})
      : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _defaultPageBuilder = defaultPageBuilder,
        _navigatorWrapper = navigatorWrapper,
        _stack = initialStack ?? const VoyagerStack([]);

  /// global navigator key used by this delegate
  @override
  final GlobalKey<NavigatorState> navigatorKey;
  VoyagerRouter _voyagerRouter;
  VoyagerPageBuilder _defaultPageBuilder;

  /// if you want to handle back press manually, provide a callback here,
  /// otherwise [VoyagerStack.removeLast] method is used
  VoidCallback? onBackPressed;

  /// pass this to intecept [setNewRoutePath]
  void Function(VoyagerStackItem page)? onNewPage;

  /// pass this to intecept [setInitialRoutePath]
  /// Kind of WORKAROUND for initialPath
  /// https://github.com/flutter/flutter/issues/71106
  void Function(VoyagerStackItem page)? onInitialPage;

  /// wrap custom widget around delegate's default [Navigator]
  VoyagerDelegateNavigatorWrapper? _navigatorWrapper;

  /// set navigator wrapper
  set navigatorWrapper(VoyagerDelegateNavigatorWrapper? value) {
    if (value == _navigatorWrapper) {
      return;
    }
    _navigatorWrapper = value;
    notifyListeners();
  }

  TransitionDelegate _transitionDelegate =
      const DefaultTransitionDelegate<dynamic>();

  /// set transition delegate
  set transitionDelegate(TransitionDelegate value) {
    if (value == _transitionDelegate) {
      return;
    }
    _transitionDelegate = value;
    notifyListeners();
  }

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
  VoyagerPageBuilder get defaultPageBuilder => _defaultPageBuilder;

  /// update router instance for this delegate
  set defaultPageBuilder(VoyagerPageBuilder value) {
    _defaultPageBuilder = value;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    final wrapper = _navigatorWrapper;
    final navigator = Navigator(
      key: navigatorKey,
      transitionDelegate: _transitionDelegate,
      pages: _stack.asPages(_voyagerRouter,
          defaultPageBuilder: _defaultPageBuilder),
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

    if (wrapper == null) {
      return navigator;
    } else {
      return wrapper(context, navigator, this);
    }
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
          // ignore: avoid_as
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
