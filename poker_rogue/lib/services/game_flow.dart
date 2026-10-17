import '../models/game_state.dart';
import '../models/player.dart';
import '../models/run_state.dart';
import 'deck_api_service.dart';

Future<GameState> createTableGame({
  required RunState run,
  required DeckApiService deckApi,
}) async {
  final deckId = await deckApi.createShuffledDeck();
  final draw = await deckApi.drawCards(deckId, 4);
  final contribution = run.currentTable == 3 ? 12 : 6;

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
