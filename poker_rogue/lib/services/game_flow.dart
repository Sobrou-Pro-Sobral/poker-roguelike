import '../models/game_state.dart';
import '../models/player.dart';
import '../models/run_state.dart';
import 'deck_api_service.dart';

Future<GameState> createTableGame({
  required RunState run,
  required DeckApiService deckApi,
}) async {
  if (run.isTerminal || run.currentTable < 1 || run.currentTable > RunState.maxTables) {
    throw const GameFlowException('A run não pode iniciar uma nova mesa.');
  }

  final contribution = run.currentTable == 3 ? 12 : 6;
  if (run.playerChips < contribution) {
    throw const GameFlowException('Fichas insuficientes para iniciar esta mesa.');
  }

  final deckId = await deckApi.createShuffledDeck();
  final draw = await deckApi.drawCards(deckId, 4);
  if (draw.cards.length != 4) {
    throw const GameFlowException('A API não retornou as quatro cartas iniciais.');
  }

  return GameState(
    deckId: deckId,
    player: Player(
      name: 'Você',
      stack: run.playerChips - contribution,
      hand: draw.cards.sublist(0, 2),
    ),
    opponent: Player(
      name: run.isBoss ? run.currentTable == 3 ? 'O Agiota' : 'O Banqueiro' : 'Rival',
      stack: 120 - contribution,
      hand: draw.cards.sublist(2, 4),
    ),
    communityCards: [],
    pot: contribution * 2,
    remainingCards: draw.remaining,
    run: run,
    initialContribution: contribution,
  );
}

class GameFlowException implements Exception {
  const GameFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}
