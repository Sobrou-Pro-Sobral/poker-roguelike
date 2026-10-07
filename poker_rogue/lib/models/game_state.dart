import 'player.dart';
import 'playing_card.dart';

enum PokerRound { preFlop, flop, turn, river, showdown }

class GameState {
  GameState({
    required this.deckId,
    required this.player,
    required this.opponent,
    required this.communityCards,
    required this.pot,
    required this.remainingCards,
    this.round = PokerRound.preFlop,
    this.opponentRevealed = false,
  });

  final String deckId;
  final Player player;
  final Player opponent;
  final List<PlayingCard> communityCards;
  int pot;
  int remainingCards;
  PokerRound round;
  bool opponentRevealed;

  String get roundLabel {
    return switch (round) {
      PokerRound.preFlop => 'pré-flop',
      PokerRound.flop => 'flop',
      PokerRound.turn => 'turn',
      PokerRound.river => 'river',
      PokerRound.showdown => 'confronto',
    };
  }
}
