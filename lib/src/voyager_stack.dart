import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:voyager/voyager.dart';

// ignore_for_file: avoid_as

/// wrap [VoyagerWidget] with a [Page]
typedef VoyagerPageBuilder = Page<dynamic> Function(
    Widget widget, ValueKey key);

/// an outcome of parsing [RouteInformation]
@immutable
class VoyagerPage extends Equatable implements VoyagerStackItem {
  /// default constructor
  const VoyagerPage(this.path, {this.argument, this.id = ""});

  /// path representing this page
  final String path;

  /// page argument
  final VoyagerArgument? argument;

  /// extra id (e.g. if you want to have duplicate entries on the stack)
  final String id;

  @override
  List<Page> toList(VoyagerRouter router, VoyagerPageBuilder pageBuilder,
      {List<Object>? scopes}) {
    var innerPageBuilder = pageBuilder;
    if (scopes != null && scopes.isNotEmpty) {
      innerPageBuilder = (widget, key) {
        final widgetWithScope = Provider<VoyagerScope>.value(
          value: VoyagerScope(scopes),
          child: widget,
        );
        return pageBuilder(widgetWithScope, key);
      };
    }

    final widget = VoyagerWidget(
      path: path,
      router: router,
      argument: argument,
    );

    final key = ValueKey("$id#$path");

    return [innerPageBuilder(widget, key)];
  }

  @override
  List<String> toPathList() => [path];

  /// [VoyagerPage] serialization adapter
  static final adapter = VoyagerAdapter<VoyagerPage>(serialize: (dynamic page) {
    return <String, dynamic>{
      "path": page.path,
      "argument": VoyagerAdapter.toJson(page.argument?.value),
      "id": page.id,
    };
  }, deserialize: (json) {
    final String path = json["path"];
    final String id = json["id"];
    final dynamic? argumentValue =
        VoyagerAdapter.fromJson(json["argument"] as Map<String, dynamic>?);
    return VoyagerPage(path,
        id: id,
        argument:
            argumentValue != null ? VoyagerArgument(argumentValue) : null);
  });

  @override
  List<Object?> get props => [path, argument?.value];

  @override
  bool? get stringify => true;
}

/// voyager stack basic building bloc
abstract class VoyagerStackItem {
  /// converts the state to a list that can be used by e.g. [Navigator]
  List<Page<dynamic>> toList(
      VoyagerRouter router, VoyagerPageBuilder pageBuilder,
      {List<Object>? scopes});

  /// converts the stack to a list of paths
  List<String> toPathList();
}

/// respresents the state of navigation
@immutable
class VoyagerStack extends Equatable implements VoyagerStackItem {
  /// default constructor
  const VoyagerStack(this._items, {Object? scope}) : _scope = scope;
  final List<VoyagerStackItem> _items;
  final Object? _scope;

  /// creates a new copy of [VoyagerStack] with applied [mutation]
  VoyagerStack mutate(void Function(List<VoyagerStackItem> items) mutation) {
    final _newItems = List<VoyagerStackItem>.from(_items);
    mutation(_newItems);
    return VoyagerStack(_newItems, scope: _scope);
  }

  /// whether or not this stack is empty
  bool get isEmpty => _items.isEmpty;

  /// should be called whenever this stack is removed
  void onRemove() {
    final s = _scope;
    if (s is VoyagerScopeRemovable) {
      s.onScopeRemoved();
    }
  }

  /// removes last item of the stack and if it's an instance of [VoyagerStack]
  /// calls a [VoyagerStackScope.onRemove] if it's registered
  VoyagerStack removeLast() {
    if (_items.isEmpty) {
      return this;
    }
    final stack = mutate((items) {
      var lastItem = items.last;
      final lastIndex = items.length - 1;
      if (lastItem is VoyagerStack) {
        lastItem = lastItem.removeLast();
        if (lastItem.isEmpty) {
          lastItem.onRemove();
          items.removeLast();
        } else {
          items[lastIndex] = lastItem;
        }
      } else {
        items.removeLast();
      }
    });
    return stack;
  }

  /// converts the state to a list that can be used by e.g. [Navigator]
  @override
  List<Page<dynamic>> toList(
      VoyagerRouter router, VoyagerPageBuilder pageBuilder,
      {List<Object>? scopes}) {
    final pages = <Page<dynamic>>[];
    if (_scope != null) {
      scopes = List<Object>.from(scopes ?? <Object>[]);
      scopes.add(_scope!);
    }
    for (final item in _items) {
      pages.addAll(item.toList(router, pageBuilder, scopes: scopes));
    }
    return pages;
  }

  @override
  List<String> toPathList() {
    final paths = <String>[];
    for (final item in _items) {
      paths.addAll(item.toPathList());
    }
    return paths;
  }

  /// check if this stack contains the given page
  /// (match by [VoyagerPage.path] and [VoyagerPage.id])
  bool contains(VoyagerPage page) {
    for (final item in _items) {
      if (item is VoyagerStack && item.contains(page)) {
        return true;
      } else if (item is VoyagerPage &&
          page.id == item.id &&
          page.path == item.path) {
        return true;
      }
    }
    return false;
  }

  /// [VoyagerStack] serialization adapter
  static final adapter =
      VoyagerAdapter<VoyagerStack>(serialize: (dynamic stack) {
    return <String, dynamic>{
      "items":
          stack._items.map((dynamic it) => VoyagerAdapter.toJson(it)).toList(),
      "scope": VoyagerAdapter.toJson(stack._scope)
    };
  }, deserialize: (json) {
    final dynamic? scope =
        VoyagerAdapter.fromJson(json["scope"] as Map<String, dynamic>?);
    final itemsJson = json['items'] as List<dynamic>;
    final items = itemsJson
        .map<dynamic>((dynamic it) => VoyagerAdapter.fromJson(it))
        .toList()
        .cast<VoyagerStackItem>();
    return VoyagerStack(items, scope: scope);
  });

  @override
  List<Object?> get props => [_items, _scope];

  @override
  bool? get stringify => true;
}

/// a [VoyagerStack] can expose a scope to all its items
class VoyagerScope {
  /// default constructor
  const VoyagerScope(this.values);

  /// scope value
  final List<dynamic> values;
}

/// [VoyagerStack] extension on build context
extension VoyagerStackScopeContextExtension on BuildContext {
  /// obtain a [T] value via [VoyagerStackScope] provided in the given [BuildContext]
  T voyagerScope<T>() => Provider.of<VoyagerScope>(this, listen: false)
      .values
      .firstWhere((dynamic it) => it is T);
}

/// use this interface to free up scope if necessary
abstract class VoyagerScopeRemovable {
  /// on scope removed callback
  void onScopeRemoved();
}
