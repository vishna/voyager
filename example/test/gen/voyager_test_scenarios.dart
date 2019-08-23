/// Generated file, DO NOT EDIT
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:test_api/test_api.dart' as test_package;
import 'package:voyager/voyager.dart';

typedef WidgetWrapper = Widget Function(Widget nonWrappedWidget);

@isTest
void _testVoyagerWidget(
  String description,
  Future<RouterNG> routerFuture,
  WidgetWrapper widgetWrapper,
  VoyagerTestScenario scenario, {
  bool skip = false,
  test_package.Timeout timeout,
  Duration initialTimeout,
  bool semanticsEnabled = false,
}) {
  testWidgets(description, (WidgetTester tester) async {
    await tester.runAsync(() async {
      final router = await routerFuture;

      expect(router, isInstanceOf<RouterNG>());

      Widget widget = VoyagerWidget(path: scenario.path(), router: router);
      widget = widgetWrapper != null ? widgetWrapper(widget) : widget;
      widget = scenario.widgetWrapper != null
          ? scenario.widgetWrapper(widget)
          : widget;

      await tester.pumpWidget(widget);

      scenario.widgetTesterCallback(tester);
    });
  },
      skip: skip,
      timeout: timeout,
      initialTimeout: initialTimeout,
      semanticsEnabled: semanticsEnabled);
}

@experimental
abstract class VoyagerTestScenario {
  VoyagerTestScenario(this.testDescription, this.widgetTesterCallback);

  final String testDescription;
  final WidgetTesterCallback widgetTesterCallback;
  WidgetWrapper widgetWrapper;

  String path();
  void addWidgetWrapper(WidgetWrapper widgetWrapper) {
    this.widgetWrapper = widgetWrapper;
  }
}

@experimental
class VoyagerTestHomeScenario extends VoyagerTestScenario {
  VoyagerTestHomeScenario.write(WidgetTesterCallback widgetTesterCallback,
      {String description = ""})
      : super(description, widgetTesterCallback);

  @override
  String path() {
    return "/home";
  }
}

@experimental
class VoyagerTestOtherScenario extends VoyagerTestScenario {
  VoyagerTestOtherScenario.write(
      this.title, WidgetTesterCallback widgetTesterCallback,
      {String description = ""})
      : super(description, widgetTesterCallback);

  final String title;

  @override
  String path() {
    return "/other/$title";
  }
}

@experimental
class VoyagerTestFabScenario extends VoyagerTestScenario {
  VoyagerTestFabScenario.write(WidgetTesterCallback widgetTesterCallback,
      {String description = ""})
      : super(description, widgetTesterCallback);

  @override
  String path() {
    return "/fab";
  }
}

@experimental
abstract class VoyagerTestScenarios {
  const VoyagerTestScenarios(this.defaultWrapper);
  final WidgetWrapper defaultWrapper;

  List<VoyagerTestHomeScenario> homeScenarios();
  List<VoyagerTestOtherScenario> otherScenarios();
  List<VoyagerTestFabScenario> fabScenarios();
}

@isTestGroup
@experimental
void voyagerAutomatedTests(String description, Future<RouterNG> router,
    VoyagerTestScenarios testScenarios,
    {bool forceTests = true}) {
  group(description, () {
    final homeScenarios = testScenarios.homeScenarios();
    if (forceTests) {
      assert(
          homeScenarios != null, "homeScenarios seems to lack implementation");
      assert(homeScenarios.isNotEmpty,
          "homeScenarios must return at least one test scenario");
    }
    homeScenarios?.asMap()?.forEach((index, scenario) {
      _testVoyagerWidget(
          "home scenario $index: path=${scenario.path()} ${scenario.testDescription}",
          router,
          testScenarios.defaultWrapper,
          scenario);
    });
    final otherScenarios = testScenarios.otherScenarios();
    if (forceTests) {
      assert(otherScenarios != null,
          "otherScenarios seems to lack implementation");
      assert(otherScenarios.isNotEmpty,
          "otherScenarios must return at least one test scenario");
    }
    otherScenarios?.asMap()?.forEach((index, scenario) {
      _testVoyagerWidget(
          "other scenario $index: path=${scenario.path()} ${scenario.testDescription}",
          router,
          testScenarios.defaultWrapper,
          scenario);
    });
    final fabScenarios = testScenarios.fabScenarios();
    if (forceTests) {
      assert(fabScenarios != null, "fabScenarios seems to lack implementation");
      assert(fabScenarios.isNotEmpty,
          "fabScenarios must return at least one test scenario");
    }
    fabScenarios?.asMap()?.forEach((index, scenario) {
      _testVoyagerWidget(
          "fab scenario $index: path=${scenario.path()} ${scenario.testDescription}",
          router,
          testScenarios.defaultWrapper,
          scenario);
    });
  });
}
