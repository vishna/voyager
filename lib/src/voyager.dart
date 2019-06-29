import 'package:flutter/foundation.dart';

/// This class is a composite product of `RouterPlugin`s for the given router's path -
/// this means all the information resolved from the navigation file that is relevant to creating
/// new widget.
/// Once assembled the variables are locked - they can be read but you can't put more.
///
/// Developer might choose to use `storage` to dynamically put any variables that should be available
/// to anyone having access to that instance of `Voyager`
class Voyager {
  final Voyager parent;
  final dynamic _config;
  final _output = Map<String, dynamic>();
  final storage = Map<String, dynamic>();
  bool _locked = false;

  Voyager({this.parent, dynamic config}) : _config = config;

  void merge(Voyager other) {
    _output.addAll(other._output);
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

  lock() {
    _locked = true;
  }

  static final Nothing nothing = Nothing._private();
}

class Nothing {
   Nothing._private();
}
