import 'package:flutter/cupertino.dart';
import 'package:voyager/voyager.dart';
import 'package:provider/provider.dart';

class MockCupertinoHomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Home Title"),
        trailing: CupertinoButton(
          onPressed: () {
            Navigator.of(context).pushNamed("/other/thing");
          },
          child: const Text("Navigate"),
        ),
      ),
      child: Center(
        child: const Text("Home Page"),
      ),
    );
  }
}

class MockCupertinoOtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String title = Provider.of<Voyager>(context)["title"];

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
        ),
        child: Center(
          child: const Text("Other Page"),
        ));
  }
}
