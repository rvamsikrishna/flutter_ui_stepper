import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math' as math;

class MyStepper extends StatefulWidget {
  final int min;
  final int max;

  const MyStepper({
    Key key,
    this.min = 0,
    this.max = 10,
  }) : super(key: key);
  @override
  _MyStepperState createState() => _MyStepperState();
}

class _MyStepperState extends State<MyStepper>
    with SingleTickerProviderStateMixin {
  final bool _isInteractive = true;
  double _currX = 0.0;
  double _center = 50.0;
  List _numbers = [];
  int _selectedIndex;
  AnimationController _controller;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    for (var i = widget.min; i <= widget.max; i++) {
      _numbers.add(i);
    }
    //just to show end of stepper we add extra member.
    _numbers.add('_');

    _controller =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this)
          ..addListener(() {
            setState(() {
              _center = lerpDouble(_center, 50.0, _controller.value);
            });
          });

    _scrollController = ScrollController(initialScrollOffset: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Offset _getGlobalToLocal(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isInteractive) {
      _currX = _getGlobalToLocal(details.globalPosition).dx / _totalWidth;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isInteractive) {
      final double valueDelta = details.primaryDelta / _totalWidth;
      _currX += valueDelta;

      _handleChanged(_clamp(_currX));
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _currX = 0.0;
    _controller.forward(from: 0.0);

    if (_center == 100.0 && _selectedIndex != _numbers.length - 2) {
      _selectedIndex += 1;
      _scrollTo(80.0 * _selectedIndex);
    } else if (_center == 0.0 && _selectedIndex != 0) {
      _selectedIndex -= 1;

      _scrollTo(80.0 * _selectedIndex);
    }
  }

  double _clamp(double value) {
    return value.clamp(0.0, 1.0);
  }

  void _handleChanged(double value) {
    final double lerpValue = _lerp(value);
    if (lerpValue != _center) {
      setState(() {
        _center = lerpValue;
      });
    }
  }

  void _scrollTo(double offset) {
    _scrollController.animateTo(
      offset,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (100.0 - 0.0) + 0.0;
  }

  // Returns a number between 0.0 and 1.0, given a value between min and max.
  double _unlerp(double value) {
    return value / 100.0;
  }

  double get _totalWidth => 180.0;
  double get _totalHeight => 80.0;

  @override
  Widget build(BuildContext context) {
//total widget can be split up as 2 equal width controls with 20.0
//fixed size between them.
//180.0 = 2 * 80.0 + 20.0.

    final double thumbDiameter = _totalHeight;
    final double thumbPosFactor = _unlerp(_center);
    double remainingWidth = _totalWidth - thumbDiameter;

    final double thumbPosLeft = lerpDouble(0.0, remainingWidth, thumbPosFactor);

    //The position of the thumb control of the slider from min value.
    final double thumbPosRight =
        lerpDouble(remainingWidth, 0.0, thumbPosFactor);

    //since from center to leftmost factor is 0.0 to 0.0...
    //so multipplied by 2
    final double leftFactor = thumbPosFactor * 2;
    final double rightFactor = leftFactor - 1;

    final double leftStickyOffset = lerpDouble(10.0, 0.0, leftFactor);
    final double rightStickyOffset = lerpDouble(0.0, 10.0, rightFactor);

    return Container(
      width: _totalWidth,
      height: _totalHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            left: 0.0,
            right: _center < 50.0
                ? lerpDouble(140.0, 100.0, leftFactor)
                : 100.0 + leftStickyOffset,
            top: 0.0,
            bottom: 0.0,
            child: Transform.rotate(
              angle: math.pi,
              child: Control(
                padding: _center < 50.0 ? leftStickyOffset : -leftStickyOffset,
                child: Icon(
                  Icons.remove,
                  size: 30.0,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          Positioned(
            left: _center > 50.0
                ? lerpDouble(100.0, 140.0, rightFactor)
                : 100.0 + rightStickyOffset,
            right: 0.0,
            top: 0.0,
            bottom: 0.0,
            child: Opacity(
              opacity: 1.0,
              child: Control(
                padding:
                    _center > 50.0 ? rightStickyOffset : -rightStickyOffset,
                child: Icon(
                  Icons.add,
                  size: 30.0,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          Positioned(
            left: _center > 50.0 ? -leftStickyOffset + 50.0 : thumbPosLeft,
            right: _center < 50.0 ? -rightStickyOffset + 50.0 : thumbPosRight,
            top: 0.0,
            bottom: 0.0,
            child: GestureDetector(
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40.0),
                ),
                child: NumbersList(
                  scrollController: _scrollController,
                  numbers: _numbers,
                  center: _center,
                  selectedIndex: _selectedIndex,
                  leftFactor: leftFactor,
                  rightFactor: rightFactor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NumbersList extends StatelessWidget {
  const NumbersList({
    Key key,
    @required ScrollController scrollController,
    @required List numbers,
    @required double center,
    @required int selectedIndex,
    @required this.leftFactor,
    @required this.rightFactor,
  })  : _scrollController = scrollController,
        _numbers = numbers,
        _center = center,
        _selectedIndex = selectedIndex,
        super(key: key);

  final ScrollController _scrollController;
  final List _numbers;
  final double _center;
  final int _selectedIndex;
  final double leftFactor;
  final double rightFactor;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      physics: NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      children: _numbers.map((i) {
        double width = 80.0;
        Alignment alignment = Alignment.center;

        if (_center < 50.0) {
          if (i == _selectedIndex - 1) {
            width = lerpDouble(120.0, 80.0, leftFactor);
            alignment = AlignmentTween(
              begin: Alignment.centerRight,
              end: Alignment.center,
            ).lerp(leftFactor);
          }
          if (i == _selectedIndex) {
            width = lerpDouble(60.0, 80.0, leftFactor);

            alignment = AlignmentTween(
              begin: Alignment.centerRight,
              end: Alignment.center,
            ).lerp(leftFactor);
          }
        } else if (_center > 50.0) {
          if (i == _selectedIndex || i == _selectedIndex + 1) {
            width = lerpDouble(80.0, 60.0, rightFactor);
          }
        }
        return Container(
          alignment: alignment,
          width: width,
          child: Text(
            i == _numbers[_numbers.length - 1] ? '' : '$i',
            style: Theme.of(context).textTheme.display1.copyWith(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      }).toList(),
    );
  }
}

class Control extends StatelessWidget {
  final Widget child;
  final double width;
  final double padding;

  const Control({
    Key key,
    this.child,
    this.width,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: ControlPainter(),
        child: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: padding + 5.0),
          child: child,
        ),
      ),
    );
  }
}

class ControlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();

    path.lineTo(size.width - 40.0, 0.0);

    path.arcToPoint(
      Offset(size.width - 40.0, size.height),
      radius: Radius.circular(40.0),
    );

    path.lineTo(0.0, size.height);

    path.arcToPoint(
      Offset(0.0, 0.0),
      radius: Radius.circular(40.0),
      clockwise: false,
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
