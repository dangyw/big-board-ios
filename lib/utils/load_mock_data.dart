import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game.dart';

class MockDataLoader {
  static Future<List<Game>> loadGames() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      print('Error loading mock data: $e');
      return [];
    }
  }
} 