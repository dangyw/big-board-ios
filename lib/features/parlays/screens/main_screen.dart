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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  final ScrollController _scrollController = ScrollController();
  final ParlayService _parlayService = ParlayService();
  final UserProfileService _userProfileService = UserProfileService();
  List<Game> games = [];
  String searchQuery = '';
  bool isLoading = false;
  Set<String> selectedPicks = {};
  late UserProfile userProfile;
  List<Group> userGroups = [];
  final GroupsService _groupsService = GroupsService();

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _loadUserGroups();
    _initializeUserProfile();
    
    // Only subscribe if user is already signed in
    if (currentUser != null) {
      _subscribeToInvitations();
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
        print("Debug - Profile loaded: $profile"); // Debug line
        print("Debug - Photo URL: ${profile?.photoURL}"); // Debug line
        if (profile != null) {
          setState(() {
            userProfile = profile;
          });
        }
      } catch (e) {
        print("Error loading user profile: $e");
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
  }

  Future<void> _loadUserGroups() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      print('Loading groups for user: $userId'); // Debug print
      
      if (userId == null) return;
      
      final groups = await _groupsService.getUserGroups(userId);
      print('Loaded groups: ${groups.length}'); // Debug print
      print('Group details: $groups'); // Debug print
      
      setState(() {
        userGroups = groups;
      });
    } catch (e) {
      print('Error loading groups: $e');
    }
  }

  void togglePick(String gameId, String team, String betType) {
    final pickId = '$gameId-$team-$betType';
    
    setState(() {
      if (selectedPicks.contains(pickId)) {
        selectedPicks.remove(pickId);
      } else {
        // Remove any existing picks for this game before adding the new one
        selectedPicks.removeWhere((pick) => pick.startsWith('$gameId-'));
        selectedPicks.add(pickId);
      }
    });
  }

  void removePick(String pickId) {
    setState(() {
      selectedPicks.remove(pickId);
    });
    
    // If no picks left, close the bottom sheet
    if (selectedPicks.isEmpty && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveParlay(String? groupId, List<PlaceholderPick> placeholderPicks) async {
    try {
      if (groupId != null) {
        // Convert placeholder picks to a more structured format
        final memberPicks = <String, List<String>>{};
        for (final pick in placeholderPicks) {
          if (pick.assignedMemberId != null) {
            memberPicks.putIfAbsent(pick.assignedMemberId!, () => []).add('placeholder');
          }
        }

        final parlay = {
          'creator_id': userProfile.id,
          'group_id': groupId,
          'status': 'pending',
          'my_picks': selectedPicks,
          'member_picks': memberPicks,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        print('Saving group parlay: $parlay');
        
        // Notify members they need to add picks
        for (final memberId in memberPicks.keys) {
          final numPicks = memberPicks[memberId]?.length ?? 0;
          print('Notifying $memberId to add $numPicks picks');
        }
      } else {
        // Save as individual parlay
        print('Saving individual parlay');
      }
    } catch (e) {
      print('Error saving parlay: $e');
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

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      bottomNavigationBar: selectedPicks.isNotEmpty
        ? ParlaySummaryBar(
            numPicks: selectedPicks.length,
            odds: _calculateTotalOdds(),
            onTap: _showParlayDetails,
          )
        : null,
    );
  }

  void _showParlayDetails() async {
    try {
      // Only get members from the user's active groups
      final Set<String> memberIds = userGroups
          .expand((group) => group.memberIds)
          .where((id) => id != currentUser?.id)  // Optionally exclude current user
          .toSet();
      
      if (memberIds.isEmpty) {
        // If no group members, show the sheet with empty maps
        _showParlayDetailsSheet({}, {});
        return;
      }

      // Fetch profiles in parallel, but only for group members
      final profiles = await Future.wait(
        memberIds.map((id) => _userProfileService.getProfile(id))
      );
      
      // Build the maps only for valid profiles
      final Map<String, String> memberNames = {};
      final Map<String, String> memberPhotos = {};
      
      for (final profile in profiles) {
        if (profile != null) {
          memberNames[profile.id] = profile.username ?? 'Unknown User';
          memberPhotos[profile.id] = profile.photoURL ?? '';
        }
      }

      if (!mounted) return;
      _showParlayDetailsSheet(memberNames, memberPhotos);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading member profiles: $e')),
      );
    }
  }

  // Separated the sheet display logic for cleaner code
  void _showParlayDetailsSheet(
    Map<String, String> memberNames,
    Map<String, String> memberPhotos,
  ) {
    // Add current user's info to the maps if not already present
    if (currentUser != null) {
      memberNames.putIfAbsent(currentUser!.id, () => userProfile.username ?? 'Me');
      memberPhotos.putIfAbsent(currentUser!.id, () => userProfile.photoURL ?? '');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ParlayDetailsSheet(
          games: games,
          selectedPicks: selectedPicks.toList(),
          onRemovePick: (pickId) => togglePick(
            pickId.split('-')[0],
            pickId.split('-')[1],
            pickId.split('-')[2],
          ),
          onSave: _saveParlay,
          userGroups: userGroups,
          memberNames: memberNames,
          memberPhotos: memberPhotos,
        ),
      ),
    );
  }

  int _calculateTotalOdds() {
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

  void _handleParlaySave(String? groupId, Map<String, String> assignments) {
    // Create parlay with group ID if present
    // Store member assignments for each pick
    // For unassigned picks (not in assignments map), these will be available 
    // for group members to claim
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
} 
