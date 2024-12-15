import 'package:flutter/material.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/parlays/models/game.dart';
import 'package:big_board/core/utils/load_mock_data.dart';
import 'package:big_board/features/parlays/widgets/game_matchup.dart';
import 'package:big_board/features/parlays/widgets/parlay_card.dart';
import 'package:big_board/features/parlays/services/parlay_service.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/parlays/screens/saved_parlays_screen.dart';
import 'package:big_board/core/utils/odds_calculator.dart';
import 'package:big_board/features/parlays/widgets/save_parlay_modal.dart';
import 'package:big_board/features/profile/screens/profile_screen.dart';
import 'package:big_board/features/auth/screens/sign_in_screen.dart';
import 'package:big_board/features/profile/models/user_profile.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/features/groups/services/groups_service.dart';
import 'package:big_board/features/groups/screens/groups_screen.dart';
import 'package:big_board/features/parlays/widgets/parlay_summary_bar.dart';
import 'package:big_board/features/parlays/widgets/parlay_details_sheet.dart';
import 'package:big_board/features/profile/services/user_profile_service.dart';
import 'package:big_board/features/parlays/models/parlay_invitation.dart';
import 'package:big_board/features/auth/services/auth_service.dart';
import 'package:big_board/features/parlays/models/placeholder_pick.dart';
import 'package:big_board/features/parlays/widgets/group_member_assignments.dart';
import 'package:provider/provider.dart';
import 'package:big_board/features/parlays/state/parlay_state.dart';
import 'package:uuid/uuid.dart';
import 'package:big_board/features/parlays/helpers/pick_helper.dart';

class ParlayScreen extends StatefulWidget {
  const ParlayScreen({Key? key}) : super(key: key);

  @override
  _ParlayScreenState createState() => _ParlayScreenState();
}

class _ParlayScreenState extends State<ParlayScreen> {
  final AuthService _authService = AuthService();
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  late final ScrollController _scrollController;
  final ParlayService _parlayService = ParlayService();
  final UserProfileService _userProfileService = UserProfileService();
  List<Game> games = [];
  final Map<String, String> memberNames = {};
  final Map<String, String> memberPhotos = {};
  String searchQuery = '';
  bool isLoading = false; 
  late UserProfile userProfile;
  List<Group> userGroups = [];
  final GroupsService _groupsService = GroupsService();
  bool _isProcessingToggle = false;
  late final ParlayState _parlayState;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _parlayState = Provider.of<ParlayState>(context, listen: false);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load games, groups, and user profile in parallel
      await Future.wait([
        _loadMockData(),
        _loadUserGroups(),
        _initializeUserProfile(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data')),
        );
      }
    }
  }

  Future<void> _loadUserGroups() async {
    print('\n=== Starting _loadUserGroups in ParlayScreen ===\n');
    if (currentUser != null) {
      print('Current User ID: ${currentUser!.id}');
      final groups = await _groupsService.getUserGroups(currentUser!.id);
      print('Groups returned: $groups');
      if (mounted) {
        setState(() {
          userGroups = groups;
          
          memberPhotos.clear();
          for (var group in groups) {
            for (var member in group.members) {
              print('Processing member: ${member.userId}');
              print('Member Profile: ${member.profile?.toJson()}');
              if (member.profile?.photoURL != null) {
                memberPhotos[member.userId] = member.profile!.photoURL!;
                print('Added photo: ${member.profile!.photoURL}');
              }
            }
          }
          print('Final memberPhotos map: $memberPhotos');
        });
      }
    } else {
      print('No current user found');
    }
  }

  void _subscribeToInvitations() {
    // Don't set up subscription if no user is signed in
    if (currentUser == null) return;

    final channel = Supabase.instance.client.channel('invitations');
    
    channel.subscribe((status, [error]) async {
      if (status == 'SUBSCRIBED') {
        await channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'parlay_invitations',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'recipient_id',
              value: currentUser?.id,
            ),
            callback: (payload) {
              _checkForPendingInvitations();
            },
          );
      }
    });
  }

  void _checkForPendingInvitations() {
    // Implement logic to check for pending invitations
  }

  Future<void> _acceptParlayInvitation(ParlayInvitation invitation) async {
    try {
      await _parlayService.acceptInvitation(invitation.id);
      // Optionally refresh the parlays list or show success message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept invitation: $e')),
      );
    }
  }

  Future<void> _declineParlayInvitation(ParlayInvitation invitation) async {
    try {
      await _parlayService.declineInvitation(invitation.id);
      // Optionally show declined message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline invitation: $e')),
      );
    }
  }

  Future<void> _initializeUserProfile() async {
    final user = currentUser;
    if (user != null) {
      try {
        final profile = await _userProfileService.getProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            userProfile = profile;
          });
        } else {
          throw Exception('Could not load user profile');
        }
      } catch (e) {
        print("Error loading user profile: $e");
        rethrow; // Propagate error to be caught by _loadInitialData
      }
    }
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

    // Update ParlayState with the loaded games
    _parlayState.updateGames(loadedGames);
  }

  void togglePick(String gameId, String team, String betType) {
    final pickId = '$gameId-$betType-$team';
    
    // Check if there's already a pick from this game
    final existingPick = _parlayState.selectedPicks.firstWhere(
      (pick) => pick.split('-')[0] == gameId,
      orElse: () => '',
    );

    if (existingPick.isNotEmpty && existingPick != pickId) {
      // Remove existing pick from this game before adding new one
      _parlayState.removePick(existingPick);
    }
    
    setState(() {
      _parlayState.togglePick(gameId, team, betType);
    });
  }

  void removePick(String pickId) {
    _parlayState.removePick(pickId);
  }

  Future<void> _saveParlay(String? groupId, List<PlaceholderPick> placeholderPicks) async {
    final savedParlay = SavedParlay(
      id: const Uuid().v4(),
      userId: currentUser?.id ?? '',
      groupId: groupId,
      picks: _convertPicksToSavedPicks(_parlayState.selectedPicks).toList(),
      totalOdds: _calculateTotalOdds(),
      units: 10.0,
      createdAt: DateTime.now(),
    );

    try {
      await _parlayService.saveParlay(savedParlay);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving parlay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save parlay: $e')),
        );
      }
    }
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

  void _showParlayDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParlayCard(
        parlayState: _parlayState,
        userGroups: userGroups,
        onSave: () => _saveParlay(null, []),
        memberNames: memberNames,
        memberPhotos: memberPhotos,
        userProfile: userProfile,
      ),
    );
  }

  int _calculateTotalOdds() {
    final List<int> odds = _parlayState.selectedPicks.map((pickId) {
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

  void _handleParlaySave(String? groupId, Map<String, String> assignments) {
    // Create parlay with group ID if present
    // Store member assignments for each pick
    // For unassigned picks (not in assignments map), these will be available 
    // for group members to claim
  }

  List<SavedPick> _convertPicksToSavedPicks(Set<String> picks) {
    return picks.map((pickId) {
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

      return SavedPick(
        teamName: team == 'home' ? game.homeTeam : game.awayTeam,
        opponent: team == 'home' ? game.awayTeam : game.homeTeam,
        betType: betType,
        spreadValue: betType == 'spread' ? outcome.point : null,
        odds: outcome.price,
      );
    }).toList();
  }

  void _removePick(String pickId) {
    setState(() {
      _parlayState.selectedPicks.remove(pickId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParlayState>(
      builder: (context, parlayState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Big Board'),
            actions: [
              IconButton(
                icon: Icon(Icons.group),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupsScreen()),
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
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userProfile: userProfile,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  try {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      // Navigate to SignInScreen and remove all previous routes
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => SignInScreen()),
                        (route) => false,  // This removes all previous routes
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out')),
                      );
                    }
                  }
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
                                              selectedPicks: context.watch<ParlayState>().selectedPicks,
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
            ],
          ),
          bottomNavigationBar: parlayState.selectedPicks.isNotEmpty
            ? ParlaySummaryBar(
                numPicks: parlayState.selectedPicks.length,
                odds: _calculateTotalOdds(),
                onTap: _showParlayDetails,
              )
            : null,
        );
      }
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
} 