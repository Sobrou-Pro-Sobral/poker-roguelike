import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/playing_card.dart';

class DeckApiService {
  DeckApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'deckofcardsapi.com';
  final http.Client _client;
  Future<void>? _activeRequest;

  Future<String> createShuffledDeck() async {
    final data = await _getJson('/api/deck/new/shuffle/', {'deck_count': '1'});
    if (data['success'] != true || data['deck_id'] is! String) {
      throw const DeckApiException('Não foi possível criar o baralho.');
    }
    return data['deck_id'] as String;
  }

  Future<DeckDraw> drawCards(String deckId, int count) async {
    if (count <= 0) {
      throw const DeckApiException('A quantidade de cartas deve ser positiva.');
    }
    final data = await _getJson('/api/deck/$deckId/draw/', {
      'count': count.toString(),
    });
    if (data['success'] != true || data['cards'] is! List || data['remaining'] == null) {
      throw const DeckApiException('Não foi possível comprar cartas.');
    }

    final cards = (data['cards'] as List)
        .map((card) => PlayingCard.fromJson(card as Map<String, dynamic>))
        .toList();
    if (cards.length != count) {
      throw const DeckApiException('A API retornou uma quantidade inesperada de cartas.');
    }

    final remaining = int.tryParse(data['remaining'].toString());
    if (remaining == null || remaining < 0) {
      throw const DeckApiException('A API retornou um baralho inválido.');
    }
    return DeckDraw(cards: cards, remaining: remaining);
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> query,
  ) async {
    if (_activeRequest != null) {
      await _activeRequest;
    }
    final request = _performGet(path, query);
    _activeRequest = request.then<void>((_) {}).catchError((_) {}).whenComplete(() {
      _activeRequest = null;
    });
    return request;
  }

  Future<Map<String, dynamic>> _performGet(
    String path,
    Map<String, String> query,
  ) async {
    try {
      final uri = Uri.https(_host, path, query);
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeckApiException('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const DeckApiException('Resposta inválida da Deck of Cards API.');
      }
      return decoded;
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
