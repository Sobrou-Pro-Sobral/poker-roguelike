class PlayingCard {
  const PlayingCard({
    required this.code,
    required this.value,
    required this.suit,
  });

  final String code;
  final String value;
  final String suit;

  factory PlayingCard.fromJson(Map<String, dynamic> json) {
    return PlayingCard(
      code: json['code'] as String,
      value: json['value'] as String,
      suit: json['suit'] as String,
    );
  }

  String get shortValue {
    return switch (value) {
      'ACE' => 'A',
      'KING' => 'K',
      'QUEEN' => 'Q',
      'JACK' => 'J',
      _ => value,
    };
  }

  String get suitSymbol {
    return switch (suit) {
      'SPADES' => '♠',
      'HEARTS' => '♥',
      'DIAMONDS' => '♦',
      'CLUBS' => '♣',
      _ => '?',
    };
  }

  bool get isRed => suit == 'HEARTS' || suit == 'DIAMONDS';

  int get rank {
    return switch (value) {
      'ACE' => 14,
      'KING' => 13,
      'QUEEN' => 12,
      'JACK' => 11,
      _ => int.parse(value),
    };
  }
}
