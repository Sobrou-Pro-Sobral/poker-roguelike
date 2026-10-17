import '../game/poker_hand_evaluator.dart';
import 'player.dart';
import 'playing_card.dart';
import 'run_state.dart';

enum PokerRound { preFlop, flop, turn, river, showdown }

class GameState {
  GameState({
    required this.deckId,
    required this.player,
    required this.opponent,
    required this.communityCards,
    required this.pot,
    required this.remainingCards,
    required this.run,
    required this.initialContribution,
    this.round = PokerRound.preFlop,
    this.opponentRevealed = false,
  });

  final String deckId;
  final Player player;
  final Player opponent;
  final List<PlayingCard> communityCards;
  final RunState run;
  final int initialContribution;
  int pot;
  int remainingCards;
  PokerRound round;
  bool opponentRevealed;
  bool resolved = false;
  bool? playerWon;
  bool isTie = false;
  int payout = 0;
  String? resultMessage;

  bool get isBoss => run.isBoss;
  String get bossName => run.currentTable == 3 ? 'O Agiota' : 'O Banqueiro';
  String get bossRule => run.currentTable == 3
      ? 'Contribuição inicial dobrada: 12 fichas.'
      : 'Apostas fixas dobradas nesta mesa.';

  String get roundLabel {
    return switch (round) {
      PokerRound.preFlop => 'pré-flop',
      PokerRound.flop => 'flop',
      PokerRound.turn => 'turn',
      PokerRound.river => 'river',
      PokerRound.showdown => 'confronto',
    };
  }

  int get betAmount {
    final base = switch (round) {
      PokerRound.preFlop => 6,
      PokerRound.flop => 12,
      PokerRound.turn => 24,
      PokerRound.river => 24,
      PokerRound.showdown => 0,
    };
    return run.currentTable == 5 ? base * 2 : base;
  }

  bool get canBet => round != PokerRound.showdown &&
      player.stack >= betAmount &&
      opponent.stack >= betAmount;

  void placeBet() {
    if (!canBet) return;
    player.stack -= betAmount;
    opponent.stack -= betAmount;
    pot += betAmount * 2;
  }

  void settle({required bool folded}) {
    if (resolved) return;
    resolved = true;
    opponentRevealed = true;

    if (folded) {
      playerWon = false;
      opponent.stack += pot;
      resultMessage = 'Você desistiu';
      _applyLossEffects();
      return;
    }

    final evaluator = PokerHandEvaluator();
    final playerResult = evaluator.evaluate([
      ...player.hand,
      ...communityCards,
    ]);
    final opponentResult = evaluator.evaluate([
      ...opponent.hand,
      ...communityCards,
    ]);
    final comparison = playerResult.compareTo(opponentResult);

    if (comparison > 0) {
      playerWon = true;
      payout = pot;
      player.stack += pot;
      resultMessage = 'Você venceu';
      run.winStreak += 1;
      _applyWinBonuses(playerResult.category);
    } else if (comparison < 0) {
      playerWon = false;
      opponent.stack += pot;
      resultMessage = 'Rival venceu';
      _applyLossEffects();
    } else {
      isTie = true;
      payout = pot ~/ 2;
      player.stack += payout;
      opponent.stack += pot - payout;
      resultMessage = 'Empate';
      run.winStreak = 0;
      _syncRunChips();
    }
  }

  void _applyWinBonuses(int category) {
    if (run.has(Upgrade.kingOfSpades) && run.isBoss) {
      final bonus = (payout * 0.25).floor();
      player.stack += bonus;
      payout += bonus;
    }
    if (run.has(Upgrade.queenOfHearts) && category >= 1) {
      player.stack += 5;
      payout += 5;
    }
    if (run.has(Upgrade.tenOfClubs) && run.winStreak == 2) {
      player.stack += 10;
      payout += 10;
    }
    _syncRunChips();
    if (run.isFinalTable) {
      run.isVictory = true;
    }
  }

  void _applyLossEffects() {
    run.winStreak = 0;
    if (run.has(Upgrade.insurance) && !run.insuranceUsed) {
      run.insuranceUsed = true;
      player.stack += 10;
    }
    _syncRunChips();
    if (run.playerChips <= 0) {
      run.isDefeat = true;
    }
  }

  void _syncRunChips() {
    run.playerChips = player.stack;
  }
}
