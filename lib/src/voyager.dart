import 'package:flutter/foundation.dart';

/// This class is a composite product of `RouterPlugin`s for the given router's path -
/// this means all the information resolved from the navigation file that is relevant to creating
/// new widget.
/// Once assembled the variables are locked - they can be read but you can't put more.
///
/// Developer might choose to use `storage` to dynamically put any variables that should be available
/// to anyone having access to that instance of `Voyager`
class Voyager {
  static const String KEY_TYPE = "type";

  final Voyager parent;
  final Map<String, dynamic> _config;
  final _output = Map<String, dynamic>();
  final storage = Map<String, dynamic>();
  final _onDispose = List<OnDispose>();
  final path;
  bool _locked = false;

  Voyager({this.path, this.parent, Map<String, dynamic> config})
      : _config = Map.from(config);

  void merge(Voyager other) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _output.addAll(other._output);
    _config.addAll(other._config);
  }

  operator [](String key) {
    dynamic value = _output[key];
    if (value != null || value == nothing) {
      return value;
    }

    return _config[key];
  }

  operator []=(String key, dynamic value) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _output[key] = value;
  }

  void onDispose(OnDispose callback) {
    if (_locked) {
      throw FlutterError("Voyager is in lockdown.");
    }
    _onDispose.add(callback);
  }

  void dispose() {
    if (!_locked) {
      throw FlutterError("Can't dispose resources before Voyager is locked");
    }
    _onDispose.forEach((callback) => callback());
    _output.clear();
    _config.clear();
  }

  lock() {
    _locked = true;
  }

  String get type => this[KEY_TYPE];

  static final Nothing nothing = Nothing._private();
}

class Nothing {
  Nothing._private();
}

typedef OnDispose = void Function();
