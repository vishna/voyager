// import 'package:example/main.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:voyager/voyager.dart';

// import 'gen/voyager_test_scenarios.dart';

// class TestScenarios extends VoyagerTestScenarios {
//   /// we need to wrap tested widget with MaterialApp so that e.g.
//   /// MediaQuery.of(context) works
//   TestScenarios()
//       : super((widget, router, scenarios) => MaterialApp(home: widget));

//   @override
//   List<VoyagerTestFabScenario> fabScenarios() {
//     return [
//       VoyagerTestFabScenario.write((WidgetTester tester) async {
//         final icon = find.byType(Icon);
//         final iconBox = tester.renderObject<RenderBox>(icon);
//         expect(iconBox.size, const Size(24.0, 24.0));
//         final widget = icon.evaluate().first.widget;
//         expect(widget, isInstanceOf<Icon>());
//         final Icon iconWidget = widget;
//         expect(iconWidget.icon,
//             const IconData(0xE88F, fontFamily: 'MaterialIcons'));
//       })
//     ];
//   }

//   @override
//   List<VoyagerTestHomeScenario> homeScenarios() {
//     return [
//       VoyagerTestHomeScenario.write((WidgetTester tester) async {
//         expect(find.text("This is Home"), findsOneWidget);
//         expect(find.text("Hello World"), findsOneWidget);
//       })
//     ];
//   }

//   @override
//   List<VoyagerTestOtherScenario> otherScenarios() {
//     return [
//       VoyagerTestOtherScenario.write("thing", (WidgetTester tester) async {
//         expect(find.text("Welcome to the other side"), findsOneWidget);
//         expect(find.text("This is thing"), findsOneWidget);
//       }),
//       VoyagerTestOtherScenario.write("thingy", (WidgetTester tester) async {
//         expect(find.text("Welcome to the other side"), findsOneWidget);
//         expect(find.text("This is thingy"), findsOneWidget);
//       })
//     ];
//   }

//   @override
//   List<VoyagerTestTalksScenario> talksScenarios() {
//     return [
//       VoyagerTestTalksScenario.write((WidgetTester tester) async {
//         expect(find.text("Berlin"), findsOneWidget);
//         expect(find.text("London"), findsOneWidget);
//         expect(find.text("Łódź"), findsOneWidget);
//       })
//     ];
//   }

//   @override
//   List<VoyagerTestObjectItemScenario> objectItemScenarios() {
//     return [
//       VoyagerTestObjectItemScenario.write("Talk", (WidgetTester tester) async {
//         expect(find.text("Mountain View"), findsOneWidget);
//       },
//           argument: const Talk("Mountain View", "Google I/O 2020", "19 May"),
//           stateless: true)
//     ];
//   }
// }

import 'package:flutter_test/flutter_test.dart';

void main() {
  // final router = loadRouter(paths(), plugins());
  // voyagerAutomatedTests("voyager auto tests", router, TestScenarios());
  test("dummy 3.0", () {});
}
