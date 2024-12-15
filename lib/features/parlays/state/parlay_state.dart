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
  Map<String, Game> _games = {};

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

  void togglePick(String gameId, String team, String betType) {
    final pickId = '$gameId-$betType-$team';
    notifyListeners();
    if (_selectedPicks.contains(pickId)) {
      _selectedPicks.remove(pickId);
    } else {
      _selectedPicks.add(pickId);
    }
    notifyListeners();
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

  int calculateTotalOdds() {
    if (selectedPicks.isEmpty) return 0;
    
    final List<int> odds = selectedPicks.map((pickId) {
      return getPickOdds(pickId).toInt();
    }).toList();
    
    return OddsCalculator.calculateParlayOdds(odds);
  }

  void setUnits(double value) {
    if (value > 0) {
      _units = value;
      notifyListeners();
    }
  }

  double getPickOdds(String pickId) {
    final pick = PickHelper(pickId);
    final game = _games[pick.gameId];
    if (game == null) return -110.0;
    
    final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
    
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final market = bookmaker.markets.firstWhere(
      (m) => m.key == (pick.betType == 'spread' ? 'spreads' : 'h2h'),
      orElse: () => Market(key: pick.betType == 'spread' ? 'spreads' : 'h2h', 
                          lastUpdate: DateTime.now(), 
                          outcomes: []),
    );

    final outcome = market.outcomes.firstWhere(
      (o) => o.name == selectedTeam,
      orElse: () => Outcome(name: '', price: -110, point: null),
    );

    return outcome.price.toDouble();
  }

  // Add method to get game by ID
  Game? getGameById(String id) => _games[id];

  // Add method to store game
  void addGame(Game game) {
    _games[game.id] = game;
    notifyListeners();
  }

  // Get formatted odds for a pick
  String getFormattedOdds(String pickId) {
    final pick = PickHelper(pickId);
    final game = getGameById(pick.gameId);
    if (game == null) return "+100";
    
    final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
    final bookmaker = BettingHelper.getBookmaker(game);
    final market = BettingHelper.getMarket(bookmaker, pick.betType);
    final outcome = BettingHelper.getOutcome(market, selectedTeam);
    
    return formatOdds(outcome.price);
  }

  String formatOdds(int odds) {
    if (odds >= 0) {
      return '+$odds';
    }
    return odds.toString();
  }

  // Get game details for display
  Map<String, String> getGameDetails(String pickId) {
    final pick = PickHelper(pickId);
    final game = _games[pick.gameId];
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
        'details': '${outcome.point} (${outcome.price})',
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

  int getOddsForPick(String pickId) {
    final pick = PickHelper(pickId);
    final game = _games[pick.gameId];
    if (game == null) return -110;
    
    final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
    final bookmaker = BettingHelper.getBookmaker(game);
    final market = BettingHelper.getMarket(bookmaker, pick.betType);
    final outcome = BettingHelper.getOutcome(market, selectedTeam);

    return outcome.price;
  }

  void updateGames(List<Game> games) {
    _games.clear();
    for (final game in games) {
      _games[game.id] = game;
    }
    notifyListeners();
  }
} 