import 'package:flutter/material.dart';
import 'package:big_board/features/parlays/models/game.dart';
import 'package:big_board/features/parlays/helpers/betting_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:big_board/core/services/espn_service.dart';
import 'package:big_board/core/utils/odds_calculator.dart';

class GameMatchup extends StatefulWidget {
  final Game game;
  final Set<String> selectedPicks;
  final Function(String, String, String) togglePick;

  const GameMatchup({
    super.key,
    required this.game,
    required this.selectedPicks,
    required this.togglePick,
  });

  @override
  State<GameMatchup> createState() => _GameMatchupState();
}

class _GameMatchupState extends State<GameMatchup> {
  late final Map<String, Market> markets;
  late final Market? spreadsMarket;
  late final Market? moneylineMarket;

  @override
  void initState() {
    super.initState();
    markets = _findMarkets();
    spreadsMarket = markets['spreads'];
    moneylineMarket = markets['h2h'];
  }

  Map<String, Market> _findMarkets() {
    debugPrint('\n=== GameMatchup Markets ===');
    debugPrint('Game: ${widget.game.awayTeam} vs ${widget.game.homeTeam}');
    debugPrint('Available markets:');
    for (var bookmaker in widget.game.bookmakers) {
      for (var market in bookmaker.markets) {
        debugPrint('  ${market.key}:');
        for (var outcome in market.outcomes) {
          debugPrint('    ${outcome.name}: ${outcome.price} (point: ${outcome.point})');
        }
      }
    }

    final Map<String, Market> foundMarkets = {};
    
    if (widget.game.bookmakers.isNotEmpty) {
      final bookmaker = widget.game.bookmakers.first;
      for (var market in bookmaker.markets) {
        if (market.outcomes.length == 2) {
          foundMarkets[market.key] = market;
        }
      }
    }

    debugPrint('\nFound markets:');
    foundMarkets.forEach((key, market) {
      debugPrint('${market.key}: ${market.key} with ${market.outcomes.length} outcomes');
    });
    debugPrint('========================');

    return foundMarkets;
  }

  bool isSelected(String team, String betType) {
    final pickId = '${widget.game.id}_${team}_${betType}';
    return widget.selectedPicks.contains(pickId);
  }

  Widget _buildBettingOption({
    required String label,
    required String odds,
    required bool isSelected,
    required VoidCallback onPress,
    bool centered = false,
  }) {
    print('\n=== Building Betting Option ===');
    print('Label: $label');
    print('Odds: $odds');
    print('Is Selected: $isSelected');
    print('========================\n');
    
    final formattedLabel = label;

    return GestureDetector(
      onTap: () {
        print('Betting option tapped');  // Debug 
        onPress();
      },
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

  Widget _buildTeamLogo(String teamName) {
    final url = EspnService.getTeamLogoUrl(teamName);
    
    return CachedNetworkImage(
      imageUrl: url,  // Use the url variable
      width: 30,
      height: 30,
      placeholder: (context, url) => SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey[400],
        ),
      ),
      errorWidget: (context, url, error) => Icon(
        Icons.sports_football,
        size: 30,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildOdds(Outcome outcome) {
    return Text(OddsCalculator.formatOdds(outcome.price));
  }

  Widget _buildSpread(Outcome outcome) {
    final point = outcome.point ?? 0;
    final formattedPoint = point > 0 ? '+$point' : point.toString();
    return Text('$formattedPoint (${OddsCalculator.formatOdds(outcome.price)})');
  }

  void _onSpreadTap(String team) {
    widget.togglePick(widget.game.id, team, 'spread');
  }

  void _onMoneylineTap(String team) {
    widget.togglePick(widget.game.id, team, 'moneyline');
  }

  Outcome _getOddsForPick(String gameId, String outcomeId, String betType) {
    print('\n=== Getting Odds for Pick ===');
    print('Game ID: $gameId');
    print('Outcome ID: $outcomeId');
    print('Bet Type: $betType');

    // Get the game data
    print('Game: ${widget.game.awayTeam} vs ${widget.game.homeTeam}');

    // Get available bookmakers
    final bookmakers = widget.game.bookmakers;
    print('Available bookmakers: ${bookmakers.map((b) => b.key).join(', ')}');

    // Use first available bookmaker (usually FanDuel)
    final bookmaker = bookmakers.first;
    print('Using bookmaker: ${bookmaker.key}');

    // Select market based on bet type
    final marketKey = betType == 'spread' ? 'spreads' : 'h2h';
    final market = bookmaker.markets.firstWhere((m) => m.key == marketKey);
    print('Market: ${market.key}');

    // Get available outcomes
    print('Available outcomes: ${market.outcomes.map((o) => '${o.name}: ${o.price}${o.point != null ? ' (point: ${o.point})' : ''}').join(', ')}');

    // Find the selected outcome
    final outcome = market.outcomes.firstWhere((o) => 
      (outcomeId == 'away' && o.name == widget.game.awayTeam) ||
      (outcomeId == 'home' && o.name == widget.game.homeTeam)
    );

    print('Selected outcome: ${outcome.name} @ ${outcome.price}');
    print('===========================');

    return outcome;
  }

  @override
  Widget build(BuildContext context) {
    String getFormattedOdds(String team, String betType) {
      final bookmaker = BettingHelper.getBookmaker(widget.game);
      final market = BettingHelper.getMarket(bookmaker, betType);
      final outcome = BettingHelper.getOutcome(market, team);
      return OddsCalculator.formatOdds(outcome.price);
    }

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
                  child: Row(
                    children: [
                      _buildTeamLogo(widget.game.awayTeam),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.game.awayTeam,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: BettingHelper.getSpreadValue(widget.game, widget.game.awayTeam),
                      odds: getFormattedOdds(widget.game.awayTeam, 'spread'),
                      isSelected: isSelected('away', 'spread'),
                      onPress: () => _onSpreadTap('away'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: '',
                      odds: getFormattedOdds(widget.game.awayTeam, 'h2h'),
                      isSelected: isSelected('away', 'moneyline'),
                      onPress: () => _onMoneylineTap('away'),
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
                  child: Row(
                    children: [
                      _buildTeamLogo(widget.game.homeTeam),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.game.homeTeam,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: BettingHelper.getSpreadValue(widget.game, widget.game.homeTeam),
                      odds: getFormattedOdds(widget.game.homeTeam, 'spread'),
                      isSelected: isSelected('home', 'spread'),
                      onPress: () => _onSpreadTap('home'),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildBettingOption(
                      label: '',
                      odds: getFormattedOdds(widget.game.homeTeam, 'h2h'),
                      isSelected: isSelected('home', 'moneyline'),
                      onPress: () => _onMoneylineTap('home'),
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