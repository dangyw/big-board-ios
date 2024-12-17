import 'package:flutter/foundation.dart';
import 'package:big_board/features/parlays/models/placeholder_pick.dart';
import 'package:big_board/features/parlays/models/game.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/core/utils/odds_calculator.dart';
import 'package:big_board/features/parlays/helpers/pick_helper.dart';
import 'package:big_board/features/parlays/helpers/betting_helper.dart';

class ParlayState extends ChangeNotifier {
  // Existing state
  bool _isGroupMode = false;
  Set<String> _selectedPicks = {};
  String? _selectedGroupId;
  List<PlaceholderPick> _placeholderPicks = [];
  double _units = 1.0;

  // Add game storage
  List<Game> _games = [];

  // Getters
  bool get isGroupMode => _isGroupMode;
  Set<String> get selectedPicks => _selectedPicks;
  String? get selectedGroupId => _selectedGroupId;
  List<PlaceholderPick> get placeholderPicks => _placeholderPicks;
  double get units => _units;

  // Methods
  void toggleGroupMode(bool value) {
    _isGroupMode = value;
    if (!value) {
      _placeholderPicks.clear();
      _selectedGroupId = null;
    }
    notifyListeners();
  }

  void setSelectedGroup(String? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }

  void updateUnits(double value) {
    _units = value;
    notifyListeners();
  }

  void addPlaceholderPick() {
    _placeholderPicks.add(
      PlaceholderPick(
        id: DateTime.now().toString(),
        assignedUserId: null,
      ),
    );
    notifyListeners();
  }

  void removePlaceholderPick(String pickId) {
    _placeholderPicks.removeWhere((pick) => pick.id == pickId);
    notifyListeners();
  }

  void assignUserToPlaceholder(String pickId, String? userId) {
    final index = _placeholderPicks.indexWhere((p) => p.id == pickId);
    if (index != -1) {
      _placeholderPicks[index] = _placeholderPicks[index].copyWith(
        assignedUserId: userId,
      );
      notifyListeners();
    }
  }

  void clearParlay() {
    _selectedPicks.clear();
    _placeholderPicks.clear();
    _selectedGroupId = null;
    _units = 1.0;
    notifyListeners();
  }

  void togglePick(String gameId, String outcomeId, String betType) {
    final pickId = '${gameId}_${outcomeId}_${betType}';
    
    // If this exact pick is already selected, remove it and return
    if (_selectedPicks.contains(pickId)) {
      _selectedPicks.remove(pickId);
      notifyListeners();
      return;
    }
    
    // Remove any other picks from the same game
    _selectedPicks.removeWhere((pick) {
      final existingGameId = pick.split('_')[0];
      return existingGameId == gameId;
    });

    // Add the new pick
    _selectedPicks.add(pickId);
    notifyListeners();
  }

  void removePick(String pickId) {
    _selectedPicks.remove(pickId);
    notifyListeners();
  }

  void setGroupMode(bool value) {
    _isGroupMode = value;
    notifyListeners();
  }

  double calculateTotalOdds() {
    if (_selectedPicks.isEmpty) return 0.0;
    
    List<double> decimalOdds = [];
    for (final pickId in _selectedPicks) {
      final odds = getOddsForPick(pickId);
      decimalOdds.add(odds);
    }
    
    return OddsCalculator.calculateParlayOdds(decimalOdds);
  }

  void setUnits(double value) {
    if (value > 0) {
      _units = value;
      notifyListeners();
    }
  }

  double getOddsForPick(String pickId) {
    final parts = pickId.split('_');
    final gameId = parts[0];
    final outcomeId = parts[1];  // 'home' or 'away'
    final betType = parts[2];    // 'spread' or 'moneyline'
    
    final game = getGameById(gameId);
    if (game == null) return 1.0;
    
    final bookmaker = game.bookmakers.first;
    
    // Map bet type to market key
    final marketKey = betType == 'spread' ? 'spreads' : 'h2h';
    
    final market = bookmaker.markets.firstWhere(
      (m) => m.key == marketKey,
      orElse: () => bookmaker.markets.first,
    );
    
    // Use the game's homeTeam/awayTeam properties
    final targetTeam = outcomeId == 'home' ? game.homeTeam : game.awayTeam;
    
    final outcome = market.outcomes.firstWhere(
      (o) => o.name == targetTeam,
      orElse: () => market.outcomes.first,
    );
    
    return outcome.price;
  }

  Game? getGameById(String gameId) {
    try {
      return _games.firstWhere((g) => g.id == gameId);
    } catch (e) {
      return null;
    }
  }

  void addGame(Game game) {
    _games.add(game);
    notifyListeners();
  }

  String getFormattedOdds(String pickId) {
    try {
      print('\n=== getFormattedOdds Debug ===');
      print('PickId: $pickId');
      
      final pick = PickHelper(pickId);
      final game = getGameById(pick.gameId);
      
      if (game == null) {
        print('Game not found!');
        return "-110";
      }
      
      print('Game found: ${game.homeTeam} vs ${game.awayTeam}');
      final odds = pick.getOutcome(game)?.price ?? 0.0;
      print('Odds: $odds');
      print('========================\n');
      
      return OddsCalculator.formatOdds(odds);
    } catch (e) {
      print('Error in getFormattedOdds: $e');
      return "-110";
    }
  }

  Map<String, String> getGameDetails(String pickId) {
    final pick = PickHelper(pickId);
    final game = getGameById(pick.gameId);
    if (game == null) {
      return {
        'team': pick.team,
        'opponent': 'Unknown',
        'details': '',
      };
    }

    final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
    final opponent = pick.isHome ? game.awayTeam : game.homeTeam;
    
    if (pick.betType == 'spread') {
      final bookmaker = BettingHelper.getBookmaker(game);
      final market = BettingHelper.getMarket(bookmaker, 'spread');
      final outcome = BettingHelper.getOutcome(market, selectedTeam);

      return {
        'team': selectedTeam,
        'opponent': opponent,
        'details': '${outcome.point} (${OddsCalculator.formatOdds(outcome.price)})',
      };
    }

    return {
      'team': selectedTeam,
      'opponent': opponent,
      'details': '',
    };
  }

  String getSpreadForTeam(Game? game, String team) {
    if (game == null) return "0";
    
    final bookmaker = BettingHelper.getBookmaker(game);
    final market = BettingHelper.getMarket(bookmaker, 'spread');
    final outcome = BettingHelper.getOutcome(market, team);
    
    final point = outcome.point ?? 0;
    return point >= 0 ? '+$point' : point.toString();
  }

  void updateGames(List<Game> games) {
    _games = games;
    notifyListeners();
  }

  String getFormattedOddsForPick(String pickId) {
    final odds = getOddsForPick(pickId);
    return OddsCalculator.formatOdds(odds);
  }

  void addPick(String pickId) {
    _selectedPicks.add(pickId);
    notifyListeners();
  }
} 