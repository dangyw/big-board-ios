import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:big_board/features/parlays/models/game.dart';

class OddsService {
  static const String baseUrl = 'https://api.the-odds-api.com/v4/sports';
  static const String sport = 'americanfootball_ncaaf';
  
  static String get apiKey => dotenv.env['ODDS_API_KEY'] ?? '';
  
  static const cacheDuration = Duration(hours: 4);
  
  static final refreshWindows = [
    '06:00',
    '09:30',
    '14:00',
    '18:00',
  ];

  final _storage = GetStorage();
  static const _cacheKey = 'cached_odds_data';

  List<Game> _parseApiResponse(String responseBody) {
    try {
      final List<dynamic> data = json.decode(responseBody);
      return data.where((gameData) => 
        gameData != null && 
        (gameData['bookmakers'] as List).isNotEmpty
      ).map((gameData) {
        // Ensure date is in ISO format
        if (gameData['commence_time'] != null) {
          try {
            DateTime.parse(gameData['commence_time']);
          } catch (e) {
            // If parsing fails, convert to ISO format
            gameData['commence_time'] = DateTime.parse(
              gameData['commence_time'].toString().replaceAll(' ', 'T')
            ).toIso8601String();
          }
        }

        return Game.fromJson(gameData);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Game>> getGames() async {
    try {
      // First check cache
      if (await _hasFreshCache()) {
        return await _loadFromCache();
      }

      // Fetch new data
      return await _fetchFromApi();
    } catch (e) {
      return [];
    }
  }

  Future<bool> _hasFreshCache() async {
    try {
      final lastUpdateStr = _storage.read('last_odds_update');
      if (lastUpdateStr == null) return false;

      final lastUpdate = DateTime.parse(lastUpdateStr);
      
      // Check if we're in a refresh window
      if (_isInRefreshWindow()) {
        return false;  // Force refresh during window
      }
      
      // Otherwise use cache duration
      return DateTime.now().difference(lastUpdate) < cacheDuration;
    } catch (e) {
      return false;
    }
  }

  Future<List<Game>> _loadFromCache() async {
    try {
      final cached = _storage.read(_cacheKey);
      if (cached == null) return [];

      final data = json.decode(cached) as List;
      return data.map((game) => Game.fromJson(game)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Game>> _fetchFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$sport/odds?apiKey=$apiKey&regions=us&markets=spreads,h2h&bookmakers=fanduel'),
      );

      if (response.statusCode == 200) {
        final games = _parseApiResponse(response.body);
        if (games.isNotEmpty) {
          await _saveToCache(games);
        }
        return games;
      } else {
        return await _loadFromCache();
      }
    } catch (e) {
      return await _loadFromCache();
    }
  }

  Future<void> _saveToCache(List<Game> games) async {
    try {
      await _storage.write(_cacheKey, json.encode(games.map((g) => g.toJson()).toList()));
      await _storage.write('last_odds_update', DateTime.now().toIso8601String());
    } catch (e) {
    }
  }

  bool _isInRefreshWindow() {
    final now = DateTime.now().toLocal();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return refreshWindows.contains(currentTime);
  }

  Future<void> testApiConnection() async {
    try {
      if (apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$sport/odds?apiKey=$apiKey&regions=us&markets=spreads,h2h'),
      );
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        
        final data = json.decode(responseBody) as List;
        if (data.isEmpty) {
          return;
        }
        
        final games = _parseApiResponse(responseBody);
        if (games.isEmpty) {
          return;
        }

        final testGame = games.first;
        print('Remaining requests: ${response.headers['x-requests-remaining']}');
      } else {
      }
    } catch (e) {
      rethrow;
    }
  }
} 