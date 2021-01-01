import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager/voyager.dart';

void main() {
  test('VoyagerStack.toPathList()', () {
    const stack1 = VoyagerStack([
      VoyagerPage("/home"),
      VoyagerPage("/settings"),
      VoyagerStack(
        [
          VoyagerPage("/omg"),
          VoyagerPage("/counter"),
          VoyagerStack(
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
    final stringCallback = () {
      stringCallbackCalled = true;
    };
    final stack1 = VoyagerStack([
      const VoyagerPage("/home"),
      const VoyagerPage("/settings"),
      VoyagerStack(
        [
          const VoyagerPage("/omg"),
          const VoyagerPage("/counter"),
          VoyagerStack(
            const [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
            scope: _MockString(
              "boo",
              stringCallback,
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
    expect(VoyagerAdapter.toJson(voyagerPage), inputReparsed.state);
  });

  test('VoyagerStack serialization', () {
    const stack1 = VoyagerStack(
      [
        VoyagerPage("/home", argument: "true"),
        VoyagerPage("/settings"),
        VoyagerStack([
          VoyagerPage("/omg"),
          VoyagerPage("/counter"),
          VoyagerStack(
            [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
          ),
        ], scope: "What is up?"),
        VoyagerPage("/that/last/thing"),
      ],
      scope: 13,
    );

    final VoyagerStack stack1DeepCopy =
        VoyagerAdapter.fromJson(VoyagerAdapter.toJson(stack1));

    expect(stack1, stack1DeepCopy);
  });

  test('VoyagerStack serialization 2', () {
    const stack1 = VoyagerStack(
      [
        VoyagerPage("/home", argument: VoyagerArgument("true")),
        VoyagerPage("/settings"),
        VoyagerStack([
          VoyagerPage("/omg"),
          VoyagerPage("/counter"),
          VoyagerStack(
            [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
          ),
        ], scope: "What is up?"),
        VoyagerPage("/that/last/thing"),
      ],
      scope: 13,
    );

    final VoyagerStack stack1DeepCopy =
        VoyagerAdapter.fromJson(VoyagerAdapter.toJson(stack1));

    expect(stack1, stack1DeepCopy);
  });

  test('VoyagerStack deserialization via VoyagerInformationParser', () async {
    const stack1 = VoyagerStack(
      [
        VoyagerPage("/home", argument: "true"),
        VoyagerPage("/settings"),
        VoyagerStack([
          VoyagerPage("/omg"),
          VoyagerPage("/counter"),
          VoyagerStack(
            [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
          ),
        ], scope: "What is up?"),
        VoyagerPage("/that/last/thing"),
      ],
      scope: 13,
    );

    final stack1Serialized = VoyagerAdapter.toJson(stack1);

    const parser = VoyagerInformationParser();
    final stack2Parsed = await parser.parseRouteInformation(
        RouteInformation(location: "/", state: stack1Serialized));

    expect(stack1, stack2Parsed);
  });

  test('VoyagerStack.toString', () {
    const stack = VoyagerStack(
      [
        VoyagerPage("/lucky", argument: "number"),
      ],
      scope: 13,
    );

    expect(stack.toString(), "VoyagerStack([VoyagerPage(/lucky, number)], 13)");
  });

  test('VoyagerStack.contains', () {
    const stack = VoyagerStack([
      VoyagerPage("/home"),
      VoyagerPage("/settings"),
      VoyagerStack(
        [
          VoyagerPage("/omg"),
          VoyagerPage("/counter"),
          VoyagerStack(
            [
              VoyagerPage("/words"),
              VoyagerPage("/matter"),
            ],
          )
        ],
      ),
      VoyagerPage("/that/last/thing"),
    ]);

    expect(stack.contains(const VoyagerPage("/home")), true);
    expect(stack.contains(const VoyagerPage("/home", id: "")), true);
    expect(stack.contains(const VoyagerPage("/home", id: "boo")), false);
    expect(stack.contains(const VoyagerPage("/matter")), true);
    expect(stack.contains(const VoyagerPage("/matters")), false);
  });
}

class _MockString implements VoyagerScopeRemovable {
  _MockString(this.value, this.onRemove);
  final String value;
  final VoidCallback onRemove;

  @override
  void onScopeRemoved() {
    onRemove.call();
  }
}
