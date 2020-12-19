/// Generated file, DO NOT EDIT
// ignore_for_file: public_member_api_docs
import 'package:flutter/widgets.dart';
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
