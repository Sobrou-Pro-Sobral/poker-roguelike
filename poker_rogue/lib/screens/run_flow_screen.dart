import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/run_state.dart';
import '../services/deck_api_service.dart';
import '../services/game_flow.dart';
import '../widgets/action_button.dart';
import 'poker_table_screen.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key, required this.game, required this.deckApi});

  final GameState game;
  final DeckApiService deckApi;

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _choose(Upgrade upgrade) async {
    if (_loading || !widget.game.rewardEligible) return;
    final run = widget.game.run;
    if (!run.canClaimRewardFor(run.currentTable)) return;

    // Prepara uma cópia. A run original só é confirmada depois que a API
    // criar o baralho e distribuir as cartas da próxima mesa.
    final candidate = run.copy();
    if (!candidate.acquire(upgrade) ||
        !candidate.markRewardClaimed() ||
        !candidate.moveToNextTable()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final nextGame = await createTableGame(
        run: candidate,
        deckApi: widget.deckApi,
      );
      if (!mounted) return;
      run.copyFrom(candidate);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PokerTableScreen(
            game: nextGame,
            deckApi: widget.deckApi,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upgrades = widget.game.run.availableUpgrades.take(3).toList();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECOMPENSA',
                style: TextStyle(
                  color: Color(0xFFE51B2B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Mesa ${widget.game.run.currentTable} concluída',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.game.run.playerChips} fichas · escolha uma vantagem para a próxima mesa.',
                style: const TextStyle(color: Colors.black54),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Color(0xFFE51B2B))),
              ],
              const SizedBox(height: 22),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: upgrades.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final upgrade = upgrades[index];
                          return _UpgradeCard(
                            upgrade: upgrade,
                            onTap: () => _choose(upgrade),
                          );
                        },
                      ),
              ),
              if (upgrades.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text('Todos os upgrades já foram adquiridos.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.upgrade, required this.onTap});

  final Upgrade upgrade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    upgrade.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add, color: Color(0xFFE51B2B)),
          ],
        ),
      ),
    );
  }
}

class RunResultScreen extends StatelessWidget {
  const RunResultScreen({super.key, required this.run});

  final RunState run;

  @override
  Widget build(BuildContext context) {
    final victory = run.isVictory;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FIM DA RUN',
                style: TextStyle(
                  color: Color(0xFFE51B2B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                victory ? 'Você venceu a run' : 'A run terminou',
                style: const TextStyle(
                  fontSize: 36,
                  height: .98,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                victory
                    ? 'O Banqueiro foi derrotado na mesa 5.'
                    : 'Suas fichas chegaram a zero antes do final.',
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                '${run.playerChips} fichas finais · ${run.upgrades.length} upgrades',
                style: const TextStyle(
                  color: Color(0xFFE51B2B),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(flex: 2),
              ActionButton(
                label: 'Nova run',
                primary: true,
                onPressed: () => Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                ),
              ),
              const SizedBox(height: 10),
              ActionButton(
                label: 'Voltar ao menu',
                onPressed: () => Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
