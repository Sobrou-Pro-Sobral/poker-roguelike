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
    if (category != other.category) {
      return category.compareTo(other.category);
    }

    for (
      var i = 0;
      i < tiebreakers.length && i < other.tiebreakers.length;
      i++
    ) {
      if (tiebreakers[i] != other.tiebreakers[i]) {
        return tiebreakers[i].compareTo(other.tiebreakers[i]);
      }
    }

    return 0;
  }
}

class PokerHandEvaluator {
  PokerHandResult evaluate(List<PlayingCard> cards) {
    final ranks = cards.map((card) => card.rank).toList()
      ..sort((a, b) => b.compareTo(a));
    final rankCounts = <int, int>{};
    for (final rank in ranks) {
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }

    final flushCards = _flushCards(cards);
    final straightHigh = _straightHigh(ranks);
    final straightFlushHigh = flushCards == null
        ? null
        : _straightHigh(flushCards.map((card) => card.rank).toList());

    if (straightFlushHigh != null) {
      return PokerHandResult(
        name: 'Sequência de mesmo naipe',
        category: 8,
        tiebreakers: [straightFlushHigh],
      );
    }

    final four = _ranksWithCount(rankCounts, 4);
    if (four.isNotEmpty) {
      return PokerHandResult(
        name: 'Quadra',
        category: 7,
        tiebreakers: [
          four.first,
          _kickers(ranks, [four.first], 1).first,
        ],
      );
    }

    final triples = _ranksWithCount(rankCounts, 3);
    final pairs = _ranksWithCount(rankCounts, 2);
    if (triples.isNotEmpty && (pairs.isNotEmpty || triples.length > 1)) {
      final second = triples.length > 1 ? triples[1] : pairs.first;
      return PokerHandResult(
        name: 'Casa cheia',
        category: 6,
        tiebreakers: [triples.first, second],
      );
    }

    if (flushCards != null) {
      final flushRanks = flushCards.map((card) => card.rank).toList()
        ..sort((a, b) => b.compareTo(a));
      return PokerHandResult(
        name: 'Mesmo naipe',
        category: 5,
        tiebreakers: flushRanks.take(5).toList(),
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
        tiebreakers: [
          triples.first,
          ..._kickers(ranks, [triples.first], 2),
        ],
      );
    }

    if (pairs.length >= 2) {
      final topPairs = pairs.take(2).toList();
      return PokerHandResult(
        name: 'Dois pares',
        category: 2,
        tiebreakers: [...topPairs, _kickers(ranks, topPairs, 1).first],
      );
    }

    if (pairs.length == 1) {
      return PokerHandResult(
        name: 'Par',
        category: 1,
        tiebreakers: [
          pairs.first,
          ..._kickers(ranks, [pairs.first], 3),
        ],
      );
    }

    return PokerHandResult(
      name: 'Carta alta',
      category: 0,
      tiebreakers: ranks.toSet().take(5).toList(),
    );
  }

  List<PlayingCard>? _flushCards(List<PlayingCard> cards) {
    final bySuit = <String, List<PlayingCard>>{};
    for (final card in cards) {
      bySuit.putIfAbsent(card.suit, () => []).add(card);
    }

    for (final suitCards in bySuit.values) {
      if (suitCards.length >= 5) {
        return suitCards;
      }
    }
    return null;
  }

  int? _straightHigh(List<int> ranks) {
    final unique = ranks.toSet().toList()..sort((a, b) => b.compareTo(a));
    if (unique.contains(14)) {
      unique.add(1);
    }

    var run = 1;
    for (var i = 1; i < unique.length; i++) {
      if (unique[i - 1] - unique[i] == 1) {
        run++;
        if (run == 5) {
          return unique[i - 4];
        }
      } else {
        run = 1;
      }
    }
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
