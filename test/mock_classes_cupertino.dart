import 'package:flutter/cupertino.dart';
import 'package:voyager/voyager.dart';

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
      child: const Center(
        child: Text("Home Page"),
      ),
    );
  }
}

class MockCupertinoOtherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String title = context.voyager["title"];

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
        ),
        child: const Center(
          child: Text("Other Page"),
        ));
  }
}
