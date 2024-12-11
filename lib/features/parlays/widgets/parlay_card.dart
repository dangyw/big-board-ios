import 'package:flutter/material.dart';
import '../models/game.dart';
import 'package:big_board/core/utils/odds_calculator.dart';
import 'package:big_board/features/groups/models/group.dart';

class ParlayCard extends StatefulWidget {
  final Set<String> selectedPicks;
  final List<Game> games;
  final Function({String? groupId}) onSave;
  final Function(String) onRemovePick;
  final List<Group> userGroups;

  const ParlayCard({
    Key? key,
    required this.selectedPicks,
    required this.games,
    required this.onSave,
    required this.onRemovePick,
    this.userGroups = const [],
  }) : super(key: key);

  @override
  State<ParlayCard> createState() => _ParlayCardState();
}

class _ParlayCardState extends State<ParlayCard> {
  bool isGroupParlay = false;
  String? selectedGroupId;
  final TextEditingController _amountController = TextEditingController();

  int _getParlayOdds() {
    final List<int> odds = widget.selectedPicks.map((pickId) {
      final parts = pickId.split('-');
      final gameId = parts[0];
      final betType = parts[1];
      final team = parts[2];
      
      final game = widget.games.firstWhere((g) => g.id == gameId);
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
    final game = widget.games.firstWhere((g) => g.id == gameId);
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
    final game = widget.games.firstWhere((g) => g.id == gameId);
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
    if (widget.selectedPicks.isEmpty) return SizedBox.shrink();

    final parlayOdds = _getParlayOdds();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
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
          
          // Header with Title and Odds
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parlay (${widget.selectedPicks.length} picks)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Odds: ${OddsCalculator.formatOdds(parlayOdds)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // List of Picks
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.selectedPicks.length,
              separatorBuilder: (context, index) => Divider(
                height: 24,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final pickId = widget.selectedPicks.elementAt(index);
                final parts = pickId.split('-');
                final gameId = parts[0];
                final betType = parts[1];
                final team = parts[2];
                
                final game = widget.games.firstWhere((g) => g.id == gameId);
                final teamName = team == 'home' ? game.homeTeam : game.awayTeam;
                
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamName,
                            style: TextStyle(
                              fontSize: 18,
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
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                betType == 'spread' 
                                  ? '${_getSpreadValue(gameId, team)} (${_getOddsValue(gameId, betType, team)})' 
                                  : _getOddsValue(gameId, betType, team),
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _getOpponent(game, team),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => widget.onRemovePick(pickId),
                    ),
                  ],
                );
              },
            ),
          ),

          // Save Button
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isGroupParlay && selectedGroupId == null 
                  ? null
                  : () => widget.onSave(
                      groupId: isGroupParlay ? selectedGroupId : null,
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE6D4F3),
                  foregroundColor: Colors.purple[900],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Parlay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Group Toggle section
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Personal',
                  style: TextStyle(
                    color: !isGroupParlay ? Colors.purple[900] : Colors.grey[600],
                    fontWeight: !isGroupParlay ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 12),
                Switch(
                  value: isGroupParlay,
                  activeColor: Colors.purple[900],
                  onChanged: (value) {
                    setState(() {
                      isGroupParlay = value;
                      if (!value) selectedGroupId = null;
                    });
                  },
                ),
                SizedBox(width: 12),
                Text(
                  'Group',
                  style: TextStyle(
                    color: isGroupParlay ? Colors.purple[900] : Colors.grey[600],
                    fontWeight: isGroupParlay ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}