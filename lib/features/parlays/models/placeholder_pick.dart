class PlaceholderPick {
  final String id;
  final String? teamName;
  final String? opponent;
  final String? betType;
  final double? spreadValue;
  final double? odds;
  final String? assignedUserId;

  PlaceholderPick({
    required this.id,
    this.teamName,
    this.opponent,
    this.betType,
    this.spreadValue,
    this.odds,
    this.assignedUserId,
  });

  double get price => odds ?? 0.0;

  PlaceholderPick copyWith({
    String? id,
    String? teamName,
    String? opponent,
    String? betType,
    double? spreadValue,
    double? odds,
    String? assignedUserId,
  }) {
    return PlaceholderPick(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      opponent: opponent ?? this.opponent,
      betType: betType ?? this.betType,
      spreadValue: spreadValue ?? this.spreadValue,
      odds: odds ?? this.odds,
      assignedUserId: assignedUserId ?? this.assignedUserId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamName': teamName,
    'opponent': opponent,
    'betType': betType,
    'spreadValue': spreadValue,
    'odds': odds,
    'assigned_member_id': assignedUserId,
  };

  factory PlaceholderPick.fromJson(Map<String, dynamic> json) => PlaceholderPick(
    id: json['id'],
    teamName: json['teamName'],
    opponent: json['opponent'],
    betType: json['betType'],
    spreadValue: json['spreadValue']?.toDouble(),
    odds: json['odds']?.toDouble(),
    assignedUserId: json['assigned_member_id'],
  );
} 