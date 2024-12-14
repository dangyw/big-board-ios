import 'package:flutter/foundation.dart';
import '../models/placeholder_pick.dart';
import '../models/game.dart';
import '../../groups/models/group.dart';
import '../../../core/utils/odds_calculator.dart';

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
    print('ParlayState.togglePick implementation called'); // Debug print
    final pickId = '$gameId-$betType-$team';
    
    if (_selectedPicks.contains(pickId)) {
      print('Removing pick: $pickId'); // Debug print
      _selectedPicks.remove(pickId);
    } else {
      print('Adding pick: $pickId'); // Debug print
      _selectedPicks.add(pickId);
    }
    
    notifyListeners();
    print('Current selectedPicks: $_selectedPicks'); // Debug print
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
    final parts = pickId.split('-');
    final gameId = parts[0];
    final betType = parts[1];
    final team = parts[2];
    
    final game = _games[gameId];
    if (game == null) return -110.0;
    
    final isHome = team == 'home';
    final selectedTeam = isHome ? game.homeTeam : game.awayTeam;
    
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final market = bookmaker.markets.firstWhere(
      (m) => m.key == (betType == 'spread' ? 'spreads' : 'h2h'),
      orElse: () => Market(key: betType == 'spread' ? 'spreads' : 'h2h', 
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
    final parts = pickId.split('-');
    final gameId = parts[0];
    final betType = parts[1];
    final team = parts[2];
    final game = getGameById(gameId);
    
    if (game == null) return "+100";
    
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    if (betType == 'spread') {
      final market = bookmaker.markets.firstWhere(
        (m) => m.key == 'spreads',
        orElse: () => Market(key: 'spreads', lastUpdate: DateTime.now(), outcomes: []),
      );
      
      final outcome = market.outcomes.firstWhere(
        (o) => o.name == team,
        orElse: () => Outcome(name: '', price: -110, point: 0),
      );
      
      return formatOdds(outcome.price); // Will show as (-110) for spreads
    } else {
      final market = bookmaker.markets.firstWhere(
        (m) => m.key == 'h2h', // Note: moneyline is 'h2h' in the API
        orElse: () => Market(key: 'h2h', lastUpdate: DateTime.now(), outcomes: []),
      );
      
      final outcome = market.outcomes.firstWhere(
        (o) => o.name == team,
        orElse: () => Outcome(name: '', price: 100, point: null),
      );
      
      return formatOdds(outcome.price); // Will show as just +110 for moneyline
    }
  }

  String formatOdds(int odds) {
    if (odds >= 0) {
      return '+$odds';
    }
    return odds.toString();
  }

  // Get game details for display
  Map<String, String> getGameDetails(String pickId) {
    final parts = pickId.split('-');
    final gameId = parts[0];
    final betType = parts[1];
    final team = parts[2];
    
    print('Looking up game with id: $gameId'); // Debug
    print('Available games in ParlayState: ${_games.keys.toList()}'); // Debug
    
    final game = _games[gameId];
    if (game == null) {
      print('Game not found in ParlayState!'); // Debug
      return {
        'team': team,
        'opponent': 'Unknown',
        'details': '',
      };
    }

    final isHome = team == 'home';
    final selectedTeam = isHome ? game.homeTeam : game.awayTeam;
    final opponent = isHome ? game.awayTeam : game.homeTeam;
    
    if (betType == 'spread') {
      final bookmaker = game.bookmakers.firstWhere(
        (b) => b.key == 'fanduel',
        orElse: () => game.bookmakers.first,
      );
      
      final spreads = bookmaker.markets.firstWhere(
        (m) => m.key == 'spreads',
        orElse: () => Market(key: 'spreads', lastUpdate: DateTime.now(), outcomes: []),
      );

      final outcome = spreads.outcomes.firstWhere(
        (o) => o.name == selectedTeam,
        orElse: () => Outcome(name: '', price: 0, point: 0),
      );

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
    
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final spreads = bookmaker.markets.firstWhere(
      (m) => m.key == 'spreads',
      orElse: () => Market(key: 'spreads', lastUpdate: DateTime.now(), outcomes: []),
    );
    
    final outcome = spreads.outcomes.firstWhere(
      (o) => o.name == team,
      orElse: () => Outcome(name: '', price: -110, point: 0),
    );
    
    final point = outcome.point ?? 0;
    return point >= 0 ? '+$point' : point.toString();
  }

  int getOddsForPick(String pickId) {
    final parts = pickId.split('-');
    final gameId = parts[0];
    final betType = parts[1];
    final team = parts[2];
    
    final game = _games[gameId];
    if (game == null) return -110; // Default odds
    
    final isHome = team == 'home';
    final selectedTeam = isHome ? game.homeTeam : game.awayTeam;
    
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final market = bookmaker.markets.firstWhere(
      (m) => m.key == (betType == 'spread' ? 'spreads' : 'h2h'),
      orElse: () => Market(key: betType == 'spread' ? 'spreads' : 'h2h', 
                          lastUpdate: DateTime.now(), 
                          outcomes: []),
    );

    final outcome = market.outcomes.firstWhere(
      (o) => o.name == selectedTeam,
      orElse: () => Outcome(name: '', price: 100, point: null),
    );

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