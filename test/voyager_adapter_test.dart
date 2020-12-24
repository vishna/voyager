import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

import 'mock_classes.dart';

void main() {
  test('VoyagerAdapter.toJson throws on unregistered type', () {
    expect(
        () => VoyagerAdapter.toJson(MockHomeWidget()),
        throwsA(predicate((e) =>
            e is StateError &&
            e.message ==
                'Missing VoyagerAdapter type `MockHomeWidget`=MockHomeWidget')));
  });

  test('VoyagerAdapter.fromJson throws on unregistered type', () {
    expect(
        () => VoyagerAdapter.fromJson(
            <String, dynamic>{"type": "boo", "data": "foo"}),
        throwsA(predicate((e) =>
            e is StateError &&
            e.message ==
                'Missing VoyagerAdapter for type `boo` in {type: boo, data: foo}')));
  });

  test('VoyagerAdapter.fromJson throws on missing data', () {
    expect(
        () => VoyagerAdapter.fromJson(
            <String, dynamic>{"type": "VoyagerStack", "data": null}),
        throwsA(predicate((e) =>
            e is StateError &&
            e.message ==
                'Missing field `data` in {type: VoyagerStack, data: null}')));
  });
}
