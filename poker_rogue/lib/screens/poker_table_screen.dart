import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/playing_card.dart';
import '../services/deck_api_service.dart';
import '../widgets/action_button.dart';
import '../widgets/poker_card_widget.dart';
import 'showdown_screen.dart';

class PokerTableScreen extends StatefulWidget {
  const PokerTableScreen({
    super.key,
    required this.game,
    required this.deckApi,
  });

  final GameState game;
  final DeckApiService deckApi;

  @override
  State<PokerTableScreen> createState() => _PokerTableScreenState();
}

class _PokerTableScreenState extends State<PokerTableScreen> {
  bool _isLoading = false;
  String? _error;

  GameState get game => widget.game;

  Future<void> _advanceRound() async {
    if (game.round == PokerRound.river) {
      _showdown();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drawCount = game.round == PokerRound.preFlop ? 3 : 1;
      final draw = await widget.deckApi.drawCards(game.deckId, drawCount);

      setState(() {
        game.communityCards.addAll(draw.cards);
        game.remainingCards = draw.remaining;
        game.pot += drawCount == 3 ? 12 : 24;
        game.round = switch (game.round) {
          PokerRound.preFlop => PokerRound.flop,
          PokerRound.flop => PokerRound.turn,
          PokerRound.turn => PokerRound.river,
          PokerRound.river => PokerRound.showdown,
          PokerRound.showdown => PokerRound.showdown,
        };
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fold() {
    game.opponentRevealed = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ShowdownScreen(game: game, folded: true),
      ),
    );
  }

  void _showdown() {
    game.round = PokerRound.showdown;
    game.opponentRevealed = true;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ShowdownScreen(game: game)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(game: game),
              const SizedBox(height: 14),
              _Stats(game: game),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _ErrorBox(message: _error!, onRetry: _advanceRound),
              ],
              const SizedBox(height: 14),
              _OpponentArea(game: game),
              const SizedBox(height: 12),
              Expanded(child: _CommunityArea(cards: game.communityCards)),
              const SizedBox(height: 12),
              _PlayerArea(cards: game.player.hand),
              const SizedBox(height: 14),
              _Actions(
                game: game,
                isLoading: _isLoading,
                onAdvance: _advanceRound,
                onFold: _fold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Rodada 01',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        Text(
          game.roundLabel,
          style: const TextStyle(
            color: Colors.black45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(label: 'FICHAS', value: '${game.player.stack}'),
        const SizedBox(width: 8),
        _StatTile(label: 'POTE', value: '${game.pot}', red: true),
        const SizedBox(width: 8),
        _StatTile(label: 'BARALHO', value: '${game.remainingCards}'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.red = false});

  final String label;
  final String value;
  final bool red;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
                color: Colors.black45,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: red ? const Color(0xFFE51B2B) : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpponentArea extends StatelessWidget {
  const _OpponentArea({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Rival - 120 fichas',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        for (final card in game.opponent.hand) ...[
          PokerCardWidget(
            card: card,
            hidden: !game.opponentRevealed,
            compact: true,
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _CommunityArea extends StatelessWidget {
  const _CommunityArea({required this.cards});

  final List<PlayingCard> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'CARTAS COMUNITÁRIAS',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              for (final card in cards)
                PokerCardWidget(card: card, compact: true),
              for (var i = cards.length; i < 5; i++)
                const PokerCardWidget(hidden: true, compact: true),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PlayerArea extends StatelessWidget {
  const _PlayerArea({required this.cards});

  final List<PlayingCard> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              'BTN',
              style: TextStyle(
                color: Color(0xFFE51B2B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        for (final card in cards) ...[
          PokerCardWidget(card: card),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.game,
    required this.isLoading,
    required this.onAdvance,
    required this.onFold,
  });

  final GameState game;
  final bool isLoading;
  final VoidCallback onAdvance;
  final VoidCallback onFold;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = switch (game.round) {
      PokerRound.preFlop => 'Apostar 6',
      PokerRound.flop => 'Apostar 12',
      PokerRound.turn => 'Apostar 24',
      PokerRound.river => 'Confronto',
      PokerRound.showdown => 'Continuar',
    };

    return Column(
      children: [
        ActionButton(
          label: isLoading ? 'Comprando...' : primaryLabel,
          onPressed: isLoading ? null : onAdvance,
          primary: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: 'Passar',
                onPressed: isLoading ? null : onAdvance,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                label: 'Desistir',
                onPressed: isLoading ? null : onFold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        border: Border.all(color: const Color(0xFFE51B2B)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFE51B2B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
