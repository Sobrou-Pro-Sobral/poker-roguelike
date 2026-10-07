import 'package:flutter/material.dart';

import '../game/poker_hand_evaluator.dart';
import '../models/game_state.dart';
import '../models/playing_card.dart';
import '../widgets/action_button.dart';
import '../widgets/poker_card_widget.dart';

class ShowdownScreen extends StatelessWidget {
  ShowdownScreen({super.key, required this.game, this.folded = false});

  final GameState game;
  final bool folded;
  final PokerHandEvaluator _evaluator = PokerHandEvaluator();

  @override
  Widget build(BuildContext context) {
    final playerResult = _evaluator.evaluate([
      ...game.player.hand,
      ...game.communityCards,
    ]);
    final opponentResult = _evaluator.evaluate([
      ...game.opponent.hand,
      ...game.communityCards,
    ]);
    final comparison = playerResult.compareTo(opponentResult);
    final title = folded
        ? 'Você desistiu'
        : comparison > 0
        ? 'Você venceu'
        : comparison < 0
        ? 'Rival venceu'
        : 'Empate';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONFRONTO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                folded ? 'O rival leva o pote.' : 'Pote: ${game.pot}',
                style: const TextStyle(
                  color: Color(0xFFE51B2B),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 28),
              _HandSummary(
                label: 'Sua mão',
                result: playerResult.name,
                cards: game.player.hand,
              ),
              const SizedBox(height: 18),
              _HandSummary(
                label: 'Mão do rival',
                result: opponentResult.name,
                cards: game.opponent.hand,
              ),
              const SizedBox(height: 18),
              const Text(
                'Cartas comunitárias',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final card in game.communityCards)
                    PokerCardWidget(card: card, compact: true),
                ],
              ),
              const Spacer(),
              ActionButton(
                label: 'Continuar',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                primary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandSummary extends StatelessWidget {
  const _HandSummary({
    required this.label,
    required this.result,
    required this.cards,
  });

  final String label;
  final String result;
  final List<PlayingCard> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final card in cards)
                PokerCardWidget(card: card, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}
