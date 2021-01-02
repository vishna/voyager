/// Generated file, DO NOT EDIT
// ignore_for_file: public_member_api_docs
part of 'main.dart';

const String path = "/stay/safe";
const String type = "";
const String pathFab = "/fab";
const String typeFab = "fab";
const String pathHome = "/home";
const String typeHome = "home";
String pathNotFound(String notfound) {
  return "/$notfound";
}

const String typeNotFound = "not_found";
String pathOther(String title) {
  return "/other/$title";
}

const String typeOther = "other";
const String pathTalkItem = "/_object/Talk";
const String typeTalkItem = "talk_item";
const String pathTalks = "/talks";
const String typeTalks = "talks";

extension VoyagerData on Voyager {
  String? get title => this["title"];
  String? get body => this["body"];
  String? get fabPath => this["fabPath"];
  String? get target => this["target"];
  Icon? get icon => this["icon"];
  List<dynamic>? get actions => this["actions"];
  List<dynamic>? get items => this["items"];
}

abstract class IconPluginStub extends VoyagerObjectPlugin<Icon> {
  IconPluginStub() : super("icon");
}

final generatedVoyagerWidgetMappings = <String, WidgetBuilder>{
  "makeMeFab": makeMeFab,
  "PageWidget": (context) => PageWidget(),
  "TalkWidget": (context) => TalkWidget(),
  "ListWidget": (context) => ListWidget()
};

WidgetPluginBuilder generatedVoyagerWidgetPluginBuilder() {
  final builder = WidgetPluginBuilder();
  generatedVoyagerWidgetMappings.forEach(builder.add);
  return builder;
}

WidgetPlugin generatedVoyagerWidgetPlugin() =>
    generatedVoyagerWidgetPluginBuilder().build();

final generatedVoyagerPageMappings = <String, VoyagerPageBuilder>{
  "slideFromTop": slideFromTop
};

PagePluginBuilder generatedVoyagerPagePluginBuilder() {
  final builder = PagePluginBuilder();
  generatedVoyagerPageMappings.forEach(builder.add);
  return builder;
}

PagePlugin generatedVoyagerPagePlugin() =>
    generatedVoyagerPagePluginBuilder().build();
