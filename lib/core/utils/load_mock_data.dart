import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:big_board/features/parlays/models/game.dart';

class MockDataLoader {
  static Future<List<Game>> loadGames() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
} 