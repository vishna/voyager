import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

void main() {
  test(
      'VoyagerUtils.interpolate() interpolates string containg %{} with a given value',
      () {
    final interpolatedValue =
        VoyagerUtils.interpolate("Hello %{name}!", {"name": "World"});
    expect(interpolatedValue, "Hello World!");
  });

  test('interpolate dynamic list or map', () {
    RouterContext context = RouterContext(params: {"foo": "Hello"});

    final list = [
      "%{foo} World",
      {"world_key": "%{foo} World"}
    ];
    VoyagerUtils.interpolateList(list, context);

    expect(
        list,
        containsAllInOrder([
          "Hello World",
          {"world_key": "Hello World"}
        ]));
  });

  test('tuple detection', () {
    expect(VoyagerUtils.isTuple("something"), false);
    expect(VoyagerUtils.isTuple(4), false);
    expect(VoyagerUtils.isTuple(["something", 4]), false);
    expect(VoyagerUtils.isTuple({"something": 4}), true);
    expect(
        VoyagerUtils.isTuple({
          "something": [4, 5]
        }),
        true);
    expect(
        VoyagerUtils.isTuple({
          "something": [4, 5],
          "otherthing": 2
        }),
        false);
  });

  test('tuple extraction', () {
    expect(() => VoyagerUtils.tuple("something"), throwsA(predicate((e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
    expect(() => VoyagerUtils.tuple("4"), throwsA(predicate((e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
    expect(() => VoyagerUtils.tuple(["something", 4]), throwsA(predicate((e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
    _expectEntry(
        VoyagerUtils.tuple({"something": 4}), MapEntry("something", 4));
    _expectEntry(
        VoyagerUtils.tuple({
          "something": [4, 5]
        }),
        MapEntry("something", [4, 5]));
    expect(
        () => VoyagerUtils.tuple({
              "something": [4, 5],
              "otherthing": 2
            }), throwsA(predicate((e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
  });
}

/// whoops https://github.com/dart-lang/sdk/issues/32559
_expectEntry(MapEntry actual, MapEntry expected) {
  expect(actual.key, expected.key);
  expect(actual.value, expected.value);
}
