import 'package:flutter/widgets.dart';
import 'voyager.dart';
import 'router.dart';

/// A Flutter widget which provides a voyager instance to its children via `VoyagerProvider.of(context)`.
/// It is used as a DI widget so that a single instance of a bloc can be provided
/// to multiple widgets within a subtree.
class VoyagerProvider extends InheritedWidget {
  /// The [Voyager] which is to be made available throughout the subtree
  final Voyager voyager;

  /// The [Router] which is to be made available throughout the subtree
  final RouterNG router;

  /// The [Widget] and its descendants which will have access to the [Voyager].
  final Widget child;

  VoyagerProvider({
    Key key,
    @required this.voyager,
    @required this.router,
    @required this.child,
  })  : assert(voyager != null),
        assert(child != null),
        super(key: key);

  /// Method that allows widgets to access the bloc as long as their `BuildContext`
  /// contains a `VoyagerProvider` instance.
  static Voyager of(BuildContext context) {
    final type = _typeOf<VoyagerProvider>();
    final VoyagerProvider provider =
        context.ancestorInheritedElementForWidgetOfExactType(type)?.widget;

    if (provider == null) {
      throw FlutterError(
          'VoyagerProvider.of() called with a context that does not contain a Voyager.\n'
          '  $context');
    }
    return provider?.voyager;
  }

  /// Method that allows widgets to access the bloc as long as their `BuildContext`
  /// contains a `VoyagerProvider` instance.
  static RouterNG routerOf(BuildContext context) {
    final type = _typeOf<VoyagerProvider>();
    final VoyagerProvider provider =
        context.ancestorInheritedElementForWidgetOfExactType(type)?.widget;

    if (provider == null) {
      throw FlutterError(
          'VoyagerProvider.of() called with a context that does not contain a Voyager.\n'
          '  $context');
    }
    return provider?.router;
  }

  /// Necessary to obtain generic [Type]
  /// https://github.com/dart-lang/sdk/issues/11923
  static Type _typeOf<T>() => T;

  @override
  bool updateShouldNotify(VoyagerProvider oldWidget) => false;
}
