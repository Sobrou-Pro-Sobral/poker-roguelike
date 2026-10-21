import 'dart:math';

import '../game/poker_hand_evaluator.dart';
import 'player.dart';
import 'playing_card.dart';
import 'run_state.dart';

enum PokerRound { preFlop, flop, turn, river, showdown }

enum OpponentAction { check, call, fold, raise, allIn }

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
    Random? random,
  })  : playerContribution = initialContribution,
       opponentContribution = initialContribution,
       _random = random ?? Random();

  final String deckId;
  final Player player;
  final Player opponent;
  final List<PlayingCard> communityCards;
  final RunState run;
  final int initialContribution;
  final Random _random;

  int pot;
  int remainingCards;
  PokerRound round;
  bool opponentRevealed;
  bool resolved = false;
  bool? playerWon;
  bool isTie = false;
  bool wasFolded = false;
  bool opponentFolded = false;
  int payout = 0;
  String? resultMessage;
  String lastAction = 'Sua vez';
  OpponentAction? lastOpponentAction;

  int playerContribution;
  int opponentContribution;
  int playerRoundContribution = 0;
  int opponentRoundContribution = 0;

  bool get isBoss => run.isBoss;
  String get bossName => run.currentTable == 3 ? 'O Agiota' : 'O Banqueiro';
  String get bossRule => run.currentTable == 3
      ? 'Contribuição inicial dobrada: 12 fichas.'
      : 'Apostas fixas dobradas nesta mesa.';

  String get roundLabel => switch (round) {
    PokerRound.preFlop => 'pré-flop',
    PokerRound.flop => 'flop',
    PokerRound.turn => 'turn',
    PokerRound.river => 'river',
    PokerRound.showdown => 'confronto',
  };

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

  int get minimumActionAmount => amountToCall > 0
      ? amountToCall + betAmount
      : betAmount;
  int get maxActionAmount => player.stack;

  int get amountToCall => opponentRoundContribution > playerRoundContribution
      ? opponentRoundContribution - playerRoundContribution
      : 0;

  bool get hasPendingCall => amountToCall > 0;
  bool get canCheck => !resolved && !hasPendingCall;
  bool get canCall => !resolved && hasPendingCall && player.stack >= amountToCall;
  bool get canBet => !resolved &&
      !hasPendingCall &&
      player.stack >= betAmount &&
      opponent.stack > 0 &&
      betAmount > 0;
  bool get canRaise => !resolved &&
      opponent.stack > 0 &&
      player.stack >= minimumActionAmount;
  bool get canAllIn => !resolved && player.stack > 0;
  bool get rewardEligible =>
      resolved && playerWon == true && !isTie && !wasFolded;

  GameStateCheckpoint checkpoint() => GameStateCheckpoint(
    playerStack: player.stack,
    opponentStack: opponent.stack,
    communityCards: List<PlayingCard>.from(communityCards),
    pot: pot,
    remainingCards: remainingCards,
    round: round,
    opponentRevealed: opponentRevealed,
    resolved: resolved,
    playerWon: playerWon,
    isTie: isTie,
    wasFolded: wasFolded,
    opponentFolded: opponentFolded,
    payout: payout,
    resultMessage: resultMessage,
    lastAction: lastAction,
    lastOpponentAction: lastOpponentAction,
    playerContribution: playerContribution,
    opponentContribution: opponentContribution,
    playerRoundContribution: playerRoundContribution,
    opponentRoundContribution: opponentRoundContribution,
    run: run.copy(),
  );

  void restore(GameStateCheckpoint state) {
    player.stack = state.playerStack;
    opponent.stack = state.opponentStack;
    communityCards
      ..clear()
      ..addAll(state.communityCards);
    pot = state.pot;
    remainingCards = state.remainingCards;
    round = state.round;
    opponentRevealed = state.opponentRevealed;
    resolved = state.resolved;
    playerWon = state.playerWon;
    isTie = state.isTie;
    wasFolded = state.wasFolded;
    opponentFolded = state.opponentFolded;
    payout = state.payout;
    resultMessage = state.resultMessage;
    lastAction = state.lastAction;
    lastOpponentAction = state.lastOpponentAction;
    playerContribution = state.playerContribution;
    opponentContribution = state.opponentContribution;
    playerRoundContribution = state.playerRoundContribution;
    opponentRoundContribution = state.opponentRoundContribution;
    run.copyFrom(state.run);
  }

  bool check() {
    if (!canCheck) return false;
    lastAction = 'Você passou';
    _opponentRespondsToCheck();
    return true;
  }

  bool placeBet() => bet(betAmount);

  bool bet(int amount) {
    if (amount < betAmount || !canBet || player.stack < amount) return false;
    _putInPot(player, amount, isPlayer: true);
    lastAction = 'Você apostou $amount';
    _opponentRespondsToBet();
    return true;
  }

  bool call() {
    if (!canCall) return false;
    final amount = amountToCall;
    _putInPot(player, amount, isPlayer: true);
    lastAction = 'Você pagou $amount';
    return true;
  }

  bool raise(int totalRoundBet) {
    if (!canRaise || totalRoundBet <= opponentRoundContribution) return false;
    final amount = totalRoundBet - playerRoundContribution;
    if (amount < minimumActionAmount || player.stack < amount) return false;
    _putInPot(player, amount, isPlayer: true);
    lastAction = 'Você aumentou $amount';
    _opponentRespondsToBet();
    return true;
  }

  bool allIn() {
    if (!canAllIn) return false;
    final amount = player.stack;
    if (hasPendingCall && amount < amountToCall) {
      _putInPot(player, amount, isPlayer: true);
      lastAction = 'Você foi all-in';
      return true;
    }
    _putInPot(player, amount, isPlayer: true);
    lastAction = 'Você foi all-in';
    _opponentRespondsToBet();
    return true;
  }

  void closeBettingRound() {
    if (hasPendingCall && player.stack > 0 && opponent.stack > 0) return;
    playerRoundContribution = 0;
    opponentRoundContribution = 0;
  }

  void _opponentRespondsToCheck() {
    if (opponent.stack <= 0) return;
    final roll = _random.nextInt(100);
    if (roll < 60) {
      lastOpponentAction = OpponentAction.check;
      lastAction = 'Rival passou';
      return;
    }
    if (roll < 85) {
      _opponentRaise(betAmount);
      return;
    }
    _opponentAllIn();
  }

  void _opponentRespondsToBet() {
    final pending = playerRoundContribution - opponentRoundContribution;
    if (pending <= 0) return;
    if (opponent.stack <= 0) {
      _refundUncalled(pending);
      lastAction = 'Aposta não contestada devolvida';
      return;
    }
    if (player.stack <= 0) {
      final roll = _random.nextInt(100);
      if (roll < 15) {
        lastOpponentAction = OpponentAction.fold;
        settle(opponentFolded: true);
        return;
      }
      _opponentCall(pending);
      return;
    }

    final roll = _random.nextInt(100);
    if (roll < 15) {
      lastOpponentAction = OpponentAction.fold;
      settle(opponentFolded: true);
      return;
    }
    if (roll < 65) {
      _opponentCall(pending);
      return;
    }
    if (roll < 88 && opponent.stack > pending + betAmount) {
      _opponentRaise(pending + _randomRaiseAmount(pending));
      return;
    }
    _opponentAllIn();
  }

  int _randomRaiseAmount(int currentPending) {
    final minimum = betAmount;
    final available = opponent.stack - currentPending;
    if (available <= minimum) return minimum;
    return minimum + _random.nextInt(available - minimum + 1);
  }

  void _opponentCall(int pending) {
    lastOpponentAction = OpponentAction.call;
    if (opponent.stack >= pending) {
      _putInPot(opponent, pending, isPlayer: false);
      lastAction = 'Rival pagou $pending';
      return;
    }
    _opponentAllIn();
  }

  void _opponentRaise(int amount) {
    final total = amount < opponent.stack ? amount : opponent.stack;
    if (total <= 0) {
      _opponentCall(playerRoundContribution - opponentRoundContribution);
      return;
    }
    lastOpponentAction = OpponentAction.raise;
    _putInPot(opponent, total, isPlayer: false);
    lastAction = 'Rival aumentou $total';
  }

  void _opponentAllIn() {
    lastOpponentAction = OpponentAction.allIn;
    final pending = playerRoundContribution - opponentRoundContribution;
    if (pending > 0 && opponent.stack <= pending) {
      final paid = opponent.stack;
      _putInPot(opponent, paid, isPlayer: false);
      _refundUncalled(pending - paid);
    } else {
      final amount = opponent.stack;
      _putInPot(opponent, amount, isPlayer: false);
    }
    lastAction = 'Rival foi all-in';
  }

  void _refundUncalled(int amount) {
    if (amount <= 0) return;
    player.stack += amount;
    playerContribution -= amount;
    playerRoundContribution -= amount;
    pot -= amount;
  }

  void _putInPot(Player participant, int amount, {required bool isPlayer}) {
    final legalAmount = amount < participant.stack ? amount : participant.stack;
    participant.stack -= legalAmount;
    pot += legalAmount;
    if (isPlayer) {
      playerContribution += legalAmount;
      playerRoundContribution += legalAmount;
    } else {
      opponentContribution += legalAmount;
      opponentRoundContribution += legalAmount;
    }
  }

  void settle({bool folded = false, bool opponentFolded = false}) {
    if (resolved) return;
    resolved = true;
    wasFolded = folded;
    this.opponentFolded = opponentFolded;
    opponentRevealed = !folded && !opponentFolded;

    if (folded) {
      playerWon = false;
      opponent.stack += pot;
      resultMessage = 'Você desistiu';
      _applyLossEffects();
      return;
    }
    if (opponentFolded) {
      playerWon = true;
      payout = pot;
      player.stack += pot;
      resultMessage = 'Rival desistiu';
      run.winStreak += 1;
      _applyWinBonuses(0);
      return;
    }

    final evaluator = PokerHandEvaluator();
    final playerResult = evaluator.evaluate([...player.hand, ...communityCards]);
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
      if (run.isFinalTable) run.isDefeat = true;
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
    if (run.isFinalTable) run.isVictory = true;
  }

  void _applyLossEffects() {
    run.winStreak = 0;
    if (run.has(Upgrade.insurance) && !run.insuranceUsed) {
      run.insuranceUsed = true;
      player.stack += 10;
    }
    _syncRunChips();
    if (run.playerChips <= 0 || run.isFinalTable) run.isDefeat = true;
  }

  void _syncRunChips() => run.playerChips = player.stack;
}

class GameStateCheckpoint {
  const GameStateCheckpoint({
    required this.playerStack,
    required this.opponentStack,
    required this.communityCards,
    required this.pot,
    required this.remainingCards,
    required this.round,
    required this.opponentRevealed,
    required this.resolved,
    required this.playerWon,
    required this.isTie,
    required this.wasFolded,
    required this.opponentFolded,
    required this.payout,
    required this.resultMessage,
    required this.lastAction,
    required this.lastOpponentAction,
    required this.playerContribution,
    required this.opponentContribution,
    required this.playerRoundContribution,
    required this.opponentRoundContribution,
    required this.run,
  });

  final int playerStack;
  final int opponentStack;
  final List<PlayingCard> communityCards;
  final int pot;
  final int remainingCards;
  final PokerRound round;
  final bool opponentRevealed;
  final bool resolved;
  final bool? playerWon;
  final bool isTie;
  final bool wasFolded;
  final bool opponentFolded;
  final int payout;
  final String? resultMessage;
  final String lastAction;
  final OpponentAction? lastOpponentAction;
  final int playerContribution;
  final int opponentContribution;
  final int playerRoundContribution;
  final int opponentRoundContribution;
  final RunState run;
}