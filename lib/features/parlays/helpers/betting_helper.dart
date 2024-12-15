import 'package:big_board/features/parlays/models/game.dart';

class BettingHelper {
  static Bookmaker getBookmaker(Game game) {
    return game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
  }

  static Market getMarket(Bookmaker bookmaker, String betType) {
    final marketKey = betType == 'spread' ? 'spreads' : 'h2h';
    return bookmaker.markets.firstWhere(
      (m) => m.key == marketKey,
      orElse: () => Market(
        key: marketKey, 
        lastUpdate: DateTime.now(), 
        outcomes: [],
      ),
    );
  }

  static Outcome getOutcome(Market market, String teamName) {
    return market.outcomes.firstWhere(
      (o) => o.name == teamName,
      orElse: () => Outcome(
        name: '', 
        price: -110, 
        point: null,
      ),
    );
  }
} 