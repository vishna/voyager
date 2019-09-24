import 'package:flutter/widgets.dart';
import 'voyager_argument.dart';
import 'voyager_stateless_widget.dart';

/// maps item instance to its id
typedef Identifier = String Function(dynamic item);

/// maps item type to a respective voyager path
typedef PathMapper = String Function(dynamic item);

/// Voyager backed ListView with stable ids.
/// You need to provide [Identifier] which will guarantee stable item IDs
/// across updates and [PathMapper] which will map object type to a relevant
/// voyager path. The item values are injected using [VoyagerArgument].
///
/// ValueKey(s) FTW: https://medium.com/flutter-community/elements-keys-and-flutters-performance-3ef15c90f607
/// ValueKey(s) + ListView sample: https://github.com/flutter/flutter/issues/21023#issuecomment-510950338
class VoyagerListView extends StatelessWidget {
  VoyagerListView(
    List<dynamic> items,
    Identifier identifier,
    PathMapper pathMapper, {
    Key key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.cacheExtent,
    this.semanticChildCount,
  })  : _idToIndex = <String, int>{},
        _items = List<_VoyagerItem>(items.length),
        super(key: key) {
    final n = items.length;
    final duplicateCounter = <String, int>{};
    for (var index = 0; index < n; index++) {
      final dynamic item = items[index];
      final _id = identifier(item);
      final count = (duplicateCounter[_id] ?? -1) + 1;
      duplicateCounter[_id] = count;
      final id = itemKeyId(_id, duplicateNumber: count);
      final path = pathMapper(item);
      _idToIndex[id] = index;
      _items[index] = _VoyagerItem(
          argument: VoyagerArgument(item),
          path: path,
          key: ValueKey<String>(id));
    }
  }

  final Map<String, int> _idToIndex;
  final List<_VoyagerItem> _items;
  final ScrollController controller;
  final Axis scrollDirection;
  final bool reverse;
  final bool primary;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;
  final double itemExtent;
  final double cacheExtent;
  final int semanticChildCount;

  @override
  Widget build(BuildContext context) {
    return ListView.custom(
      physics: physics,
      controller: controller,
      childrenDelegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final item = _items[index];
            return VoyagerStatelessWidget(
                path: item.path,
                useCache: true,
                argument: item.argument,
                key: item.key);
          },
          childCount: _items.length,
          findChildIndexCallback: (Key key) {
            final ValueKey valueKey = key;
            final String id = valueKey.value;
            return _idToIndex[id];
          }),
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: itemExtent,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
    );
  }

  static String itemKeyId(String itemId, {int duplicateNumber = 0}) =>
      "$duplicateNumber:$itemId";
}

class _VoyagerItem {
  const _VoyagerItem({this.argument, this.path, this.key});
  final VoyagerArgument argument;
  final ValueKey key;
  final String path;
}
