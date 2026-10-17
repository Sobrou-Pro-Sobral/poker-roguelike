import 'package:flutter/material.dart';

import '../game/poker_hand_evaluator.dart';
import '../models/game_state.dart';
import '../models/playing_card.dart';
import '../models/run_state.dart';
import '../services/deck_api_service.dart';
import '../services/game_flow.dart';
import '../widgets/action_button.dart';
import '../widgets/poker_card_widget.dart';
import 'poker_table_screen.dart';
import 'run_flow_screen.dart';

class ShowdownScreen extends StatefulWidget {
  const ShowdownScreen({
    super.key,
    required this.game,
    required this.deckApi,
    this.folded = false,
  });

  final GameState game;
  final DeckApiService deckApi;
  final bool folded;

  @override
  State<ShowdownScreen> createState() => _ShowdownScreenState();
}

class _ShowdownScreenState extends State<ShowdownScreen> {
  late final PokerHandResult _playerResult;
  late final PokerHandResult _opponentResult;

  @override
  void initState() {
    super.initState();
    widget.game.settle(folded: widget.folded);
    final evaluator = PokerHandEvaluator();
    _playerResult = evaluator.evaluate([
      ...widget.game.player.hand,
      ...widget.game.communityCards,
    ]);
    _opponentResult = evaluator.evaluate([
      ...widget.game.opponent.hand,
      ...widget.game.communityCards,
    ]);
  }

  void _continue() {
    final run = widget.game.run;
    if (run.isVictory || run.isDefeat) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RunResultScreen(run: run)),
      );
      return;
    }

    final upgrades = run.availableUpgrades;
    if (upgrades.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RewardScreen(
            game: widget.game,
            deckApi: widget.deckApi,
          ),
        ),
      );
      return;
    }

    run.moveToNextTable();
    _openNextTable();
  }

  Future<void> _openNextTable() async {
    try {
      final run = widget.game.run;
      final nextGame = await _createNextGame(run);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PokerTableScreen(
            game: nextGame,
            deckApi: widget.deckApi,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível iniciar a próxima mesa: $error')),
      );
    }
  }

  Future<GameState> _createNextGame(RunState run) {
    // Importação local mantida aqui para deixar o fluxo da tela fácil de seguir.
    return createTableGame(run: run, deckApi: widget.deckApi);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONFRONTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      game.resultMessage ?? 'Resultado',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.isTie
                          ? 'Pote dividido: ${game.payout} para você.'
                          : game.playerWon == true
                          ? 'Pote recebido: ${game.payout}'
                          : 'O rival leva o pote.',
                      style: const TextStyle(
                        color: Color(0xFFE51B2B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _HandSummary(
                      label: 'Sua mão',
                      result: _playerResult.name,
                      cards: game.player.hand,
                    ),
                    const SizedBox(height: 14),
                    _HandSummary(
                      label: 'Mão do rival',
                      result: _opponentResult.name,
                      cards: game.opponent.hand,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Cartas comunitárias',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final card in game.communityCards)
                          PokerCardWidget(card: card, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: ActionButton(
                label: game.run.isVictory || game.run.isDefeat
                    ? 'Ver resultado final'
                    : 'Continuar',
                onPressed: _continue,
                primary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandSummary extends StatelessWidget {
  const _HandSummary({
    required this.label,
    required this.result,
    required this.cards,
  });

  final String label;
  final String result;
  final List<PlayingCard> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final card in cards)
                PokerCardWidget(card: card, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}
