import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:big_board/features/parlays/state/parlay_state.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/features/parlays/services/parlay_service.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/parlays/models/game.dart';
import 'package:big_board/features/profile/models/user_profile.dart';
import 'package:big_board/features/parlays/helpers/pick_helper.dart';
import 'package:big_board/features/parlays/helpers/betting_helper.dart';
import 'package:big_board/core/utils/odds_calculator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:big_board/core/services/espn_service.dart';

class ParlayCard extends StatefulWidget {
  final ParlayState parlayState;
  final List<Group> userGroups;
  final VoidCallback onSave;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotos;
  final UserProfile userProfile;

  const ParlayCard({
    Key? key,
    required this.parlayState,
    required this.userGroups,
    required this.onSave,
    required this.memberNames,
    required this.memberPhotos,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ParlayCard> createState() => _ParlayCardState();
}

class _ParlayCardState extends State<ParlayCard> {
  late TextEditingController _unitsController;

  @override
  void initState() {
    super.initState();
    _unitsController = TextEditingController(text: widget.parlayState.units.toString());
  }

  @override
  void dispose() {
    _unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decimalOdds = widget.parlayState.selectedPicks.isEmpty 
      ? 1.0 
      : widget.parlayState.calculateTotalOdds();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<ParlayState>(
              builder: (context, parlayState, child) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Group Toggle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SwitchListTile(
                          title: Text('Group Parlay Mode'),
                          value: parlayState.isGroupMode,
                          onChanged: (value) => parlayState.setGroupMode(value),
                        ),
                      ),
                      Divider(),

                      // Group Dropdown (when in group mode)
                      if (parlayState.isGroupMode) ...[
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Group',
                              border: OutlineInputBorder(),
                            ),
                            value: parlayState.selectedGroupId,
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Select a Group'),
                              ),
                              ...widget.userGroups.map((group) => DropdownMenuItem(
                                value: group.id,
                                child: Text(group.name),
                              )).toList(),
                            ],
                            onChanged: (value) => parlayState.setSelectedGroup(value),
                          ),
                        ),
                        Divider(),
                      ],

                      // Parlay Summary
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Status Icon
                                if (parlayState.isGroupMode)
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Stack(
                                      children: [
                                        CircularProgressIndicator(
                                          value: parlayState.selectedPicks.length / 
                                                (parlayState.selectedPicks.length + parlayState.placeholderPicks.length),
                                          backgroundColor: Colors.orange.withOpacity(0.3),
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          strokeWidth: 6,  // Make it thicker for donut appearance
                                          strokeCap: StrokeCap.round,  // Rounds the ends of the progress
                                        ),
                                        if (parlayState.placeholderPicks.isEmpty)
                                          Positioned.fill(
                                            child: Center(
                                              child: Container(
                                                width: 12,  // Smaller checkmark
                                                height: 12,
                                                child: Icon(
                                                  Icons.check,
                                                  size: 10,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                SizedBox(width: 8),
                                // Title
                                Text(
                                  '${parlayState.selectedPicks.length + parlayState.placeholderPicks.length} Leg Parlay',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                // Pending Count
                                if (parlayState.isGroupMode && parlayState.placeholderPicks.isNotEmpty)
                                  Text(
                                    ' (${parlayState.placeholderPicks.length} Pending)',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            // Odds
                            Consumer<ParlayState>(
                              builder: (context, state, _) {
                                final decimalOdds = state.selectedPicks.isEmpty 
                                  ? 1.0 
                                  : state.calculateTotalOdds();
                                
                                // Debug prints
                                print('\n=== Parlay Odds Calculation ===');
                                for (final pickId in state.selectedPicks) {
                                  final odds = state.getOddsForPick(pickId);
                                  print('Pick: $pickId');
                                  print('Decimal odds: $odds');
                                  print('American odds: ${OddsCalculator.formatOdds(odds)}');
                                }
                                print('Total decimal odds: $decimalOdds');
                                print('Total American odds: ${OddsCalculator.formatOdds(decimalOdds)}');
                                print('===========================\n');

                                return Text(
                                  'Total Odds: ${OddsCalculator.formatOdds(decimalOdds)}',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Units Input
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Units',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                controller: _unitsController,
                                onChanged: (value) {
                                  final units = double.tryParse(value);
                                  if (units != null) widget.parlayState.setUnits(units);
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Consumer<ParlayState>(
                              builder: (context, state, _) {
                                final decimalOdds = state.selectedPicks.isEmpty 
                                  ? 1.0 
                                  : state.calculateTotalOdds();
                                final returnAmount = state.units * decimalOdds;
                                
                                return Text(
                                  'Return: ${returnAmount.toStringAsFixed(2)} Units',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Selected Picks
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Picks',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            ...parlayState.selectedPicks.map((pickId) {
                              // Update parsing to handle new format: gameId_team_betType
                              final parts = pickId.split('_');
                              final gameId = parts[0];
                              final team = parts[1];  // 'home' or 'away'
                              final betType = parts[2];  // 'spread' or 'moneyline'
                              
                              final game = parlayState.getGameById(gameId);
                              if (game == null) {
                                return SizedBox.shrink();
                              }
                              
                              final details = parlayState.getGameDetails(pickId);
                              
                              return Card(
                                key: ValueKey(pickId),
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: _buildTeamLogo(details['team'] ?? ''),
                                  ),
                                  title: Text(details['team'] ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${betType[0].toUpperCase()}${betType.substring(1)} vs ${details['opponent']}'),
                                      if (betType == 'spread') ...[
                                        Text(
                                          getSpreadDisplay(pickId),
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: widget.userProfile.photoURL != null 
                                            ? NetworkImage(widget.userProfile.photoURL!)
                                            : null,
                                        child: widget.userProfile.photoURL == null 
                                            ? Icon(Icons.person_outline, size: 20, color: Colors.indigo)
                                            : null,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        betType == 'spread' 
                                            ? getSpreadDisplay(pickId)
                                            : getMoneylineOdds(pickId)
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () => parlayState.removePick(pickId),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Group Mode Placeholder Picks
                      if (parlayState.isGroupMode) ...[
                        Divider(),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(builder: (context) {
                                return SizedBox.shrink();
                              }),
                              Text(
                                'Group Picks',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              ...parlayState.placeholderPicks.map((pick) {
                                
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: pick.assignedUserId != null && widget.memberPhotos[pick.assignedUserId] != null
                                          ? NetworkImage(widget.memberPhotos[pick.assignedUserId]!)
                                          : null,
                                      child: (pick.assignedUserId == null || widget.memberPhotos[pick.assignedUserId] == null)
                                          ? Icon(Icons.person_outline, color: Colors.indigo)
                                          : null,
                                    ),
                                    title: Text('Group Pick'),
                                    subtitle: Text('Assign to group member'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButton<String>(
                                          hint: Text('Select User'),
                                          value: pick.assignedUserId,
                                          items: [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Text('Select User'),
                                            ),
                                            ...widget.userGroups
                                                .expand((group) => group.members)
                                                .map((member) => DropdownMenuItem(
                                                      value: member.userId,
                                                      child: Text(widget.memberNames[member.userId] ?? 'Unknown User'),
                                                    ))
                                                .toList(),
                                          ],
                                          onChanged: (value) => parlayState.assignUserToPlaceholder(pick.id, value),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () => parlayState.removePlaceholderPick(pick.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              TextButton.icon(
                                icon: Icon(Icons.add),
                                label: Text('Add Group Pick'),
                                onPressed: () => parlayState.addPlaceholderPick(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Save Button
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: widget.onSave,
                          child: Text('Save Parlay'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String getSpreadDisplay(String pickId) {
    try {
      final pick = PickHelper(pickId);
      final game = widget.parlayState.getGameById(pick.gameId);
      if (game == null) return "0";
      
      final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
      final bookmaker = BettingHelper.getBookmaker(game);
      final market = BettingHelper.getMarket(bookmaker, 'spread');
      final outcome = BettingHelper.getOutcome(market, selectedTeam);
      
      return OddsCalculator.formatOdds(outcome.price);
    } catch (e) {
      return "0";
    }
  }

  String getMoneylineOdds(String pickId) {
    final game = widget.parlayState.getGameById(pickId.split('_')[0]);
    if (game == null) return "0";

    try {
      final pick = PickHelper(pickId);
      final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
      final bookmaker = BettingHelper.getBookmaker(game);
      final market = BettingHelper.getMarket(bookmaker, 'h2h');
      final outcome = BettingHelper.getOutcome(market, selectedTeam);
      
      return OddsCalculator.formatOdds(outcome.price);
    } catch (e) {
      return "PK";
    }
  }

  Widget _buildTeamLogo(String teamName) {
    final url = EspnService.getTeamLogoUrl(teamName);
    
    return CachedNetworkImage(
      imageUrl: url,
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
}

