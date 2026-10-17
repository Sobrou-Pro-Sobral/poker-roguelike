enum Upgrade {
  insurance,
  kingOfSpades,
  queenOfHearts,
  tenOfClubs,
}

extension UpgradeDetails on Upgrade {
  String get title => switch (this) {
    Upgrade.insurance => 'Seguro',
    Upgrade.kingOfSpades => 'Rei de Espadas',
    Upgrade.queenOfHearts => 'Rainha de Copas',
    Upgrade.tenOfClubs => 'Dez de Paus',
  };

  String get description => switch (this) {
    Upgrade.insurance => 'Na primeira derrota, devolve 10 fichas.',
    Upgrade.kingOfSpades => 'Ao vencer um boss, ganha +25% do pote.',
    Upgrade.queenOfHearts => 'Ao vencer com par ou melhor, ganha +5 fichas.',
    Upgrade.tenOfClubs => 'Após duas vitórias seguidas, ganha +10 fichas.',
  };
}

class RunState {
  RunState({this.playerChips = 120});

  int currentTable = 1;
  int playerChips;
  final Set<Upgrade> upgrades = <Upgrade>{};
  int winStreak = 0;
  bool insuranceUsed = false;
  bool isVictory = false;
  bool isDefeat = false;

  bool get isBoss => currentTable == 3 || currentTable == 5;
  bool get isFinalTable => currentTable == 5;

  bool has(Upgrade upgrade) => upgrades.contains(upgrade);

  void acquire(Upgrade upgrade) => upgrades.add(upgrade);

  List<Upgrade> get availableUpgrades => Upgrade.values
      .where((upgrade) => !upgrades.contains(upgrade))
      .toList(growable: false);

  void moveToNextTable() {
    currentTable += 1;
  }
}
