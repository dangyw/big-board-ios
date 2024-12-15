import 'dart:convert';
import 'dart:io';

void main() {
  // Read the JSON file
  final file = File('assets/mock_data.json');
  final jsonString = file.readAsStringSync();
  final jsonData = json.decode(jsonString) as List;

  // Set to store unique team names
  final Set<String> teamNames = {};

  // Extract team names from both home_team and away_team fields
  for (var game in jsonData) {
    teamNames.add(game['home_team'] as String);
    teamNames.add(game['away_team'] as String);
  }

  final sortedNames = teamNames.toList()..sort();
  for (var name in sortedNames) {
  }
}