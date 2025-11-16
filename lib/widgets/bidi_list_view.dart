import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BidiListView extends StatelessWidget {
  BidiListView.builder({
    super.key,
    this.scrollDirection = Axis.vertical,
    BidiScrollController? controller,
    this.physics,
    this.padding,
    this.itemExtent,
    required IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    int? negativeItemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    this.anchor = 0.0,
    this.cacheExtent,
  }) : positiveChildrenDelegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ),
       negativeChildrenDelegate = SliverChildBuilderDelegate(
         (BuildContext context, int index) => itemBuilder(context, -1 - index),
         childCount: negativeItemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ),
       controller = controller ?? BidiScrollController();

  BidiListView.separated({
    super.key,
    this.scrollDirection = Axis.vertical,
    BidiScrollController? controller,
    this.physics,
    this.padding,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    int? itemCount,
    int? negativeItemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    this.cacheExtent,
    this.anchor = 0.0,
  }) : itemExtent = null,
       positiveChildrenDelegate = SliverChildBuilderDelegate(
         (BuildContext context, int index) {
           final itemIndex = index ~/ 2;
           return index.isEven
               ? itemBuilder(context, itemIndex)
               : separatorBuilder(context, itemIndex);
         },
         childCount: itemCount != null ? math.max(0, itemCount * 2 - 1) : null,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ),
       negativeChildrenDelegate = SliverChildBuilderDelegate(
         (BuildContext context, int index) {
           final itemIndex = (-1 - index) ~/ 2;
           return index.isOdd
               ? itemBuilder(context, itemIndex)
               : separatorBuilder(context, itemIndex);
         },
         childCount: negativeItemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
       ),
       controller = controller ?? BidiScrollController();

  final Axis scrollDirection;

  final BidiScrollController controller;

  final ScrollPhysics? physics;

  final EdgeInsets? padding;

  final double? itemExtent;

  final double? cacheExtent;

  final double anchor;

  final SliverChildDelegate negativeChildrenDelegate;

  final SliverChildDelegate positiveChildrenDelegate;

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = _buildSlivers(context, negative: false);
    final List<Widget> negativeSlivers = _buildSlivers(context, negative: true);
    final AxisDirection axisDirection = _getDirection(context);
    final scrollPhysics = AlwaysScrollableScrollPhysics(parent: physics);
    return Scrollable(
      axisDirection: axisDirection,
      controller: controller,
      physics: scrollPhysics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return Builder(
          builder: (BuildContext context) {
            final state = Scrollable.of(context);
            final negativeOffset = BidiScrollPosition(
              physics: scrollPhysics,
              context: state,
              initialPixels: -offset.pixels,
              keepScrollOffset: controller.keepScrollOffset,
              negativeScroll: true,
            );

            offset.addListener(() {
              negativeOffset._forceNegativePixels(offset.pixels);
            });

            return Stack(
              children: <Widget>[
                Viewport(
                  axisDirection: flipAxisDirection(axisDirection),
                  anchor: 1.0 - anchor,
                  offset: negativeOffset,
                  slivers: negativeSlivers,
                  cacheExtent: cacheExtent,
                ),
                Viewport(
                  axisDirection: axisDirection,
                  anchor: anchor,
                  offset: offset,
                  slivers: slivers,
                  cacheExtent: cacheExtent,
                ),
              ],
            );
          },
        );
      },
    );
  }

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(
      context,
      scrollDirection,
      false,
    );
  }

  List<Widget> _buildSlivers(BuildContext context, {bool negative = false}) {
    Widget sliver;
    if (itemExtent != null) {
      sliver = SliverFixedExtentList(
        delegate: negative
            ? negativeChildrenDelegate
            : positiveChildrenDelegate,
        itemExtent: itemExtent!,
      );
    } else {
      sliver = SliverList(
        delegate: negative
            ? negativeChildrenDelegate
            : positiveChildrenDelegate,
      );
    }
    if (padding != null) {
      sliver = SliverPadding(
        padding: negative
            ? padding! - EdgeInsets.only(bottom: padding!.bottom)
            : padding! - EdgeInsets.only(top: padding!.top),
        sliver: sliver,
      );
    }
    return <Widget>[sliver];
  }
}

class BidiScrollController extends ScrollController {
  BidiScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return BidiScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class BidiScrollPosition extends ScrollPositionWithSingleContext {
  BidiScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    ScrollPosition? oldPosition,
    super.debugLabel,
    this.negativeScroll = false,
  }) {
    if (oldPosition != null) {
      _minScrollExtent = oldPosition.minScrollExtent;
      _maxScrollExtent = oldPosition.maxScrollExtent;
    }
  }

  @override
  double get minScrollExtent => _minScrollExtent;
  double _minScrollExtent = 0.0;

  @override
  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent = 0.0;

  final bool negativeScroll;

  void _forceNegativePixels(double value) {
    super.forcePixels(-value);
  }

  void setMinMaxExtent(double minExtent, double maxExtent) {
    _minScrollExtent = minExtent;
    _maxScrollExtent = maxExtent;
  }

  @override
  void saveScrollOffset() {
    if (!negativeScroll) {
      super.saveScrollOffset();
    }
  }

  @override
  void restoreScrollOffset() {
    if (!negativeScroll) {
      super.restoreScrollOffset();
    }
  }
}
