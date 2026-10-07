import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/playing_card.dart';

class DeckApiService {
  static const _host = 'deckofcardsapi.com';

  Future<String> createShuffledDeck() async {
    final data = await _getJson('/api/deck/new/shuffle/', {'deck_count': '1'});

    if (data['success'] != true || data['deck_id'] == null) {
      throw const DeckApiException('Não foi possível criar o baralho.');
    }

    return data['deck_id'] as String;
  }

  Future<DeckDraw> drawCards(String deckId, int count) async {
    final data = await _getJson('/api/deck/$deckId/draw/', {
      'count': count.toString(),
    });

    if (data['success'] != true ||
        data['cards'] == null ||
        data['remaining'] == null) {
      throw const DeckApiException('Não foi possível comprar cartas.');
    }

    return DeckDraw(
      cards: (data['cards'] as List)
          .map((card) => PlayingCard.fromJson(card as Map<String, dynamic>))
          .toList(),
      remaining: data['remaining'] as int,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final uri = Uri.https(_host, path, query);
      final response = await http.get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeckApiException('HTTP ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on DeckApiException {
      rethrow;
    } catch (_) {
      throw const DeckApiException('Problema de conexão. Tente novamente.');
    }
  }
}

class DeckDraw {
  const DeckDraw({required this.cards, required this.remaining});

  final List<PlayingCard> cards;
  final int remaining;
}

class DeckApiException implements Exception {
  const DeckApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
