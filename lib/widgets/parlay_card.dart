import 'package:flutter/material.dart';
import '../models/game.dart';
import '../utils/odds_calculator.dart';

class ParlayCard extends StatelessWidget {
  final Set<String> selectedPicks;
  final List<Game> games;
  final Function() onSave;
  final Function(String) onRemovePick;

  const ParlayCard({
    Key? key,
    required this.selectedPicks,
    required this.games,
    required this.onSave,
    required this.onRemovePick,
  }) : super(key: key);

  int _getParlayOdds() {
    final List<int> odds = selectedPicks.map((pickId) {
      final parts = pickId.split('-');
      final gameId = parts[0];
      final betType = parts[1];
      final team = parts[2];
      
      final game = games.firstWhere((g) => g.id == gameId);
      final bookmaker = game.bookmakers.firstWhere(
        (b) => b.key == 'fanduel',
        orElse: () => game.bookmakers.first,
      );
      
      final market = bookmaker.markets.firstWhere(
        (m) => m.key == (betType == 'spread' ? 'spreads' : 'h2h'),
      );
      
      final outcome = market.outcomes.firstWhere(
        (o) => o.name == (team == 'home' ? game.homeTeam : game.awayTeam),
      );
      
      return outcome.price;
    }).toList();
    
    return OddsCalculator.calculateParlayOdds(odds);
  }

  String _getSpreadValue(String gameId, String team) {
    final game = games.firstWhere((g) => g.id == gameId);
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final spreads = bookmaker.markets.firstWhere(
      (m) => m.key == 'spreads',
    );
    
    final outcome = spreads.outcomes.firstWhere(
      (o) => o.name == (team == 'home' ? game.homeTeam : game.awayTeam),
    );
    
    return outcome.point! > 0 ? '+${outcome.point}' : '${outcome.point}';
  }

  String _getOddsValue(String gameId, String betType, String team) {
    final game = games.firstWhere((g) => g.id == gameId);
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final market = bookmaker.markets.firstWhere(
      (m) => m.key == (betType == 'spread' ? 'spreads' : 'h2h'),
    );
    
    final outcome = market.outcomes.firstWhere(
      (o) => o.name == (team == 'home' ? game.homeTeam : game.awayTeam),
    );
    
    return outcome.price > 0 ? '+${outcome.price}' : '${outcome.price}';
  }

  String _getOpponent(Game game, String team) {
    return 'vs ${team == 'home' ? game.awayTeam : game.homeTeam}';
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPicks.isEmpty) return SizedBox.shrink();

    final parlayOdds = _getParlayOdds();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            width: double.infinity,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // Header with Title and Save Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parlay (${selectedPicks.length} picks)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Odds: ${OddsCalculator.formatOdds(parlayOdds)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                    foregroundColor: Colors.purple[900],
                  ),
                  child: Text('Save Parlay'),
                ),
              ],
            ),
          ),

          // List of Picks
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: selectedPicks.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final pickId = selectedPicks.elementAt(index);
                final parts = pickId.split('-');
                final gameId = parts[0];
                final betType = parts[1];
                final team = parts[2];
                
                final game = games.firstWhere((g) => g.id == gameId);
                final teamName = team == 'home' ? game.homeTeam : game.awayTeam;
                
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teamName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  betType == 'spread' ? 'Spread' : 'Moneyline',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  betType == 'spread' 
                                    ? '${_getSpreadValue(gameId, team)} (${_getOddsValue(gameId, betType, team)})' 
                                    : _getOddsValue(gameId, betType, team),
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _getOpponent(game, team),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => onRemovePick(pickId),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}