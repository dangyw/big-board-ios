import 'package:flutter/material.dart';
import '../models/game.dart';
import '../utils/load_mock_data.dart';
import '../widgets/game_matchup.dart';
import '../widgets/parlay_card.dart';
import '../services/parlay_service.dart';
import '../models/saved_parlay.dart';
import 'saved_parlays_screen.dart';
import '../utils/odds_calculator.dart';
import '../widgets/save_parlay_modal.dart';
import 'settings/profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Game> games = [];
  String searchQuery = '';
  bool isLoading = false;
  Set<String> selectedPicks = {};
  final ParlayService _parlayService = ParlayService();
  double _cardHeight = 200;  // Default height (middle ground)
  double _minHeight = 80;    // Minimum height
  double _maxHeight = 400;   // Maximum height
  List<double> _snapHeights = [80, 120, 160, 200, 240, 300, 400];  // More granular control

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    setState(() {
      isLoading = true;
    });
    
    final loadedGames = await MockDataLoader.loadGames();
    
    setState(() {
      games = loadedGames;
      isLoading = false;
    });
  }

  void togglePick(String gameId, String betType, String team) {
    setState(() {
      final pickId = '$gameId-$betType-$team';
      
      if (selectedPicks.contains(pickId)) {
        // If already selected, just remove it
        selectedPicks.remove(pickId);
      } else {
        // Remove any existing pick for this game
        selectedPicks.removeWhere((pick) => pick.startsWith(gameId));
        
        // Add the new pick
        selectedPicks.add(pickId);
        
        // Snap back to default height when adding a new pick
        _cardHeight = 200;  // Default height
      }
    });
  }

  void removePick(String pickId) {
    setState(() {
      selectedPicks.remove(pickId);
    });
  }

  Future<void> _saveParlay() async {
    if (selectedPicks.isEmpty) return;

    final picks = selectedPicks.map((pickId) {
      final parts = pickId.split('-');
      final gameId = parts[0];
      final betType = parts[1];
      final team = parts[2];
      
      final game = games.firstWhere((g) => g.id == gameId);
      final teamName = team == 'home' ? game.homeTeam : game.awayTeam;
      final opponent = team == 'home' ? game.awayTeam : game.homeTeam;
      
      final bookmaker = game.bookmakers.firstWhere(
        (b) => b.key == 'fanduel',
        orElse: () => game.bookmakers.first,
      );
      
      final market = bookmaker.markets.firstWhere(
        (m) => m.key == (betType == 'spread' ? 'spreads' : 'h2h'),
      );
      
      final outcome = market.outcomes.firstWhere(
        (o) => o.name == teamName,
      );

      return SavedPick(
        teamName: teamName,
        opponent: opponent,
        betType: betType == 'spread' ? 'Spread' : 'Moneyline',
        spreadValue: betType == 'spread' ? outcome.point : null,
        odds: outcome.price,
      );
    }).toList();

    final totalOdds = OddsCalculator.calculateParlayOdds(
      picks.map((p) => p.odds).toList(),
    );

    // Show the modal
    showDialog(
      context: context,
      builder: (dialogContext) => SaveParlayModal(
        picks: picks,
        totalOdds: totalOdds,
        onSave: (amount) async {
          final parlay = SavedParlay(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            createdAt: DateTime.now(),
            picks: picks,
            totalOdds: totalOdds,
            amount: amount,
          );

          try {
            await _parlayService.saveParlay(parlay);
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('Parlay saved!')),
              );
            }
            setState(() {
              selectedPicks.clear();
            });
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('Error saving parlay: $e')),
              );
            }
          }
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    
    // Get day of week
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayOfWeek = days[localTime.weekday % 7];
    
    // Get month
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    final month = months[localTime.month - 1];
    
    final day = localTime.day;
    
    // Convert to 12-hour format with AM/PM
    int hour = localTime.hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : hour;
    hour = hour == 0 ? 12 : hour;  // Convert 0 to 12 for midnight
    
    final minute = localTime.minute.toString().padLeft(2, '0');
    
    return '$dayOfWeek, $month $day - $hour:$minute $ampm';
  }

  List<Game> get filteredGames {
    if (searchQuery.isEmpty) return games;
    
    final query = searchQuery.toLowerCase();
    return games.where((game) {
      return game.homeTeam.toLowerCase().contains(query) ||
             game.awayTeam.toLowerCase().contains(query);
    }).toList();
  }

  double _getClosestSnapHeight(double currentHeight) {
    return _snapHeights.reduce((a, b) {
      return (currentHeight - a).abs() < (currentHeight - b).abs() ? a : b;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _cardHeight -= details.delta.dy;
      _cardHeight = _cardHeight.clamp(_minHeight, _maxHeight);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    
    setState(() {
      if (velocity.abs() > 500) {
        // If swiped with high velocity, go to min or max
        _cardHeight = velocity > 0 ? _minHeight : _maxHeight;
      } else {
        // Otherwise snap to closest height
        _cardHeight = _getClosestSnapHeight(_cardHeight);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Big Board'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedParlaysScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search teams...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ),

              // Games List
              Expanded(
                child: isLoading 
                  ? Center(child: CircularProgressIndicator())
                  : games.isEmpty 
                    ? Center(child: Text('No games available'))
                    : RefreshIndicator(
                        onRefresh: _loadMockData,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = filteredGames[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                          child: Text(
                                            _formatTime(game.commenceTime),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        GameMatchup(
                                          game: game,
                                          selectedPicks: selectedPicks,
                                          togglePick: togglePick,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          if (selectedPicks.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  height: _cardHeight,
                  child: ParlayCard(
                    selectedPicks: selectedPicks,
                    games: games,
                    onSave: _saveParlay,
                    onRemovePick: removePick,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
} 
