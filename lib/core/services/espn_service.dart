import 'package:big_board/core/constants/team_ids.dart';

class EspnService {
  static String getTeamLogoUrl(String teamName) {
    // Get the team ID from our mapping
    final teamId = TeamIds.ncaaFootball[teamName];
    if (teamId == null) {
      return ''; // Or return a default logo URL
    }
    
    final url = 'https://a.espncdn.com/i/teamlogos/ncaa/500/$teamId.png';
    return url;
  }
} 