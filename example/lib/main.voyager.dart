/// Generated file, DO NOT EDIT
// ignore_for_file: public_member_api_docs
part of 'main.dart';

const String pathHome = "/home";
const String typeHome = "home";
String pathOther(String title) {
  return "/other/$title";
}

const String typeOther = "other";
const String pathFab = "/fab";
const String typeFab = "fab";
const String pathTalks = "/talks";
const String typeTalks = "talks";
const String pathTalkItem = "/_object/Talk";
const String typeTalkItem = "talk_item";
const String path = "/stay/safe";
const String type = "";
String pathNotFound(String notfound) {
  return "/$notfound";
}

const String typeNotFound = "not_found";

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
  "PageWidget": (context) => PageWidget(),
  "makeMeFab": makeMeFab,
  "ListWidget": (context) => ListWidget(),
  "TalkWidget": (context) => TalkWidget()
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
