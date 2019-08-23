import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

const navigationYaml = '''
'/list' :
  type: 'list'
  widget: ListWidget
  title: "Voyager Talks"
  items:
    - city: "Berlin"
      event: Droidcon
      date: July 1, 2019
    - city: "London"
      event: FlutterLDN
      date: October 21, 2019
    - city: "Łódź"
      event: Mobilization
      date: October 26, 2019
'/_object/:className':
  type: object_item
  widget: "%{className}Widget"
''';

class ListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voyager = Provider.of<Voyager>(context);
    final String title = voyager["title"];

    // ignore: avoid_as
    final talks = (voyager["items"] as List<dynamic>)
        .toList()
        .map((dynamic item) => Talk(item["city"], item["event"], item["date"]))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: VoyagerListView(talks, idMapper, objectMapper, null),
        floatingActionButton: voyager["fabPath"] != null
            ? VoyagerWidget(
                path: voyager["fabPath"],
              )
            : null);
  }

  // ignore: avoid_as
  static String idMapper(dynamic item) => (item as Talk).city;
  static String objectMapper(dynamic item) =>
      "/_object/${item.runtimeType.toString()}";
}

class Talk {
  const Talk(this.city, this.event, this.date);
  final String city;
  final String event;
  final String date;
}

class TalkWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Talk talk = Provider.of<VoyagerArgument>(context).value;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(talk.city,
                style: TextStyle(
                    fontSize: 20,
                    color: theme.accentColor,
                    fontWeight: FontWeight.bold)),
            Text(talk.event, style: const TextStyle(fontSize: 16)),
            Text(talk.date, style: const TextStyle(fontSize: 14)),
          ],
        ));
  }
}

void main() {
  testWidgets('create VoyagerList with dynamic Items',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final paths = loadPathsFromString(navigationYaml);
      final plugins = [
        WidgetPluginBuilder()
            .add<ListWidget>((_) => ListWidget())
            .add<TalkWidget>((_) => TalkWidget())
            .build()
      ];

      final router = await loadRouter(paths, plugins);

      expect(router, isInstanceOf<RouterNG>());

      await tester.pumpWidget(
          MaterialApp(home: VoyagerWidget(path: "/list", router: router)));

      expect(find.text("Berlin"), findsOneWidget);
      expect(find.text("Łódź"), findsOneWidget);
      expect(find.text("London"), findsOneWidget);
    });
  });
}
