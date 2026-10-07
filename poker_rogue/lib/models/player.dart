import 'playing_card.dart';

class Player {
  Player({required this.name, required this.stack, List<PlayingCard>? hand})
    : hand = hand ?? [];

  final String name;
  int stack;
  final List<PlayingCard> hand;
}
