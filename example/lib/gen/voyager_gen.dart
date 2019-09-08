/// Generated file, DO NOT EDIT
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

class VoyagerPaths {
  static const String pathHome = "/home";
  static const String typeHome = "home";
  static String pathOther(String title) {
    return "/other/$title";
  }

  static const String typeOther = "other";
  static const String pathFab = "/fab";
  static const String typeFab = "fab";
  static const String pathList = "/list";
  static const String typeList = "list";
  static String pathObjectItem(String className) {
    return "/_object/$className";
  }

  static const String typeObjectItem = "object_item";
}

class VoyagerData {
  VoyagerData(this.voyager);
  final Voyager voyager;

  String get type => voyager.type;
  String get title => voyager["title"];
  String get body => voyager["body"];
  String get fabPath => voyager["fabPath"];
  String get target => voyager["target"];
  Icon get icon => voyager["icon"];
  List<dynamic> get actions => voyager["actions"];
  List<dynamic> get items => voyager["items"];

  // ignore: prefer_constructors_over_static_methods
  static VoyagerData of(BuildContext context) {
    final voyager = Provider.of<Voyager>(context);
    VoyagerData data = voyager.storage["VoyagerData"];
    if (data == null) {
      data = VoyagerData(voyager);
      voyager.storage["VoyagerData"] = data;
    }
    return data;
  }
}

abstract class IconPluginStub extends RouterObjectPlugin<Icon> {
  IconPluginStub() : super("icon");
}
