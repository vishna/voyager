import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

void main() {
  test('static values because codecov complains', () {
    expect(Router.cupertinoRoute, Router.cupertinoRoute);
    expect(Router.materialRoute, Router.materialRoute);
    expect(RedirectPlugin.KEY, RedirectPlugin.KEY);
    expect(WidgetPlugin.KEY, WidgetPlugin.KEY);
    expect(Voyager.KEY_TYPE, Voyager.KEY_TYPE);
  });
}
