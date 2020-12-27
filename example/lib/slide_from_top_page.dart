import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:voyager/voyager.dart';

/// slide from top page animation
class SlideFromTopPage extends Page<dynamic> {
  /// default constructor
  SlideFromTopPage(this._widget, VoyagerPage _page)
      : super(key: _page.key, arguments: _page.argument, name: _page.path);
  final Widget _widget;

  @override
  Route createRoute(BuildContext context) => _SlideFromTopRoute(_widget, this);
}

class _SlideFromTopRoute extends PageRouteBuilder<dynamic> {
  _SlideFromTopRoute(this.widget, RouteSettings settings)
      : super(
            settings: settings,
            pageBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return widget;
            },
            transitionsBuilder: (BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            });

  final Widget widget;
}
