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
  bool _dialogOpen = false;
  String? _error;

  GameState get game => widget.game;

  Future<void> _pass() async {
    if (_isLoading || !game.canCheck) return;
    final checkpoint = game.checkpoint();
    if (!game.check()) return;
    await _finishAction(checkpoint);
  }

  Future<void> _call() async {
    if (_isLoading || !game.canCall) return;
    final checkpoint = game.checkpoint();
    if (!game.call()) return;
    await _finishAction(checkpoint);
  }

  Future<void> _submitRaise(int amount) async {
    if (_isLoading) return;
    final checkpoint = game.checkpoint();
    final accepted = game.hasPendingCall
        ? game.raise(game.playerRoundContribution + amount)
        : game.bet(amount);
    if (!accepted) return;
    await _finishAction(checkpoint);
  }

  Future<void> _allIn() async {
    if (_isLoading || !game.canAllIn) return;
    final checkpoint = game.checkpoint();
    if (!game.allIn()) return;
    await _finishAction(checkpoint);
  }

  Future<void> _finishAction(GameStateCheckpoint checkpoint) async {
    if (game.resolved) {
      _showdown();
      return;
    }
    if (game.hasPendingCall) {
      if (mounted) setState(() {});
      return;
    }
    await _advanceStreet(checkpoint);
  }

  Future<void> _advanceStreet(GameStateCheckpoint checkpoint) async {
    if (_isLoading || game.resolved) return;
    if (game.round == PokerRound.river) {
      game.closeBettingRound();
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
      if (!mounted) return;
      setState(() {
        game.communityCards.addAll(draw.cards);
        game.remainingCards = draw.remaining;
        game.closeBettingRound();
        game.round = switch (game.round) {
          PokerRound.preFlop => PokerRound.flop,
          PokerRound.flop => PokerRound.turn,
          PokerRound.turn => PokerRound.river,
          PokerRound.river => PokerRound.showdown,
          PokerRound.showdown => PokerRound.showdown,
        };
      });
    } catch (error) {
      game.restore(checkpoint);
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fold() {
    if (_isLoading || game.resolved) return;
    game.settle(folded: true);
    _showdown();
  }

  void _showdown() {
    if (!mounted) return;
    game.round = PokerRound.showdown;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ShowdownScreen(game: game, deckApi: widget.deckApi),
      ),
    );
  }

  Future<void> _showRaisePanel() async {
    if (_isLoading || !game.canRaise && !game.canBet) {
      if (game.canAllIn) await _allIn();
      return;
    }
    final minimum = game.minimumActionAmount;
    final maximum = game.maxActionAmount;
    if (minimum > maximum) {
      await _allIn();
      return;
    }

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var value = minimum.toDouble();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final divisions = maximum > minimum ? maximum - minimum : 1;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escolha o aumento',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Valor desta ação: ${value.round()} fichas',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Slider(
                      min: minimum.toDouble(),
                      max: maximum.toDouble(),
                      divisions: divisions,
                      value: value,
                      activeColor: const Color(0xFFE51B2B),
                      onChanged: (next) => setSheetState(() => value = next),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            label: 'Cancelar',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ActionButton(
                            label: 'Confirmar ${value.round()}',
                            primary: true,
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(value.round()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _allInFromSheet(sheetContext),
                        child: const Text('Ir all-in'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected != null && mounted) await _submitRaise(selected);
  }

  void _allInFromSheet(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    _allIn();
  }

  Future<void> _confirmAbandon() async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;
    final abandon = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonar a partida?'),
        content: const Text('O progresso desta mão será encerrado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continuar jogando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (abandon == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmAbandon();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  game: game,
                  onQuit: () {
                    _confirmAbandon();
                  },
                ),
                const SizedBox(height: 10),
                if (game.isBoss) _BossBanner(game: game),
                const SizedBox(height: 10),
                _Stats(game: game),
                const SizedBox(height: 8),
                _BetIndicators(game: game),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBox(
                    message: _error!,
                    onRetry: () {
                      _pass();
                    },
                  ),
                ],
                const SizedBox(height: 10),
                _OpponentArea(game: game),
                const SizedBox(height: 8),
                Expanded(child: _CommunityArea(cards: game.communityCards)),
                const SizedBox(height: 8),
                _PlayerArea(cards: game.player.hand, stack: game.player.stack),
                const SizedBox(height: 10),
                _Actions(
                  game: game,
                  isLoading: _isLoading,
                  onCall: () {
                    _call();
                  },
                  onPass: () {
                    _pass();
                  },
                  onRaise: () {
                    _showRaisePanel();
                  },
                  onFold: _fold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.onQuit});

  final GameState game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Mesa ${game.run.currentTable} / 5',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        Text(
          game.roundLabel,
          style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w700),
        ),
        IconButton(
          tooltip: 'Abandonar a partida',
          onPressed: onQuit,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _BossBanner extends StatelessWidget {
  const _BossBanner({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        border: Border.all(color: const Color(0xFFE51B2B)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BOSS · ${game.bossName}',
            style: const TextStyle(
              color: Color(0xFFE51B2B),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 3),
          Text(
            game.bossRule,
            style: const TextStyle(
              color: Color(0xFFE51B2B),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.3,
            ),
            softWrap: true,
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w900)),
            Text(value, style: TextStyle(color: red ? const Color(0xFFE51B2B) : Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _BetIndicators extends StatelessWidget {
  const _BetIndicators({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(child: _BetLine(label: 'Você', value: game.playerRoundContribution)),
          Expanded(child: _BetLine(label: 'Rival', value: game.opponentRoundContribution)),
          if (game.hasPendingCall)
            Text(
              'Paga ${game.amountToCall}',
              style: const TextStyle(color: Color(0xFFE51B2B), fontWeight: FontWeight.w900, fontSize: 12),
            )
          else
            Text(game.lastAction, style: const TextStyle(color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _BetLine extends StatelessWidget {
  const _BetLine({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text('$label +$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12));
  }
}

class _OpponentArea extends StatelessWidget {
  const _OpponentArea({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('${game.opponent.name} · ${game.opponent.stack} fichas', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
        ),
        for (final card in game.opponent.hand) ...[
          PokerCardWidget(card: card, hidden: !game.opponentRevealed, compact: true, animate: true),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          const Text('CARTAS COMUNITÁRIAS', style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w900)),
          const Spacer(),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              for (final card in cards) PokerCardWidget(key: ValueKey(card.code), card: card, compact: true, animate: true),
              for (var i = cards.length; i < 5; i++) const PokerCardWidget(hidden: true, compact: true, animate: true),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PlayerArea extends StatelessWidget {
  const _PlayerArea({required this.cards, required this.stack});
  final List<PlayingCard> cards;
  final int stack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Você', style: TextStyle(fontWeight: FontWeight.w900)),
            Text('BTN · $stack', style: const TextStyle(color: Color(0xFFE51B2B), fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(width: 12),
        for (final card in cards) ...[
          PokerCardWidget(card: card, animate: true),
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
    required this.onCall,
    required this.onPass,
    required this.onRaise,
    required this.onFold,
  });

  final GameState game;
  final bool isLoading;
  final VoidCallback onCall;
  final VoidCallback onPass;
  final VoidCallback onRaise;
  final VoidCallback onFold;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = game.hasPendingCall ? 'Pagar ${game.amountToCall}' : 'Passar';
    final canIncrease = game.canRaise || game.canBet;
    return Column(
      children: [
        ActionButton(
          label: isLoading
              ? 'Comprando cartas...'
              : canIncrease
              ? 'Aumentar'
              : game.canAllIn
              ? 'Ir all-in'
              : 'Aumento indisponível',
          onPressed: isLoading || (!canIncrease && !game.canAllIn) ? null : onRaise,
          primary: true,
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: secondaryLabel,
                onPressed: isLoading || (game.hasPendingCall ? !game.canCall : !game.canCheck)
                    ? null
                    : game.hasPendingCall
                    ? onCall
                    : onPass,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(child: ActionButton(label: 'Desistir', onPressed: isLoading ? null : onFold)),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFFEEF0), border: Border.all(color: const Color(0xFFE51B2B)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFE51B2B), fontWeight: FontWeight.w700))),
          TextButton(onPressed: onRetry, child: const Text('Tentar')),
        ],
      ),
    );
  }
}
