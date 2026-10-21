import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playing_card.dart';

class PokerCardWidget extends StatefulWidget {
  const PokerCardWidget({
    super.key,
    this.card,
    this.hidden = false,
    this.compact = false,
    this.animate = false,
  });

  final PlayingCard? card;
  final bool hidden;
  final bool compact;
  final bool animate;

  @override
  State<PokerCardWidget> createState() => _PokerCardWidgetState();
}

class _PokerCardWidgetState extends State<PokerCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.animate && !widget.hidden ? 0 : 1,
    );
    if (widget.animate && !widget.hidden) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant PokerCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hidden && !widget.hidden && widget.animate) {
      _controller.forward(from: 0);
    } else if (!oldWidget.hidden && widget.hidden) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 46.0 : 58.0;
    final height = widget.compact ? 64.0 : 82.0;
    final color = widget.card?.isRed ?? false
        ? const Color(0xFFE51B2B)
        : Colors.black;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = math.pi * (1 - _controller.value);
          final showingFace = _controller.value >= .5 && !widget.hidden && widget.card != null;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateY(angle),
            child: showingFace
                ? _Face(
                    card: widget.card!,
                    color: color,
                    compact: widget.compact,
                  )
                : _Back(width: width, height: height),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE51B2B), width: 1.2),
      ),
      child: Center(
        child: Container(
          width: width * .42,
          height: height * .42,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.4),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.card, required this.color, required this.compact});

  final PlayingCard card;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 5,
            child: _CornerMark(
              value: card.shortValue,
              suit: card.suitSymbol,
              color: color,
              compact: compact,
            ),
          ),
          Center(
            child: Text(
              card.suitSymbol,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w400,
                fontSize: compact ? 27 : 36,
                height: .9,
              ),
            ),
          ),
          Positioned(
            right: 5,
            bottom: 5,
            child: Transform.rotate(
              angle: math.pi,
              child: _CornerMark(
                value: card.shortValue,
                suit: card.suitSymbol,
                color: color,
                compact: compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerMark extends StatelessWidget {
  const _CornerMark({
    required this.value,
    required this.suit,
    required this.color,
    required this.compact,
  });

  final String value;
  final String suit;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 12 : 14,
            height: 1,
          ),
        ),
        Text(
          suit,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 11 : 13,
            height: 1,
          ),
        ),
      ],
    );
  }
}
