import 'package:flutter/material.dart';

import '../models/run_state.dart';
import '../services/deck_api_service.dart';
import '../services/game_flow.dart';
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

  Future<void> _startRun() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final run = RunState();
      final game = await createTableGame(run: run, deckApi: _deckApi);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PokerTableScreen(game: game, deckApi: _deckApi),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showHowItWorks() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como funciona'),
        content: const Text(
          'Você começa com 120 fichas e joga até cinco mesas. Depois de cada vitória, '
          'escolha um upgrade antes de continuar. As mesas 3 e 5 têm bosses simples.',
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
              ? const _LoadingState()
              : _HomeContent(
                  error: _error,
                  onStart: _startRun,
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
        ActionButton(label: 'Nova run', onPressed: onStart, primary: true),
        const SizedBox(height: 10),
        ActionButton(label: 'Como funciona', onPressed: onHowItWorks),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOVA RUN',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4),
        ),
        Spacer(),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFFE51B2B)),
              SizedBox(height: 28),
              Text(
                'Preparando a mesa 1',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Embaralhando cartas e iniciando a run.',
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
