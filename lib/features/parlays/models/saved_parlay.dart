import 'package:uuid/uuid.dart';
import 'placeholder_pick.dart';

class SavedParlay {
  final String id;
  final String userId;
  final DateTime createdAt;
  final List<SavedPick> picks;
  final int totalOdds;
  final double units;
  final String status;
  final String? result;
  final DateTime? settledAt;
  final String? groupId;
  final List<PlaceholderPick>? placeholderPicks;

  SavedParlay({
    String? id,
    required this.userId,
    required this.createdAt,
    required this.picks,
    required this.totalOdds,
    required this.units,
    this.status = 'pending',
    this.result,
    this.settledAt,
    this.groupId,
    this.placeholderPicks,
  }) : assert(units > 0, 'Units must be greater than 0'),
     this.id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'events': picks.map((pick) => pick.toJson()).toList(),
    'odds': totalOdds,
    'stake': units,
    'potential_payout': units > 0 ? units * ((totalOdds > 0) 
        ? (totalOdds / 100) + 1 
        : 1 - (100 / totalOdds)) : 0,
    'status': status,
    'result': result,
    'settled_at': settledAt?.toIso8601String(),
    'group_id': groupId,
    'placeholder_picks': placeholderPicks?.map((p) => p.toJson()).toList(),
  };

  factory SavedParlay.fromJson(Map<String, dynamic> json) {
    final units = json['stake']?.toDouble() ?? 0.0;
    if (units <= 0) {
      print('Warning: Invalid units found in parlay: $units');
    }
    
    return SavedParlay(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      picks: (json['events'] as List)
          .map((p) => SavedPick.fromJson(p))
          .toList(),
      totalOdds: json['odds'],
      units: units > 0 ? units : 0.01,
      status: json['status'] ?? 'pending',
      result: json['result'],
      settledAt: json['settled_at'] != null 
          ? DateTime.parse(json['settled_at']) 
          : null,
      groupId: json['group_id'],
      placeholderPicks: json['placeholder_picks'] != null
          ? (json['placeholder_picks'] as List)
              .map((p) => PlaceholderPick.fromJson(p))
              .toList()
          : null,
    );
  }

  bool get isGroupParlay => groupId != null;

  String get displayTitle {
    final regularPicks = picks.length;
    final placeholderCount = placeholderPicks?.length ?? 0;
    final totalPicks = regularPicks + placeholderCount;
    
    final baseTitle = '$totalPicks Leg Parlay';
    
    if (isGroupParlay && placeholderCount > 0) {
      final pendingText = placeholderCount == totalPicks 
          ? '(All Pending)' 
          : '($placeholderCount Pending)';
      return '$baseTitle $pendingText';
    }
    
    return baseTitle;
  }

  bool get hasPlaceholderPicks => placeholderPicks?.isNotEmpty ?? false;
  int get pendingPicksCount => placeholderPicks?.length ?? 0;
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