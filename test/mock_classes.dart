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
      ),
      floatingActionButton: _makeMeFab(context),
    );
  }
}

Widget _makeMeFab(BuildContext context) {
  return FloatingActionButton(
    onPressed: () {
      Navigator.of(context).pushNamed("/other/thing");
    },
    tooltip: 'Navigate',
    child: Icon(Icons.add),
  );
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
