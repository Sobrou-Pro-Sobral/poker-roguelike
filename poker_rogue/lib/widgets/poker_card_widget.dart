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

    return Container(
      width: width,
      height: height,
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
                width: width * 0.45,
                height: height * 0.45,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card!.shortValue,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13 : 15,
                    ),
                  ),
                  Text(
                    card!.suitSymbol,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 15 : 18,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      card!.suitSymbol,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 20 : 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
