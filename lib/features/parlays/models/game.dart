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
    return Market(
      key: json['key'],
      lastUpdate: DateTime.parse(json['last_update']),
      outcomes: (json['outcomes'] as List)
          .map((o) => Outcome.fromJson(o))
          .toList(),
    );
  }
}

class Outcome {
  final String name;
  final int price;
  final double? point;

  Outcome({
    required this.name,
    required this.price,
    this.point,
  });

  factory Outcome.fromJson(Map<String, dynamic> json) {
    return Outcome(
      name: json['name'],
      price: json['price'],
      point: json['point']?.toDouble(),
    );
  }
} 