import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/profile/models/user_profile.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class UserProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      
      if (response != null) {
        return UserProfile.fromMap(response, userId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createInitialProfile(UserProfile profile) async {
    try {
      await _supabase.from('user_profiles').insert({
        'user_id': profile.userId,
        'display_name': profile.displayName,
        'email': profile.email,
        'photo_url': profile.photoURL,
        'unit_value': profile.unitValue,
        'created_at': profile.createdAt.toIso8601String(),
        'joined_at': profile.joinedAt.toIso8601String(),
        'bankroll': 0.0,
        'parlay_count': 0,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('user_profiles')
          .update(profile.toMap())
          .eq('user_id', profile.userId);
    } catch (e) {
      rethrow;
    }
  }

  Stream<UserProfile?> streamProfile(String userId) {
    return _supabase
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.isNotEmpty 
            ? UserProfile.fromMap(data.first, userId)
            : null);
  }

  Future<void> updateBankroll(String userId, double newAmount) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'bankroll': newAmount})
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> incrementParlayCount(String userId) async {
    try {
      await _supabase.rpc(
        'increment_parlay_count',
        params: {'user_id_param': userId}
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .single();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadProfileImage(String filePath) async {
    try {
      final fileName = '${DateTime.now().toIso8601String()}_${path.basename(filePath)}';
      final file = File(filePath);
      
      // Upload to Supabase Storage
      final response = await _supabase
          .storage
          .from('profile-images')  // Create this bucket in Supabase
          .upload(fileName, file);

      // Get public URL
      final imageUrl = _supabase
          .storage
          .from('profile-images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfileImage(String userId, String imageUrl) async {
    await _supabase
        .from('profiles')
        .update({'photo_url': imageUrl})
        .eq('user_id', userId);
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(10);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      return []; // Return empty list instead of null on error
    }
  }
} 