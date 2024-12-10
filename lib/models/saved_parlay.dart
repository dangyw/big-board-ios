class SavedParlay {
  final String id;
  final DateTime createdAt;
  final List<SavedPick> picks;
  final int totalOdds;
  final double amount;

  SavedParlay({
    required this.id,
    required this.createdAt,
    required this.picks,
    required this.totalOdds,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'picks': picks.map((pick) => pick.toJson()).toList(),
    'totalOdds': totalOdds,
    'amount': amount,
  };

  factory SavedParlay.fromJson(Map<String, dynamic> json) {
    return SavedParlay(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      picks: (json['picks'] as List)
          .map((p) => SavedPick.fromJson(p))
          .toList(),
      totalOdds: json['totalOdds'],
      amount: json['amount']?.toDouble() ?? 0.0,
    );
  }
}

class SavedPick {
  final String teamName;
  final String opponent;
  final String betType;
  final double? spreadValue;
  final int odds;

  SavedPick({
    required this.teamName,
    required this.opponent,
    required this.betType,
    this.spreadValue,
    required this.odds,
  });

  Map<String, dynamic> toJson() => {
    'teamName': teamName,
    'opponent': opponent,
    'betType': betType,
    'spreadValue': spreadValue,
    'odds': odds,
  };

  factory SavedPick.fromJson(Map<String, dynamic> json) {
    return SavedPick(
      teamName: json['teamName'],
      opponent: json['opponent'],
      betType: json['betType'],
      spreadValue: json['spreadValue']?.toDouble(),
      odds: json['odds'],
    );
  }
} 