import '../models/playing_card.dart';

class PokerHandResult implements Comparable<PokerHandResult> {
  const PokerHandResult({
    required this.name,
    required this.category,
    required this.tiebreakers,
  });

  final String name;
  final int category;
  final List<int> tiebreakers;

  @override
  int compareTo(PokerHandResult other) {
    if (category != other.category) return category.compareTo(other.category);
    final length = tiebreakers.length < other.tiebreakers.length
        ? tiebreakers.length
        : other.tiebreakers.length;
    for (var i = 0; i < length; i++) {
      if (tiebreakers[i] != other.tiebreakers[i]) {
        return tiebreakers[i].compareTo(other.tiebreakers[i]);
      }
    }
    return tiebreakers.length.compareTo(other.tiebreakers.length);
  }
}

class PokerHandEvaluator {
  PokerHandResult evaluate(List<PlayingCard> cards) {
    if (cards.length <= 5) return _evaluateFive(cards);

    PokerHandResult? best;
    _forEachCombination(cards, 5, (combination) {
      final result = _evaluateFive(combination);
      if (best == null || result.compareTo(best!) > 0) best = result;
    });
    return best!;
  }

  void _forEachCombination(
    List<PlayingCard> cards,
    int size,
    void Function(List<PlayingCard>) onCombination,
  ) {
    final selected = <PlayingCard>[];

    void visit(int start) {
      if (selected.length == size) {
        onCombination(List<PlayingCard>.unmodifiable(selected));
        return;
      }
      final needed = size - selected.length;
      for (var i = start; i <= cards.length - needed; i++) {
        selected.add(cards[i]);
        visit(i + 1);
        selected.removeLast();
      }
    }

    visit(0);
  }

  PokerHandResult _evaluateFive(List<PlayingCard> cards) {
    final ranks = cards.map((card) => card.rank).toList()
      ..sort((a, b) => b.compareTo(a));
    final counts = <int, int>{};
    for (final rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
    }

    final flush = cards.length == 5 && cards.every((card) => card.suit == cards.first.suit);
    final straightHigh = _straightHigh(ranks);
    if (flush && straightHigh != null) {
      return PokerHandResult(
        name: 'Sequência de mesmo naipe',
        category: 8,
        tiebreakers: [straightHigh],
      );
    }

    final fours = _ranksWithCount(counts, 4);
    if (fours.isNotEmpty) {
      return PokerHandResult(
        name: 'Quadra',
        category: 7,
        tiebreakers: [fours.first, ..._kickers(ranks, fours, 1)],
      );
    }

    final triples = _ranksWithCount(counts, 3);
    final pairs = _ranksWithCount(counts, 2);
    if (triples.isNotEmpty && pairs.isNotEmpty) {
      return PokerHandResult(
        name: 'Casa cheia',
        category: 6,
        tiebreakers: [triples.first, pairs.first],
      );
    }

    if (flush) {
      return PokerHandResult(
        name: 'Mesmo naipe',
        category: 5,
        tiebreakers: ranks,
      );
    }

    if (straightHigh != null) {
      return PokerHandResult(
        name: 'Sequência',
        category: 4,
        tiebreakers: [straightHigh],
      );
    }

    if (triples.isNotEmpty) {
      return PokerHandResult(
        name: 'Trinca',
        category: 3,
        tiebreakers: [triples.first, ..._kickers(ranks, triples, 2)],
      );
    }

    if (pairs.length >= 2) {
      return PokerHandResult(
        name: 'Dois pares',
        category: 2,
        tiebreakers: [pairs[0], pairs[1], ..._kickers(ranks, pairs, 1)],
      );
    }

    if (pairs.length == 1) {
      return PokerHandResult(
        name: 'Par',
        category: 1,
        tiebreakers: [pairs.first, ..._kickers(ranks, pairs, 3)],
      );
    }

    return PokerHandResult(
      name: 'Carta alta',
      category: 0,
      tiebreakers: ranks.toSet().take(5).toList(),
    );
  }

  int? _straightHigh(List<int> ranks) {
    final unique = ranks.toSet();
    for (var high = 14; high >= 5; high--) {
      if (List<int>.generate(5, (index) => high - index)
          .every(unique.contains)) {
        return high;
      }
    }
    if ({14, 2, 3, 4, 5}.every(unique.contains)) return 5;
    return null;
  }

  List<int> _ranksWithCount(Map<int, int> counts, int count) {
    return counts.entries
        .where((entry) => entry.value == count)
        .map((entry) => entry.key)
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  List<int> _kickers(List<int> ranks, List<int> ignored, int count) {
    return ranks
        .where((rank) => !ignored.contains(rank))
        .toSet()
        .take(count)
        .toList();
  }
}
