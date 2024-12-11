import 'package:uuid/uuid.dart';

class SavedParlay {
  final String id;
  final String userId;
  final DateTime createdAt;
  final List<SavedPick> picks;
  final int totalOdds;
  final double amount;
  final String status;
  final String? result;
  final DateTime? settledAt;
  final String? groupId;

  SavedParlay({
    String? id,
    required this.userId,
    required this.createdAt,
    required this.picks,
    required this.totalOdds,
    required this.amount,
    this.status = 'pending',
    this.result,
    this.settledAt,
    this.groupId,
  }) : assert(amount > 0, 'Amount must be greater than 0'),
     this.id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'events': picks.map((pick) => pick.toJson()).toList(),
    'odds': totalOdds,
    'stake': amount,
    'potential_payout': amount > 0 ? amount * ((totalOdds > 0) 
        ? (totalOdds / 100) + 1 
        : 1 - (100 / totalOdds)) : 0,
    'status': status,
    'result': result,
    'settled_at': settledAt?.toIso8601String(),
    'group_id': groupId,
  };

  factory SavedParlay.fromJson(Map<String, dynamic> json) {
    final amount = json['stake']?.toDouble() ?? 0.0;
    if (amount <= 0) {
      print('Warning: Invalid amount found in parlay: $amount');
      // Either use a default amount or handle it differently
    }
    
    return SavedParlay(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      picks: (json['events'] as List)
          .map((p) => SavedPick.fromJson(p))
          .toList(),
      totalOdds: json['odds'],
      amount: amount > 0 ? amount : 0.01,  // Use a minimum valid amount if zero
      status: json['status'] ?? 'pending',
      result: json['result'],
      settledAt: json['settled_at'] != null 
          ? DateTime.parse(json['settled_at']) 
          : null,
      groupId: json['group_id'],
    );
  }

  bool get isGroupParlay => groupId != null;

  String get displayTitle {
    final baseTitle = '${picks.length} Team Parlay';
    return isGroupParlay ? 'Group $baseTitle' : baseTitle;
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