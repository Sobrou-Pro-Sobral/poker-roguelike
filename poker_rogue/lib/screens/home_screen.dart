import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/player.dart';
import '../services/deck_api_service.dart';
import '../widgets/action_button.dart';
import 'poker_table_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DeckApiService _deckApi = DeckApiService();
  bool _isLoading = false;
  String? _error;

  Future<void> _startGame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deckId = await _deckApi.createShuffledDeck();
      final draw = await _deckApi.drawCards(deckId, 4);
      final cards = draw.cards;
      final game = GameState(
        deckId: deckId,
        player: Player(name: 'Você', stack: 120, hand: cards.sublist(0, 2)),
        opponent: Player(name: 'Rival', stack: 120, hand: cards.sublist(2, 4)),
        communityCards: [],
        pot: 12,
        remainingCards: draw.remaining,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PokerTableScreen(game: game, deckApi: _deckApi),
        ),
      );
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

  void _showHowItWorks() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como funciona'),
        content: const Text(
          'Jogue uma mão de Texas Holdem contra um bot simples. Avance pelo '
          'pré-flop, flop, turn, river e confronto para comparar as melhores mãos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? _LoadingState()
              : _HomeContent(
                  error: _error,
                  onStart: _startGame,
                  onHowItWorks: _showHowItWorks,
                ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.error,
    required this.onStart,
    required this.onHowItWorks,
  });

  final String? error;
  final VoidCallback onStart;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROGUELIKE / HOLD EM',
          style: TextStyle(
            color: Color(0xFFE51B2B),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        const Text(
          'POKER\nROGUELIKE',
          style: TextStyle(
            color: Colors.black,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Uma partida solo de Texas Holdem em que cada mão pode mudar a rodada.',
          style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.35),
        ),
        if (error != null) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE51B2B)),
            ),
            child: Text(
              'Problema de conexão\n$error',
              style: const TextStyle(
                color: Color(0xFFE51B2B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(flex: 2),
        ActionButton(label: 'Nova partida', onPressed: onStart, primary: true),
        const SizedBox(height: 10),
        ActionButton(label: 'Como funciona', onPressed: onHowItWorks),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOVA PARTIDA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4),
        ),
        Spacer(),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFFE51B2B)),
              SizedBox(height: 28),
              Text(
                'Preparando o baralho',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Embaralhando cartas e iniciando a mão.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        Spacer(flex: 2),
      ],
    );
  }
}
