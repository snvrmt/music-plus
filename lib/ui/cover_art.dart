import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';

class CoverArt extends StatelessWidget {
  const CoverArt(this.cover,
      {super.key, required this.size, this.radius = 8, this.round = false, this.width});

  final Cover cover;
  final double size;
  final double? width;
  final double radius;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = size;
    final s = math.min(w, h);
    final br = round ? BorderRadius.circular(s) : BorderRadius.circular(radius);

    late final Widget shape;
    switch (cover.shape) {
      case CoverShape.circle:
        shape = Positioned(
          right: -0.12 * w,
          bottom: -0.12 * h,
          width: 0.64 * w,
          height: 0.64 * w,
          child: DecoratedBox(
              decoration: BoxDecoration(color: cover.fg, shape: BoxShape.circle)),
        );
      case CoverShape.half:
        shape = Positioned(
          left: 0,
          bottom: 0,
          width: w,
          height: 0.46 * h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cover.fg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(w)),
            ),
          ),
        );
      case CoverShape.diamond:
        shape = Positioned(
          left: 0.12 * w,
          top: 0.12 * h,
          width: 0.52 * s,
          height: 0.52 * s,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cover.fg,
                borderRadius: BorderRadius.circular(0.52 * s * 0.12),
              ),
            ),
          ),
        );
      case CoverShape.sun:
        shape = Positioned(
          left: 0.14 * w,
          top: 0.14 * h,
          width: 0.44 * s,
          height: 0.44 * s,
          child: DecoratedBox(
              decoration: BoxDecoration(color: cover.fg, shape: BoxShape.circle)),
        );
    }

    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        width: w,
        height: h,
        child: cover.imageUrl != null
            ? Image.network(cover.imageUrl!, fit: BoxFit.cover)
            : ColoredBox(
                color: cover.bg,
                child: Stack(clipBehavior: Clip.hardEdge, children: [shape]),
              ),
      ),
    );
  }
}
