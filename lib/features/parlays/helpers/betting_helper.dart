import 'package:big_board/features/parlays/models/game.dart';

class BettingHelper {
  static Bookmaker getBookmaker(Game game) {
    
    // Try FanDuel first
    final fanduel = game.bookmakers.where((b) => b.key == 'fanduel').toList();
    if (fanduel.isNotEmpty) {
      return fanduel.first;
    }
    
    // Try DraftKings second
    final draftkings = game.bookmakers.where((b) => b.key == 'draftkings').toList();
    if (draftkings.isNotEmpty) {
      return draftkings.first;
    }
    
    return game.bookmakers.first;
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
        name: teamName,
        price: 1.91,
        point: market.key == 'spreads' ? 0.0 : null,
      ),
    );
  }

  static String getSpreadValue(Game game, String teamName) {
    final bookmaker = getBookmaker(game);
    final market = getMarket(bookmaker, 'spread');
    final outcome = getOutcome(market, teamName);
    
    if (outcome.point == null) return '';
    return outcome.point! >= 0 ? '+${outcome.point}' : '${outcome.point}';
  }
} 