/// Generated file, DO NOT EDIT
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

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
String pathObjectItem(String className) {
  return "/_object/$className";
}

const String typeObjectItem = "object_item";

class VoyagerData extends Voyager {
  VoyagerData({String path, Voyager parent, Map<String, dynamic> config})
      : super(path: path, parent: parent, config: config);

  String get title => this["title"];
  String get body => this["body"];
  String get fabPath => this["fabPath"];
  String get target => this["target"];
  Icon get icon => this["icon"];
  List<dynamic> get actions => this["actions"];
  List<dynamic> get items => this["items"];
}

class VoyagerProvider {
  static VoyagerData of(BuildContext context) => Provider.of<Voyager>(context);
}

VoyagerData voyagerDataFactory(
        AbstractRouteContext abstractContext, Map<String, dynamic> config) =>
    VoyagerData(
        path: abstractContext.url(),
        parent: abstractContext.getExtras().parent,
        config: config);

abstract class IconPluginStub extends RouterObjectPlugin<Icon> {
  IconPluginStub() : super("icon");
}
