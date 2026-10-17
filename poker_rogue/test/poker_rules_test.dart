import 'package:flutter_test/flutter_test.dart';
import 'package:poker_rogue/game/poker_hand_evaluator.dart';
import 'package:poker_rogue/models/game_state.dart';
import 'package:poker_rogue/models/player.dart';
import 'package:poker_rogue/models/playing_card.dart';
import 'package:poker_rogue/models/run_state.dart';

PlayingCard c(String value, String suit) => PlayingCard(
  code: '$value$suit',
  value: switch (value) {
    'A' => 'ACE',
    'K' => 'KING',
    'Q' => 'QUEEN',
    'J' => 'JACK',
    _ => value,
  },
  suit: switch (suit) {
    'S' => 'SPADES',
    'H' => 'HEARTS',
    'D' => 'DIAMONDS',
    _ => 'CLUBS',
  },
);

void main() {
  group('PokerHandEvaluator', () {
    final evaluator = PokerHandEvaluator();

    test('compara uma mão vencedora com uma perdedora', () {
      final pair = evaluator.evaluate([
        c('A', 'S'),
        c('A', 'H'),
        c('2', 'C'),
        c('7', 'D'),
        c('9', 'S'),
        c('J', 'C'),
        c('3', 'H'),
      ]);
      final highCard = evaluator.evaluate([
        c('K', 'S'),
        c('Q', 'D'),
        c('2', 'C'),
        c('7', 'D'),
        c('9', 'S'),
        c('J', 'C'),
        c('3', 'H'),
      ]);
      expect(pair.compareTo(highCard), greaterThan(0));
    });

    test('reconhece par, sequência, flush e full house', () {
      expect(
        evaluator
            .evaluate([
              c('A', 'S'), c('A', 'H'), c('2', 'C'), c('7', 'D'), c('9', 'S'),
            ])
            .category,
        1,
      );
      expect(
        evaluator
            .evaluate([
              c('5', 'S'), c('6', 'H'), c('7', 'D'), c('8', 'C'), c('9', 'S'),
            ])
            .category,
        4,
      );
      expect(
        evaluator
            .evaluate([
              c('2', 'H'), c('5', 'H'), c('7', 'H'), c('9', 'H'), c('K', 'H'),
            ])
            .category,
        5,
      );
      expect(
        evaluator
            .evaluate([
              c('A', 'S'), c('A', 'H'), c('A', 'D'), c('K', 'S'), c('K', 'H'),
            ])
            .category,
        6,
      );
    });
  });

  test('paga o pote apenas uma vez', () {
    final run = RunState();
    final game = GameState(
      deckId: 'test',
      player: Player(name: 'Você', stack: 94, hand: [c('A', 'S'), c('A', 'H')]),
      opponent: Player(name: 'Rival', stack: 94, hand: [c('K', 'S'), c('Q', 'D')]),
      communityCards: [c('2', 'C'), c('7', 'D'), c('9', 'S'), c('J', 'C'), c('3', 'H')],
      pot: 12,
      remainingCards: 43,
      run: run,
      initialContribution: 6,
    );

    game.settle(folded: false);
    final chipsAfterFirstSettlement = game.player.stack;
    game.settle(folded: false);
    expect(game.player.stack, chipsAfterFirstSettlement);
    expect(run.playerChips, chipsAfterFirstSettlement);
  });

  test('Seguro é ativado uma única vez quando a mão é perdida', () {
    final run = RunState();
    run.acquire(Upgrade.insurance);
    final game = GameState(
      deckId: 'test',
      player: Player(name: 'Você', stack: 0, hand: [c('2', 'C'), c('7', 'D')]),
      opponent: Player(name: 'Rival', stack: 94, hand: [c('A', 'S'), c('K', 'H')]),
      communityCards: [c('3', 'C'), c('5', 'D'), c('9', 'H'), c('J', 'C'), c('Q', 'D')],
      pot: 12,
      remainingCards: 43,
      run: run,
      initialContribution: 6,
    );

    game.settle(folded: false);
    expect(run.insuranceUsed, isTrue);
    expect(run.playerChips, 10);
    game.settle(folded: false);
    expect(run.playerChips, 10);
  });

  test('Rainha de Copas e Dez de Paus aplicam seus bônus', () {
    final run = RunState();
    run.acquire(Upgrade.queenOfHearts);
    run.acquire(Upgrade.tenOfClubs);
    run.winStreak = 1;
    final game = GameState(
      deckId: 'test',
      player: Player(name: 'Você', stack: 94, hand: [c('A', 'S'), c('A', 'H')]),
      opponent: Player(name: 'Rival', stack: 94, hand: [c('K', 'S'), c('Q', 'D')]),
      communityCards: [c('2', 'C'), c('7', 'D'), c('9', 'S'), c('J', 'C'), c('3', 'H')],
      pot: 12,
      remainingCards: 43,
      run: run,
      initialContribution: 6,
    );

    game.settle(folded: false);
    expect(run.playerChips, 111);
  });
}
