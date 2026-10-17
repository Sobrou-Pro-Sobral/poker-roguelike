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

  static const int maxTables = 5;

  int currentTable = 1;
  int playerChips;
  final Set<Upgrade> upgrades = <Upgrade>{};
  int winStreak = 0;
  bool insuranceUsed = false;
  bool isVictory = false;
  bool isDefeat = false;
  int? rewardedTable;

  bool get isBoss => currentTable == 3 || currentTable == 5;
  bool get isFinalTable => currentTable == maxTables;
  bool get isTerminal => isVictory || isDefeat;

  bool has(Upgrade upgrade) => upgrades.contains(upgrade);

  bool acquire(Upgrade upgrade) {
    if (isTerminal || upgrades.contains(upgrade)) return false;
    upgrades.add(upgrade);
    return true;
  }

  List<Upgrade> get availableUpgrades => Upgrade.values
      .where((upgrade) => !upgrades.contains(upgrade))
      .toList(growable: false);

  bool canClaimRewardFor(int table) =>
      table == currentTable && !isTerminal && rewardedTable != table;

  bool markRewardClaimed() {
    if (!canClaimRewardFor(currentTable)) return false;
    rewardedTable = currentTable;
    return true;
  }

  bool moveToNextTable() {
    if (isTerminal || currentTable >= maxTables) return false;
    currentTable += 1;
    return true;
  }

  RunState copy() {
    final result = RunState(playerChips: playerChips)
      ..currentTable = currentTable
      ..winStreak = winStreak
      ..insuranceUsed = insuranceUsed
      ..isVictory = isVictory
      ..isDefeat = isDefeat
      ..rewardedTable = rewardedTable;
    result.upgrades.addAll(upgrades);
    return result;
  }

  void copyFrom(RunState other) {
    currentTable = other.currentTable;
    playerChips = other.playerChips;
    upgrades
      ..clear()
      ..addAll(other.upgrades);
    winStreak = other.winStreak;
    insuranceUsed = other.insuranceUsed;
    isVictory = other.isVictory;
    isDefeat = other.isDefeat;
    rewardedTable = other.rewardedTable;
  }
}
