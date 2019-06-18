import 'package:flutter/material.dart';
import 'package:voyager/voyager.dart';
import 'package:provider/provider.dart';

class MockHomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Home Title"),
        ),
        body: Center(
          child: Text("Home Page"),
        ));
  }
}

class MockOtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = Provider.of<Voyager>(context)["title"];

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text("Other Page"),
        ));
  }
}

class MockTitlePlugin extends RouterPlugin {
  MockTitlePlugin() : super("title");

  @override
  void outputFor(RouterContext context, dynamic config, Voyager output) {
    output["title"] = config.toString();
  }
}
