import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

void main() {
  test('VoyagerStack type check', () {
    const a = VoyagerStack<dynamic>([]);
    const b = VoyagerStack<int>([]);
    const c = VoyagerStack<String>([]);

    expect(a is VoyagerStack, true);
    expect(b is VoyagerStack, true);
    expect(c is VoyagerStack, true);

    expect(a is VoyagerStack<dynamic>, true);
    expect(b is VoyagerStack<dynamic>, true);
    expect(c is VoyagerStack<dynamic>, true);

    expect(a is VoyagerStack<String>, false);
    expect(b is VoyagerStack<String>, false);
    expect(c is VoyagerStack<String>, true);

    expect(a is VoyagerStack<int>, false);
    expect(b is VoyagerStack<int>, true);
    expect(c is VoyagerStack<int>, false);
  });

  test('VoyagerStack.toPathList()', () {
    const stack1 = VoyagerStack<dynamic>([
      VoyagerPage("/home"),
      VoyagerPage("/settings"),
      VoyagerStack<int>(
        [
          VoyagerPage("/omg"),
          VoyagerPage("/counter"),
          VoyagerStack<String>(
            [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
          )
        ],
      ),
      VoyagerPage("/that/last/thing"),
    ]);

    expect(stack1.toPathList(), [
      "/home",
      "/settings",
      "/omg",
      "/counter",
      "/words",
      "/matter",
      "/that/last/thing"
    ]);
  });

  test('VoyagerStack.removeLast', () {
    var stringCallbackCalled = false;
    final stringCallback = (String value) {
      expect(value, "boo");
      stringCallbackCalled = true;
    };
    final stack1 = VoyagerStack<dynamic>([
      const VoyagerPage("/home"),
      const VoyagerPage("/settings"),
      VoyagerStack<int>(
        [
          const VoyagerPage("/omg"),
          const VoyagerPage("/counter"),
          VoyagerStack<String>(
            const [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
            scope: VoyagerStackScope(
              "boo",
              onRemove: stringCallback,
            ),
          ),
        ],
      ),
      const VoyagerPage("/that/last/thing"),
    ]);

    expect(stringCallbackCalled, false);
    expect(stack1.toPathList(), [
      "/home",
      "/settings",
      "/omg",
      "/counter",
      "/words",
      "/matter",
      "/that/last/thing"
    ]);
    expect(stack1.isEmpty, false);

    final stack2 = stack1.removeLast();
    expect(stringCallbackCalled, false);
    expect(stack2.toPathList(), [
      "/home",
      "/settings",
      "/omg",
      "/counter",
      "/words",
      "/matter",
    ]);
    expect(stack2.isEmpty, false);

    final stack3 = stack2.removeLast();
    expect(stringCallbackCalled, false);
    expect(stack3.toPathList(), [
      "/home",
      "/settings",
      "/omg",
      "/counter",
      "/words",
    ]);
    expect(stack3.isEmpty, false);

    final stack4 = stack3.removeLast();
    expect(stringCallbackCalled, true);
    expect(stack4.toPathList(), [
      "/home",
      "/settings",
      "/omg",
      "/counter",
    ]);
    expect(stack4.isEmpty, false);

    final stack5 =
        stack4.removeLast().removeLast().removeLast().removeLast().removeLast();
    expect(stringCallbackCalled, true);
    expect(stack5.toPathList(), <String>[]);
    expect(stack5.isEmpty, true);
  });

  test('VoyagerInformation parser', () async {
    const parser = VoyagerInformationParser();
    const input = RouteInformation(location: "/home");
    final voyagerPage = await parser.parseRouteInformation(input);
    final inputReparsed = parser.restoreRouteInformation(voyagerPage);

    expect(input.location, inputReparsed.location);
    expect(input.state, inputReparsed.state);
  });
}
