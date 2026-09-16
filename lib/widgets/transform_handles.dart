import 'package:flutter/material.dart';

class TransformHandles extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback? onTopLeft;
  final VoidCallback? onTopRight;
  final VoidCallback? onBottomLeft;
  final VoidCallback? onBottomRight;

  const TransformHandles({
    super.key,
    required this.width,
    required this.height,
    this.onTopLeft,
    this.onTopRight,
    this.onBottomLeft,
    this.onBottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: -6,
            top: -6,
            child: _handle(onTopLeft),
          ),
          Positioned(
            right: -6,
            top: -6,
            child: _handle(onTopRight),
          ),
          Positioned(
            left: -6,
            bottom: -6,
            child: _handle(onBottomLeft),
          ),
          Positioned(
            right: -6,
            bottom: -6,
            child: _handle(onBottomRight),
          ),
        ],
      ),
    );
  }

  Widget _handle(VoidCallback? onDrag) {
    return GestureDetector(
      onPanUpdate: (_) => onDrag?.call(),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
