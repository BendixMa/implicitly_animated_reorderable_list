import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src.dart';

/// A Handle is used to initiate a drag/reorder of an item inside an
/// [ImplicitlyAnimatedReorderableList].
///
/// A Handle must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
/// as its ancestor.
class Handle extends StatefulWidget {
  /// The child of this Handle that can initiate a reorder.
  ///
  /// This might for instance be an [Icon] or a [ListTile].
  final Widget child;

  /// The delay between when a pointer touched the [child] and
  /// when the drag is initiated.
  ///
  /// If the Handle wraps the whole item, the delay should be greater
  /// than `Duration.zero` as otherwise the list might become unscrollable.
  ///
  /// When the [ImplicitlyAnimatedReorderableList] was scrolled in the mean time,
  /// the reorder will be canceled.
  /// If the [ImplicitlyAnimatedReorderableList] uses a `NeverScrollableScrollPhysics`
  /// the Handle will instead use a parent `Scrollable` if there is one.
  final Duration delay;

  /// Whether to vibrate when a drag has been initiated.
  final bool vibrate;
  
  /// True if this item is draggable.
  final bool draggable;

  /// Creates a widget that can initiate a drag/reorder of an item inside an
  /// [ImplicitlyAnimatedReorderableList].
  ///
  /// A Handle must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
  /// as its ancestor.
  const Handle({
    Key key,
    @required this.child,
    this.delay = Duration.zero,
    this.vibrate = true,
	this.draggable = true,
  })  : assert(delay != null),
        assert(child != null),
        assert(vibrate != null),
		assert(draggable != null),
        super(key: key);

  @override
  _HandleState createState() => _HandleState();
}

class _HandleState extends State<Handle> {
  ScrollableState _scrollable;
  // A custom handler used to cancel the pending onDragStart callbacks.
  Handler _handler;
  // The parent Reorderable item.
  ReorderableState _reorderable;
  // The parent list.
  ImplicitlyAnimatedReorderableListState _list;
  // Whether the ImplicitlyAnimatedReorderableList has a
  // scrollDirection of Axis.vertical.
  bool get _isVertical => _list?.isVertical ?? true;

  double _initialOffset;
  double _currentOffset;
  double get _delta => (_currentOffset ?? 0) - (_initialOffset ?? 0);

  // Use flags from the list as this State object is being
  // recreated between dragged and normal state.
  bool get _inDrag => _list.inDrag ?? false;
  bool get _inReorder => _list.inReorder ?? false;

  void _onDragStarted(Offset pointer) {
    _removeScrollListener();

    // If the list is already in drag we dont want to
    // initiate a new reorder.
    if (_inReorder) return;

    _initialOffset = _isVertical ? pointer.dy : pointer.dx;

    _list?.onDragStarted(_reorderable?.key);
    _reorderable.rebuild();

    _vibrate();
  }

  void _onDragUpdated(Offset pointer) {
    _currentOffset = _isVertical ? pointer.dy : pointer.dx;
    _list?.onDragUpdated(_delta);
  }

  void _onDragEnded() {
    _handler?.cancel();
    _list?.onDragEnded();
  }

  void _vibrate() {
    if (widget.vibrate) HapticFeedback.mediumImpact();
  }

  // A Handle should only initiate a reorder when the list didn't change it scroll
  // position in the meantime.

  bool get _useParentScrollable {
    final hasParent = _scrollable != null;
    final physics = _list?.widget?.physics;

    return hasParent &&
        physics != null &&
        physics is NeverScrollableScrollPhysics;
  }

  void _addScrollListener() {
    if (widget.delay > Duration.zero) {
      if (_useParentScrollable) {
        _scrollable.position.addListener(_cancelReorder);
      } else {
        _list?.scrollController?.addListener(_cancelReorder);
      }
    }
  }

  void _removeScrollListener() {
    if (widget.delay > Duration.zero) {
      if (_useParentScrollable) {
        _scrollable.position.removeListener(_cancelReorder);
      } else {
        _list?.scrollController?.removeListener(_cancelReorder);
      }
    }
  }

  void _cancelReorder() {
    _handler?.cancel();
    _removeScrollListener();

    if (_inDrag) _onDragEnded();
  }

  @override
  Widget build(BuildContext context) {
    _list ??= ImplicitlyAnimatedReorderableList.of(context);
    assert(_list != null,
        'No ancestor ImplicitlyAnimatedReorderableList was found in the hierarchy!');
    _reorderable ??= Reorderable.of(context);
    assert(_reorderable != null,
        'No ancestor Reorderable was found in the hierarchy!');
    _scrollable = Scrollable.of(_list.context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final pointer = event.localPosition;

        // Ensure the list is not already in a reordering
        // state when initiating a new reorder operation.
        if (!_inDrag && draggable) {
          _cancelReorder();

          _addScrollListener();
          _handler = postDuration(
            widget.delay,
            () => _onDragStarted(pointer),
          );
        }
      },
      onPointerMove: (event) {
        final pointer = event.localPosition;

        if (_inDrag && _inReorder) {
          _onDragUpdated(pointer);
        }
      },
      onPointerUp: (_) => _cancelReorder(),
      onPointerCancel: (_) => _cancelReorder(),
      child: widget.child,
    );
  }
}
