import 'dart:math';

import 'package:flutter/widgets.dart';

class FlipTransition extends AnimatedWidget {
  /// The [turns] argument must not be null.
  const FlipTransition({
    Key key,
    this.axis = Axis.vertical,
    @required Animation<double> turns,
    this.child,
  }) : assert(turns != null),
      super(key: key, listenable: turns);

  Animation<double> get turns => listenable as Animation<double>;

  final Axis axis;
  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double turnsValue = turns.value * -pi + pi;
    var tilt = ((turnsValue - 0.5 * pi).abs() - 0.5 * pi) * 0.003;
    final value = min(turnsValue, pi / 2);
    return Transform(
      transform: axis == Axis.horizontal
        ? (Matrix4.rotationY(value)..setEntry(3, 0, tilt))
        : (Matrix4.rotationX(value)..setEntry(3, 1, tilt)),
      child: child,
      alignment: Alignment.center,
    );
  }
}