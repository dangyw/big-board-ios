import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';
import '../models/placeholder_pick.dart';
import 'package:big_board/core/utils/odds_calculator.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/features/parlays/services/parlay_service.dart';
import 'package:big_board/features/parlays/widgets/member_search_dialog.dart';
import 'package:big_board/features/groups/services/groups_service.dart';
import 'package:big_board/features/groups/widgets/create_group_dialog.dart';
import 'package:flutter/services.dart';

class ParlayDetailsSheet extends StatefulWidget {
  final List<Game> games;
  final List<String> selectedPicks;
  final Function(String) onRemovePick;
  final Function(String?, List<PlaceholderPick>) onSave;
  final List<Group> userGroups;
  final Map<String, String> memberNames;
  final String? parlayId;
  final Map<String, String> memberPhotos;

  const ParlayDetailsSheet({
    Key? key,
    required this.games,
    required this.selectedPicks,
    required this.onRemovePick,
    required this.onSave,
    required this.userGroups,
    required this.memberNames,
    this.parlayId,
    required this.memberPhotos,
  }) : super(key: key);

  @override
  State<ParlayDetailsSheet> createState() => _ParlayDetailsSheetState();
}

class _ParlayDetailsSheetState extends State<ParlayDetailsSheet> {
  final _supabase = Supabase.instance.client;
  final ScrollController scrollController = ScrollController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool isGroupParlay = false;
  String? selectedGroupId;
  Map<String, int> _memberAllocations = {};
  String? selectedMemberId;
  List<PlaceholderPick> placeholderPicks = [];
  final double unitValue = 10.0; // This should come from user settings
  final Map<String, int> pickMemberAllocations = {};

  int get totalOdds {
    final List<int> odds = widget.selectedPicks.map((pickId) {
      final parts = pickId.split('-');
      final game = widget.games.firstWhere((g) => g.id == parts[0]);
      final bookmaker = game.bookmakers.firstWhere(
        (b) => b.key == 'fanduel',
        orElse: () => game.bookmakers.first,
      );
      final market = bookmaker.markets.firstWhere(
        (m) => m.key == (parts[1] == 'spread' ? 'spreads' : 'h2h'),
      );
      final outcome = market.outcomes.firstWhere(
        (o) => o.name == (parts[2] == 'home' ? game.homeTeam : game.awayTeam),
      );
      return outcome.price;
    }).toList();
    
    return OddsCalculator.calculateParlayOdds(odds);
  }

  void _calculateAmount(String units) {
    if (units.isEmpty) {
      _amountController.text = '';
      return;
    }
    final double unitsValue = double.tryParse(units) ?? 0;
    final double amount = unitsValue * unitValue;
    _amountController.text = amount.toStringAsFixed(2);
  }

  void _calculateUnits(String amount) {
    if (amount.isEmpty) {
      _unitsController.text = '';
      return;
    }
    final double amountValue = double.tryParse(amount) ?? 0;
    final double units = amountValue / unitValue;
    _unitsController.text = units.toStringAsFixed(2);
  }

  Widget _buildMemberAllocationSection() {
    if (selectedGroupId == null) return SizedBox.shrink();

    final group = widget.userGroups.firstWhere(
      (g) => g.id == selectedGroupId,
      orElse: () => Group(id: '', name: '', ownerId: '', createdAt: DateTime.now(), members: []),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Assign Picks to Group Members',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...group.members.map((member) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.memberNames[member.id] ?? 'Unknown User'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: _memberAllocations[member.id] == 0 
                        ? null 
                        : () => _updateMemberAllocation(member.id, -1),
                  ),
                  Text('${_memberAllocations[member.id] ?? 0} picks'),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => _updateMemberAllocation(member.id, 1),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
        
        // Show total allocated picks
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Total Picks Requested: ${_getTotalAllocatedPicks()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getTotalAllocatedPicks() > 0 ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  int _getTotalAllocatedPicks() {
    return _memberAllocations.values.fold(0, (sum, picks) => sum + picks);
  }

  void _updateMemberAllocation(String memberId, int delta) {
    setState(() {
      final currentAllocation = _memberAllocations[memberId] ?? 0;
      _memberAllocations[memberId] = currentAllocation + delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet handle
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group toggle at top
                    SwitchListTile(
                      title: Text('Group Parlay'),
                      value: isGroupParlay,
                      onChanged: (value) {
                        setState(() {
                          isGroupParlay = value;
                          if (!value) {
                            selectedGroupId = null;
                            placeholderPicks.clear();
                          }
                        });
                      },
                    ),

                    // Group selection when toggled
                    if (isGroupParlay) ...[
                      Builder(builder: (context) {
                        // Debug prints wrapped in Builder with more context
                        print('Group Parlay toggled ON');
                        print('Available groups: ${widget.userGroups ?? []}');
                        print('Current user ID: ${_supabase.auth.currentUser?.id ?? 'Not logged in'}');
                        return const SizedBox.shrink();
                      }),
                      if (widget.userGroups.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'You need to create a group first',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  // Show dialog to create group
                                  final groupName = await showDialog<String>(
                                    context: context,
                                    builder: (context) => CreateGroupDialog(),
                                  );
                                  
                                  if (groupName != null) {
                                    // Create group and update state
                                    try {
                                      final newGroup = await GroupsService().createGroup(
                                        name: groupName,
                                        ownerId: _supabase.auth.currentUser!.id,
                                      );
                                      
                                      if (newGroup != null) {
                                        setState(() {
                                          selectedGroupId = newGroup.id;
                                        });
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to create group: $e')),
                                      );
                                    }
                                  }
                                },
                                child: Text('Create New Group'),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: DropdownButtonFormField<String>(
                            value: selectedGroupId,
                            decoration: InputDecoration(
                              labelText: 'Select Group',
                              border: OutlineInputBorder(),
                            ),
                            items: widget.userGroups.map((group) => DropdownMenuItem(
                              value: group.id,
                              child: Text(group.name),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGroupId = value;
                                placeholderPicks.clear();
                              });
                            },
                          ),
                        ),
                    ],

                    // Odds, Units, Amount section
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Odds:', 
                                style: TextStyle(fontWeight: FontWeight.bold)
                              ),
                              Text(
                                totalOdds >= 0 ? '+$totalOdds' : '$totalOdds',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _unitsController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Units',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      _calculateAmount(value);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: _calculateUnits,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Current user's picks
                    ...widget.selectedPicks.map((pickId) => _buildPickTile(pickId)),

                    // Add pick button and placeholder picks when group is selected
                    if (isGroupParlay && selectedGroupId != null) ...[
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addPlaceholderPick,
                        icon: Icon(Icons.add),
                        label: Text('Add Pick for Group Member'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                      SizedBox(height: 16),
                      ...placeholderPicks.map((pick) => Column(
                        children: [
                          _buildEmptyPickTile(pick),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: _buildMemberAssignmentDropdown(pick),
                          ),
                        ],
                      )),
                    ],
                  ],
                ),
              ),
            ),

            // Save button
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => widget.onSave(selectedGroupId, placeholderPicks),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Save Parlay'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePotentialPayout() {
    final double units = double.tryParse(_unitsController.text) ?? 0;
    final double amount = units * unitValue;
    if (totalOdds >= 0) {
      return amount * (totalOdds / 100) + amount;
    } else {
      return amount * (100 / -totalOdds) + amount;
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    _unitsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildPickTile(String pickId, {String? assignedMemberId}) {
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
    
    final username = assignedMemberId != null 
        ? widget.memberNames[assignedMemberId] 
        : widget.memberNames[_supabase.auth.currentUser!.id];
    final photoUrl = assignedMemberId != null 
        ? widget.memberPhotos[assignedMemberId] 
        : widget.memberPhotos[_supabase.auth.currentUser!.id];

    return Dismissible(
      key: Key(pickId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onRemovePick(pickId),
      child: Card(
        child: ListTile(
          title: Row(
            children: [
              Text(
                team == 'home' ? game.homeTeam : game.awayTeam,
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Text(
                betType == 'spread' ? 'Spread' : 'Moneyline',
                style: TextStyle(color: Colors.black87),
              ),
              if (outcome.point != null) ...[
                SizedBox(width: 8),
                Text(
                  outcome.point! >= 0 ? '+${outcome.point}' : '${outcome.point}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
              SizedBox(width: 8),
              Text(
                outcome.price >= 0 ? '+${outcome.price}' : '${outcome.price}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Builder(
                builder: (context) {
                  return CircleAvatar(
                    radius: 12,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty 
                        ? NetworkImage(photoUrl) 
                        : null,
                    backgroundColor: photoUrl != null && photoUrl.isNotEmpty 
                        ? Colors.transparent 
                        : _getColorFromUsername(username ?? ''),
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Icon(Icons.person, size: 16, color: Colors.white) 
                        : null,
                  );
                }
              ),
            ],
          ),
          trailing: Icon(Icons.close, color: Colors.red),
        ),
      ),
    );
  }

  // Helper method to generate consistent colors from usernames
  Color _getColorFromUsername(String username) {
    // Generate a consistent hash from the username
    final hash = username.codeUnits.fold(0, (prev, curr) => prev + curr);
    
    // Use the hash to generate HSL color with:
    // - Random hue (0-360)
    // - Fixed saturation (60%)
    // - Fixed lightness (45%) for good contrast
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
  }

  Widget _buildMemberDropdown(String pickId) {
    return DropdownButtonFormField<String?>(
      value: pickMemberAllocations[pickId]?.toString(),
      decoration: InputDecoration(
        labelText: 'Assign to Member',
        border: OutlineInputBorder(),
        hintText: 'Leave unassigned for group to pick',
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('Unassigned (Group to Pick)'),
        ),
        if (selectedGroupId != null)
          ...widget.userGroups
              .firstWhere(
                (g) => g.id == selectedGroupId,
                orElse: () => Group(
                  id: '',
                  name: '',
                  ownerId: '',
                  createdAt: DateTime.now(),
                  members: [],
                ),
              )
              .members
              .map((memberId) => DropdownMenuItem<String?>(
                    value: memberId.id,
                    child: Text(widget.memberNames[memberId.id] ?? 'Unknown User'),
                  ))
              .toList(),
      ],
      onChanged: (String? value) {
        setState(() {
          if (value == null) {
            pickMemberAllocations.remove(pickId);
          } else {
            pickMemberAllocations[pickId] = int.parse(value);
          }
        });
      },
    );
  }

  Widget _buildPicksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your picks section - always shown
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Your Picks', style: Theme.of(context).textTheme.titleMedium),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.selectedPicks.length,
          itemBuilder: (context, index) {
            final pickId = widget.selectedPicks[index];
            final parts = pickId.split('-');
            final game = widget.games.firstWhere((g) => g.id == parts[0]);
            return ListTile(
              title: Text('${parts[2] == 'home' ? game.homeTeam : game.awayTeam}'),
              subtitle: Text('${parts[1].toUpperCase()}'),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => widget.onRemovePick(pickId),
              ),
            );
          },
        ),

        // Group picks section - only shown when group parlay is enabled
        if (selectedGroupId != null) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Group Member Picks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Spacer(),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Member Pick'),
                  onPressed: _addPlaceholderPick,
                ),
              ],
            ),
          ),
          ...placeholderPicks.map((pick) => _buildPlaceholderPickTile(pick)),
        ],
      ],
    );
  }

  Widget _buildPlaceholderPickTile(PlaceholderPick pick) {
    final username = pick.assignedMemberId != null 
        ? widget.memberNames[pick.assignedMemberId!]
        : null;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: username != null 
              ? _getColorFromUsername(username)
              : Colors.grey,
        ),
        title: Text('Empty Pick'),
        subtitle: Text(username ?? 'Unassigned'),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _removePlaceholderPick(pick),
        ),
      ),
    );
  }

  void _addPlaceholderPick() {
    setState(() {
      placeholderPicks.add(PlaceholderPick());
    });
  }

  void _removePlaceholderPick(PlaceholderPick pick) {
    setState(() {
      placeholderPicks.remove(pick);
    });
  }

  void _assignPickToMember(PlaceholderPick pick, String? memberId) {
    setState(() {
      pick.assignedMemberId = memberId;
    });
  }

  Widget _buildInviteButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add),
      label: const Text('Invite Member'),
      onPressed: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => MemberSearchDialog(),
        );
        
        if (result != null) {
          try {
            await ParlayService().inviteToParlay(
              parlayId: widget.parlayId ?? '',
              inviteeId: result,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invitation sent!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send invitation: $e')),
            );
          }
        }
      },
    );
  }

  Widget _buildEmptyPickTile(PlaceholderPick pick) {
    final username = pick.assignedMemberId != null 
        ? widget.memberNames[pick.assignedMemberId!]
        : null;
    final photoUrl = pick.assignedMemberId != null 
        ? widget.memberPhotos[pick.assignedMemberId!]
        : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: photoUrl != null 
                  ? NetworkImage(photoUrl)
                  : null,
              backgroundColor: photoUrl != null 
                  ? Colors.transparent
                  : Colors.grey,
              child: photoUrl == null 
                  ? Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Empty Pick',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => _removePlaceholderPick(pick),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAssignmentDropdown(PlaceholderPick pick) {
    final group = widget.userGroups.firstWhere(
      (g) => g.id == selectedGroupId,
      orElse: () => Group(id: '', name: '', members: [], ownerId: '', createdAt: DateTime.now()),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String?>(
        value: pick.assignedMemberId,
        decoration: InputDecoration(
          labelText: 'Assign to Member',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        items: [
          DropdownMenuItem<String>(
            value: '',
            child: Text('Select a Sport'),
          ),
          ...group.members
              .where((member) => member.id != _supabase.auth.currentUser?.id)
              .map((member) => DropdownMenuItem<String?>(
                    value: member.id,
                    child: Text(widget.memberNames[member.id] ?? 'Unknown User'),
                  )),
        ],
        onChanged: (value) => _assignPickToMember(pick, value),
      ),
    );
  }
}

class PlaceholderPick {
  String? assignedMemberId;
  PlaceholderPick({this.assignedMemberId});
} 