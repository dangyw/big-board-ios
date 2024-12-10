import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/saved_parlay.dart';
import 'dart:async';

class ParlayService {
  final _supabase = Supabase.instance.client;
  final _streamController = StreamController<List<SavedParlay>>.broadcast();

  Future<void> saveParlay(SavedParlay parlay) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final parlayJson = parlay.toJson();
      parlayJson.remove('id');  // Remove the id field and let Supabase generate it

      await _supabase
          .from('parlays')
          .insert(parlayJson);
    } catch (e) {
      print('Error saving parlay: $e');
      rethrow;
    }
  }

  Stream<List<SavedParlay>> getParlays() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Initial load and setup stream
      _refreshParlays();

      return _streamController.stream;
    } catch (e) {
      print('Error in getParlays: $e');
      rethrow;
    }
  }

  Future<void> _refreshParlays() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('parlays')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final parlays = data.map((json) => SavedParlay.fromJson(json)).toList();
      _streamController.add(parlays);
    } catch (e) {
      print('Error refreshing parlays: $e');
    }
  }

  Future<void> deleteParlay(String parlayId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('parlays')
          .delete()
          .eq('id', parlayId);
        
      print('Parlay deleted successfully: $parlayId');
      
      // Force refresh after delete
      await _refreshParlays();
      
    } catch (e) {
      print('Error deleting parlay: $e');
      rethrow;
    }
  }

  void dispose() {
    _streamController.close();
  }
} 