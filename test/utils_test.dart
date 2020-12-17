import 'package:flutter_test/flutter_test.dart';
import 'package:sprintf/sprintf.dart';
import 'package:voyager/voyager.dart';

void main() {
  test("sprintf sanity", () {
    // argnum starts at 1
    expect(sprintf("Hello %1\$s!", ["World"]), "Hello World!");
  });

  test(
      'VoyagerUtils.interpolate() interpolates string containg %{} with a given value',
      () {
    final interpolatedValue = VoyagerUtils.interpolate(
        "Hello %{name}!", <String, String>{"name": "World"});
    expect(interpolatedValue, "Hello World!");
  });

  test('interpolate dynamic list or map', () {
    final context = VoyagerContext(
      params: {"foo": "Hello"},
      path: "/mock/path",
      router: VoyagerRouter(),
    );

    final list = [
      "%{foo} World",
      {"world_key": "%{foo} World"}
    ];
    VoyagerUtils.interpolateList(list, context);

    expect(
        list,
        containsAllInOrder(<dynamic>[
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
    expect(() => VoyagerUtils.tuple("something"), throwsA(predicate((Error e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
    expect(() => VoyagerUtils.tuple("4"), throwsA(predicate((Error e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
    expect(() => VoyagerUtils.tuple(["something", 4]),
        throwsA(predicate((Error e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
    _expectEntry(VoyagerUtils.tuple({"something": 4}),
        const MapEntry<String, int>("something", 4));
    _expectEntry(
        VoyagerUtils.tuple({
          "something": [4, 5]
        }),
        const MapEntry<String, dynamic>("something", [4, 5]));
    expect(
        () => VoyagerUtils.tuple({
              "something": [4, 5],
              "otherthing": 2
            }), throwsA(predicate((Error e) {
      expect(e, isInstanceOf<ArgumentError>());
      return true;
    })));
  });

  test('VoyagerUtils.cleanUrl()', () {
    expect(VoyagerUtils.cleanUrl("/home"), "home");
    expect(VoyagerUtils.cleanUrl("home"), "home");
    expect(VoyagerUtils.cleanUrl("/home/"), "home");
    expect(VoyagerUtils.cleanUrl("home/"), "home");

    expect(VoyagerUtils.cleanUrl("/"), "");
    expect(VoyagerUtils.cleanUrl(""), "");
    expect(VoyagerUtils.cleanUrl("//"), "");
  });

  test('VoyagerUtils - obfuscation', () {
    expect(VoyagerUtils.stringTypeOf<bool>(), "bool");
    VoyagerUtils.addObfuscationMap({bool: "xyz"});
    expect(VoyagerUtils.stringTypeOf<bool>(), "xyz");
  });
}

/// whoops https://github.com/dart-lang/sdk/issues/32559
void _expectEntry(MapEntry actual, MapEntry expected) {
  expect(actual.key, expected.key);
  expect(actual.value, expected.value);
}
