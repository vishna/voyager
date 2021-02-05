/// Generated file, DO NOT EDIT
// ignore_for_file: public_member_api_docs
part of 'main.dart';

const String pathObjectTalk = "/_object/Talk";
const String typeObjectTalk = "_object_Talk";
const String pathFab = "/fab";
const String typeFab = "fab";
const String pathHome = "/home";
const String typeHome = "home";
String pathNotfound(String notfound) {
  return "/$notfound";
}

const String typeNotfound = "notfound";
String pathOtherTitle(String title) {
  return "/other/$title";
}

const String typeOtherTitle = "other_title";
const String pathStaySafe = "/stay/safe";
const String typeStaySafe = "stay_safe";
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
  "TalkWidget": (context) => TalkWidget(),
  "makeMeFab": makeMeFab,
  "PageWidget": (context) => PageWidget(),
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
