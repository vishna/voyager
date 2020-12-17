import 'package:flutter/material.dart';
import 'package:voyager/voyager.dart';

class MockHomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Title"),
      ),
      body: const Center(
        child: Text("Home Page"),
      ),
      floatingActionButton: mockFab(context),
    );
  }
}

Widget mockFab(BuildContext context) {
  return FloatingActionButton(
    onPressed: () {
      Navigator.of(context).pushNamed("/other/thing");
    },
    tooltip: 'Navigate',
    child: const Icon(Icons.add),
  );
}

class MockOtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String title = context.voyager["title"];

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: const Center(
          child: Text("Other Page"),
        ));
  }
}

class MockOtherWidgetWithArgument extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String title = context.voyager["title"];
    assert(context.voyagerArgument != null);

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: const Center(
          child: Text("Other Page"),
        ));
  }
}

class MockHomeWidgetArgument1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Title"),
      ),
      body: const Center(
        child: Text("Home Page"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed("/other/thing", arguments: "hello");
        },
        tooltip: 'Navigate',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MockHomeWidgetArgument2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Title"),
      ),
      body: const Center(
        child: Text("Home Page"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .pushNamed("/other/thing", arguments: VoyagerArgument("hello"));
        },
        tooltip: 'Navigate',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CustomVoyager extends Voyager {
  CustomVoyager(String path, Voyager? parent)
      : super(path: path, parent: parent, config: <String, dynamic>{});

  set widget(WidgetBuilder builder) {
    this[WidgetPlugin.KEY] = builder;
  }

  set title(String value) {
    this["title"] = value;
  }

  String get title => this["title"];
}
