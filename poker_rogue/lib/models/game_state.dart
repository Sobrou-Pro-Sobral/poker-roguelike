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
  })  : playerContribution = initialContribution,
       opponentContribution = initialContribution;

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
  bool wasFolded = false;
  int payout = 0;
  String? resultMessage;

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

  int get amountToCall => opponentRoundContribution > playerRoundContribution
      ? opponentRoundContribution - playerRoundContribution
      : 0;

  bool get canCheck => !resolved && amountToCall == 0;
  bool get canCall => !resolved && amountToCall > 0 && player.stack >= amountToCall;
  bool get canBet => !resolved &&
      playerRoundContribution == opponentRoundContribution &&
      player.stack >= betAmount &&
      opponent.stack > 0 &&
      betAmount > 0;
  bool get canRaise => !resolved &&
      amountToCall > 0 &&
      player.stack >= amountToCall + betAmount;
  bool get canAllIn => !resolved && player.stack > 0;
  bool get rewardEligible => resolved && playerWon == true && !isTie && !wasFolded;

  bool check() => canCheck;

  bool placeBet() => bet(betAmount);

  bool bet(int amount) {
    if (amount <= 0 || !canBet || player.stack < amount) return false;
    _putInPot(player, amount, isPlayer: true);
    _botRespondToBet();
    return true;
  }

  bool call() {
    if (!canCall) return false;
    _putInPot(player, amountToCall, isPlayer: true);
    return true;
  }

  bool raise(int totalRoundBet) {
    if (!canRaise || totalRoundBet <= opponentRoundContribution) return false;
    final amount = totalRoundBet - playerRoundContribution;
    if (amount <= 0 || player.stack < amount) return false;
    _putInPot(player, amount, isPlayer: true);
    _botRespondToBet();
    return true;
  }

  bool allIn() {
    if (!canAllIn) return false;
    _putInPot(player, player.stack, isPlayer: true);
    _botRespondToBet();
    return true;
  }

  void closeBettingRound() {
    if (playerRoundContribution != opponentRoundContribution &&
        player.stack > 0 &&
        opponent.stack > 0) {
      return;
    }
    playerRoundContribution = 0;
    opponentRoundContribution = 0;
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

  void _botRespondToBet() {
    final pending = playerRoundContribution - opponentRoundContribution;
    if (pending <= 0) return;

    final botCall = pending < opponent.stack ? pending : opponent.stack;
    _putInPot(opponent, botCall, isPlayer: false);
    if (botCall < pending) {
      // O excesso da aposta do jogador não é contestado e volta para seu stack.
      final uncalled = pending - botCall;
      player.stack += uncalled;
      playerContribution -= uncalled;
      playerRoundContribution -= uncalled;
      pot -= uncalled;
    }
  }

  void settle({required bool folded}) {
    if (resolved) return;
    resolved = true;
    wasFolded = folded;
    opponentRevealed = !folded;

    if (folded) {
      playerWon = false;
      opponent.stack += pot;
      resultMessage = 'Você desistiu';
      _applyLossEffects();
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
