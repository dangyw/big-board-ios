import 'package:big_board/features/parlays/models/game.dart';
import 'package:big_board/features/parlays/helpers/betting_helper.dart';
import 'package:big_board/core/utils/odds_calculator.dart';

class PickHelper {
  final String pickId;

  PickHelper(this.pickId);

  List<String> get parts => pickId.split('_');
  String get gameId => parts[0];
  String get outcomeId => parts[1];
  String get marketType => parts[2];
  
  bool get isHome => outcomeId == 'home';
  
  String get team {
    switch (outcomeId) {
      case 'home':
        return 'home';
      case 'away':
        return 'away';
      case 'over':
        return 'over';
      case 'under':
        return 'under';
      default:
        return '';
    }
  }

  String get betType => marketType;

  Outcome? getOutcome(Game? game) {
    if (game == null) return null;
    
    print('\n=== GetOutcome Debug ===');
    print('PickId: $pickId');
    print('Market Type: $marketType');
    print('Outcome ID: $outcomeId');
    
    final bookmaker = game.bookmakers.first;
    
    // Map market type to API key
    final marketKey = marketType == 'spread' ? 'spreads' : 'h2h';
    print('Looking for market key: $marketKey');
    
    final market = bookmaker.markets.firstWhere(
      (m) => m.key == marketKey,
      orElse: () => bookmaker.markets.first,
    );
    print('Found market with key: ${market.key}');

    final targetTeam = outcomeId == 'home' ? game.homeTeam : game.awayTeam;
    print('Target Team: $targetTeam');
    
    final outcome = market.outcomes.firstWhere(
      (o) => o.name == targetTeam,
      orElse: () => market.outcomes.first,
    );
    print('Selected Outcome: ${outcome.name} @ ${outcome.price} (point: ${outcome.point})');
    print('======================\n');
    
    return outcome;
  }

  double? getFormattedOdds(Game? game) {
    final outcome = getOutcome(game);
    return outcome?.price;
  }
}
