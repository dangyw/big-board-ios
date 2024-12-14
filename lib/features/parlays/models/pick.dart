class Pick {
  final String id;
  final String teamName;
  final String betType;
  final double? spreadValue;
  final int odds;

  Pick({
    required this.id,
    required this.teamName,
    required this.betType,
    this.spreadValue,
    required this.odds,
  });
} 