import 'package:flutter/material.dart';
import '../models/game.dart';

class GameMatchup extends StatelessWidget {
  final Game game;
  final Set<String> selectedPicks;
  final Function(String, String, String) togglePick;

  const GameMatchup({
    Key? key,
    required this.game,
    required this.selectedPicks,
    required this.togglePick,
  }) : super(key: key);

  Widget _buildBettingOption({
    required String label,
    required String odds,
    required bool isSelected,
    required VoidCallback onPress,
    bool centered = false,
  }) {
    final formattedLabel = label.isNotEmpty 
        ? (double.parse(label) > 0 ? '+$label' : label)
        : label;

    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: 100,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (formattedLabel.isNotEmpty)
              Text(
                formattedLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            Text(
              odds,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                fontWeight: centered ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get FanDuel odds for now
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );

    final spreads = bookmaker.markets.firstWhere(
      (m) => m.key == 'spreads',
      orElse: () => Market(key: 'spreads', lastUpdate: DateTime.now(), outcomes: []),
    );

    final moneyline = bookmaker.markets.firstWhere(
      (m) => m.key == 'h2h',
      orElse: () => Market(key: 'h2h', lastUpdate: DateTime.now(), outcomes: []),
    );

    String formatOdds(int? price) => 
        price == null ? '--' : (price > 0 ? '+$price' : '$price');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Spread',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Moneyline',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Away Team Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    game.awayTeam,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: spreads.outcomes
                          .firstWhere(
                            (o) => o.name == game.awayTeam,
                            orElse: () => Outcome(name: game.awayTeam, price: 0, point: 0),
                          )
                          .point
                          ?.toString() ?? '',
                      odds: formatOdds(spreads.outcomes
                          .firstWhere(
                            (o) => o.name == game.awayTeam,
                            orElse: () => Outcome(name: game.awayTeam, price: 0),
                          )
                          .price),
                      isSelected: selectedPicks.contains('${game.id}-spread-away'),
                      onPress: () => togglePick(game.id, 'spread', 'away'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: '',
                      odds: formatOdds(moneyline.outcomes
                          .firstWhere(
                            (o) => o.name == game.awayTeam,
                            orElse: () => Outcome(name: game.awayTeam, price: 0),
                          )
                          .price),
                      isSelected: selectedPicks.contains('${game.id}-moneyline-away'),
                      onPress: () => togglePick(game.id, 'moneyline', 'away'),
                      centered: true,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Home Team Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    game.homeTeam,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: spreads.outcomes
                          .firstWhere(
                            (o) => o.name == game.homeTeam,
                            orElse: () => Outcome(name: game.homeTeam, price: 0, point: 0),
                          )
                          .point
                          ?.toString() ?? '',
                      odds: formatOdds(spreads.outcomes
                          .firstWhere(
                            (o) => o.name == game.homeTeam,
                            orElse: () => Outcome(name: game.homeTeam, price: 0),
                          )
                          .price),
                      isSelected: selectedPicks.contains('${game.id}-spread-home'),
                      onPress: () => togglePick(game.id, 'spread', 'home'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: '',
                      odds: formatOdds(moneyline.outcomes
                          .firstWhere(
                            (o) => o.name == game.homeTeam,
                            orElse: () => Outcome(name: game.homeTeam, price: 0),
                          )
                          .price),
                      isSelected: selectedPicks.contains('${game.id}-moneyline-home'),
                      onPress: () => togglePick(game.id, 'moneyline', 'home'),
                      centered: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 