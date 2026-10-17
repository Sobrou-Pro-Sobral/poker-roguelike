import 'package:flutter/material.dart';

import '../models/playing_card.dart';

class PokerCardWidget extends StatelessWidget {
  const PokerCardWidget({
    super.key,
    this.card,
    this.hidden = false,
    this.compact = false,
  });

  final PlayingCard? card;
  final bool hidden;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 46.0 : 58.0;
    final height = compact ? 64.0 : 82.0;
    final color = card?.isRed ?? false ? const Color(0xFFE51B2B) : Colors.black;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hidden ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hidden ? const Color(0xFFE51B2B) : color,
            width: 1.2,
          ),
        ),
        child: hidden || card == null
            ? Center(
                child: Container(
                  width: width * .42,
                  height: height * .42,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
            : Stack(
                children: [
                  Positioned(
                    left: 5,
                    top: 5,
                    child: _CornerMark(
                      value: card!.shortValue,
                      suit: card!.suitSymbol,
                      color: color,
                      compact: compact,
                    ),
                  ),
                  Center(
                    child: Text(
                      card!.suitSymbol,
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
                      angle: 3.1415926535,
                      child: _CornerMark(
                        value: card!.shortValue,
                        suit: card!.suitSymbol,
                        color: color,
                        compact: compact,
                      ),
                    ),
                  ),
                ],
              ),
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
