import 'package:big_board/core/utils/odds_calculator.dart';
import 'dart:math';

class Game {
  final String id;
  final String sportKey;
  final String sportTitle;
  final DateTime commenceTime;
  final String homeTeam;
  final String awayTeam;
  final List<Bookmaker> bookmakers;

  Game({
    required this.id,
    required this.sportKey,
    required this.sportTitle,
    required this.commenceTime,
    required this.homeTeam,
    required this.awayTeam,
    required this.bookmakers,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      sportKey: json['sport_key'],
      sportTitle: json['sport_title'],
      commenceTime: DateTime.parse(json['commence_time']),
      homeTeam: json['home_team'],
      awayTeam: json['away_team'],
      bookmakers: (json['bookmakers'] as List)
          .map((b) => Bookmaker.fromJson(b))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sport_key': sportKey,
    'sport_title': sportTitle,
    'commence_time': commenceTime.toIso8601String(),
    'home_team': homeTeam,
    'away_team': awayTeam,
    'bookmakers': bookmakers.map((b) => b.toJson()).toList(),
  };

  Outcome? get homeOutcome {
    final market = bookmakers.firstOrNull?.markets.firstOrNull;
    return market?.outcomes.firstWhere(
      (o) => o.name == homeTeam,
      orElse: () => Outcome(name: homeTeam, price: 0),
    );
  }

  Outcome? get awayOutcome {
    final market = bookmakers.firstOrNull?.markets.firstOrNull;
    return market?.outcomes.firstWhere(
      (o) => o.name == awayTeam,
      orElse: () => Outcome(name: awayTeam, price: 0),
    );
  }

  Outcome? get overOutcome {
    final market = bookmakers.firstOrNull?.markets
        .firstWhere((m) => m.key == 'totals', 
            orElse: () => Market(key: '', lastUpdate: DateTime.now(), outcomes: []));
    if (market == null) return null;
    
    try {
      return market.outcomes.firstWhere(
        (o) => o.name.toLowerCase() == 'over',
        orElse: () => Outcome(name: 'over', price: 0),
      );
    } catch (e) {
      return null;
    }
  }

  Outcome? get underOutcome {
    final market = bookmakers.firstOrNull?.markets
        .firstWhere((m) => m.key == 'totals', 
            orElse: () => Market(key: '', lastUpdate: DateTime.now(), outcomes: []));
    if (market == null) return null;
    
    try {
      return market.outcomes.firstWhere(
        (o) => o.name.toLowerCase() == 'under',
        orElse: () => Outcome(name: 'under', price: 0),
      );
    } catch (e) {
      return null;
    }
  }
}

class Bookmaker {
  final String key;
  final String title;
  final DateTime lastUpdate;
  final List<Market> markets;

  Bookmaker({
    required this.key,
    required this.title,
    required this.lastUpdate,
    required this.markets,
  });

  factory Bookmaker.fromJson(Map<String, dynamic> json) {
    return Bookmaker(
      key: json['key'],
      title: json['title'],
      lastUpdate: DateTime.parse(json['last_update']),
      markets: (json['markets'] as List)
          .map((m) => Market.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'last_update': lastUpdate.toIso8601String(),
    'markets': markets.map((m) => m.toJson()).toList(),
  };
}

class Market {
  final String key;
  final DateTime lastUpdate;
  final List<Outcome> outcomes;

  Market({
    required this.key,
    required this.lastUpdate,
    required this.outcomes,
  });

  factory Market.fromJson(Map<String, dynamic> json) {

    final market = Market(
      key: json['key'],
      lastUpdate: DateTime.parse(json['last_update']),
      outcomes: (json['outcomes'] as List)
          .map((o) {

            final outcome = Outcome.fromJson(o);
            return outcome;
          })
          .toList(),
    );
    
    return market;
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'last_update': lastUpdate.toIso8601String(),
    'outcomes': outcomes.map((o) => o.toJson()).toList(),
  };
}

class Outcome {
  final String name;
  final double price;
  final double? point;

  const Outcome({
    required this.name,
    required this.price,
    this.point,
  });

  factory Outcome.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'] as num;
    return Outcome(
      name: json['name'],
      price: rawPrice.toDouble(),
      point: json['point']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'point': point,
  };

  int get americanOdds {
    if (price >= 2.0) {
      return ((price - 1) * 100).round();
    } else {
      return (-100 / (price - 1)).round();
    }
  }
} 