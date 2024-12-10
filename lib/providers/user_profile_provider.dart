import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import 'dart:io';

class UserProfileProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserProfile? _profile;
  bool _loading = false;
  final _userProfileService = UserProfileService();

  UserProfile? get profile => _profile;
  bool get loading => _loading;

  // Add stream controller
  final _profileController = StreamController<UserProfile?>.broadcast();
  Stream<UserProfile?> get _profileStream => _profileController.stream;

  Future<void> loadProfile() async {
    try {
      _loading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();
      
      _profile = UserProfile.fromMap(data, data['user_id']);
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createOrUpdateProfile({
    required String displayName,
    String? photoUrl,
    double? unitValue,
    double? bankroll,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final updates = {
        'user_id': user.id,
        'display_name': displayName,
        'email': user.email,
        'photo_url': photoUrl,
        if (unitValue != null) 'unit_value': unitValue,
        if (bankroll != null) 'bankroll': bankroll,
      };

      final data = await _supabase
          .from('user_profiles')
          .upsert(updates)
          .select()
          .single();

      _profile = UserProfile.fromMap(data, data['user_id']);
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<bool> hasProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();  // Returns null if no profile exists
      
      return response != null;
    } catch (error) {
      print('Error checking profile existence: $error');
      return false;
    }
  }

  Future<void> createInitialProfile({
    required String displayName,
    String? photoUrl,
    double unitValue = 10.0,
    double bankroll = 1000.0,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final profile = {
        'user_id': user.id,
        'display_name': displayName,
        'email': user.email,
        'photo_url': photoUrl,
        'unit_value': unitValue,
        'bankroll': bankroll,
        'parlay_count': 0,
      };

      final response = await _supabase
          .from('user_profiles')
          .insert(profile)
          .select()
          .single();
      
      _profile = UserProfile.fromMap(response, response['user_id']);
      notifyListeners();
    } catch (error) {
      print('Error creating initial profile: $error');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUnitValue(double newValue) async {
    try {
      await _supabase.from('user_profiles')
          .update({'unit_value': newValue})
          .eq('user_id', _profile?.userId ?? '');
      
      _profile = _profile?.copyWith(unitValue: newValue);
      _profileController.add(_profile);
      notifyListeners();
    } catch (e) {
      print('Error updating unit value: $e');
      rethrow;
    }
  }

  Future<void> updateBankroll(double newValue) async {
    try {
      await _supabase.from('user_profiles')
          .update({'bankroll': newValue})
          .eq('user_id', _profile?.userId ?? '');
      
      _profile = _profile?.copyWith(bankroll: newValue);
      _profileController.add(_profile);
      notifyListeners();
    } catch (e) {
      print('Error updating bankroll: $e');
      rethrow;
    }
  }

  // Add the getter
  Stream<UserProfile?> get profileStream {
    print('Starting profile stream...'); // Debug print
    
    final user = _supabase.auth.currentUser;
    print('Current user: ${user?.id}'); // Debug print
    
    if (user == null) {
      print('No user found in profileStream'); // Debug print
      return Stream.value(null);
    }

    try {
      return _supabase
          .from('user_profiles')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .map((event) {
            print('Received stream event: $event'); // Debug print
            if (event.isEmpty) {
              print('No profile data found for user ${user.id}');
              return null;
            }
            try {
              final profile = UserProfile.fromJson(event.first);
              print('Successfully parsed profile: ${profile.displayName}');
              return profile;
            } catch (e) {
              print('Error parsing profile: $e');
              print('Raw data: ${event.first}');
              return null;
            }
          });
    } catch (e) {
      print('Error setting up profile stream: $e');
      return Stream.value(null);
    }
  }
  
  // Make sure to close the controller when the provider is disposed
  @override
  void dispose() {
    _profileController.close();
    super.dispose();
  }
  
  // Add a method to update the stream
  void updateProfile(UserProfile? profile) {
    _profileController.add(profile);
    notifyListeners();
  }

  Future<String> uploadProfileImage(String imagePath) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final fileExt = imagePath.split('.').last;
      final fileName = '$userId.$fileExt';
      final filePath = 'profile_images/$fileName';
      
      // Upload the file to Supabase Storage
      final file = File(imagePath);
      await supabase.storage
          .from('avatars')
          .upload(filePath, file);

      // Get the public URL
      final imageUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image');
    }
  }
}