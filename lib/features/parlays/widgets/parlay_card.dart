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
    final totalOdds = widget.parlayState.calculateTotalOdds();
    
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
                            items: widget.userGroups.map((group) => DropdownMenuItem(
                              value: group.id,
                              child: Text(group.name),
                            )).toList(),
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
                            Text(
                              '${parlayState.selectedPicks.length} Team Parlay',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Total Odds: ${totalOdds >= 0 ? "+$totalOdds" : totalOdds}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
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
                            Text(
                              'Return: ${(widget.parlayState.units * (totalOdds/100)).toStringAsFixed(1)} Units',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      
                      // Selected Picks
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: parlayState.selectedPicks.map((pickId) {
                            final details = parlayState.getGameDetails(pickId);
                            final betType = pickId.split('-')[1];
                            final odds = parlayState.getFormattedOdds(pickId);
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.sports_football, color: Colors.indigo),
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
                                    Text(betType == 'spread' 
                                        ? details['details']?.toString().split(' ').last ?? ''
                                        : getMoneylineOdds(pickId)),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () => parlayState.removePick(pickId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
                              Text(
                                'Group Picks',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              ...parlayState.placeholderPicks.map((pick) => Card(
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
                                        items: widget.userGroups
                                            .expand((group) => group.members)
                                            .map((member) => DropdownMenuItem(
                                                  value: member.id,
                                                  child: Text(member.name),
                                                ))
                                            .toList(),
                                        onChanged: (value) =>
                                            parlayState.assignUserToPlaceholder(pick.id, value),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () => parlayState.removePlaceholderPick(pick.id),
                                      ),
                                    ],
                                  ),
                                ),
                              )).toList(),
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
    final pick = PickHelper(pickId);
    final game = widget.parlayState.getGameById(pick.gameId);
    if (game == null) return "0";
    
    final selectedTeam = pick.isHome ? game.homeTeam : game.awayTeam;
    final bookmaker = BettingHelper.getBookmaker(game);
    final market = BettingHelper.getMarket(bookmaker, 'spread');
    final outcome = BettingHelper.getOutcome(market, selectedTeam);
    
    final point = outcome.point ?? 0;
    return point >= 0 ? '+$point' : point.toString();
  }

  String formatOdds(int odds) {
    if (odds >= 0) {
      return '+$odds';
    }
    return odds.toString();
  }

  String getMoneylineOdds(String pickId) {
    final parts = pickId.split('-');
    final gameId = parts[0];
    final team = parts[2];
    final game = widget.parlayState.getGameById(gameId);
    
    if (game == null) return "0";
    
    final bookmaker = game.bookmakers.firstWhere(
      (b) => b.key == 'fanduel',
      orElse: () => game.bookmakers.first,
    );
    
    final moneyline = bookmaker.markets.firstWhere(
      (m) => m.key == 'h2h',
      orElse: () => Market(key: 'h2h', lastUpdate: DateTime.now(), outcomes: []),
    );
    
    final actualTeam = team == 'home' ? game.homeTeam : game.awayTeam;
    
    final outcome = moneyline.outcomes.firstWhere(
      (o) => o.name == actualTeam,
      orElse: () => Outcome(name: '', price: 0, point: 0),
    );
    
    return outcome.price >= 0 ? '+${outcome.price}' : '${outcome.price}';
  }
}

