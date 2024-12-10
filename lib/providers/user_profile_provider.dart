import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  UserProfile? _userProfile;
  String? _error;
  bool _loading = false;

  UserProfile? get userProfile => _userProfile;
  String? get error => _error;
  bool get isLoading => _loading;

  Stream<UserProfile?> get profileStream {
    return _firestore
        .collection('users')
        .doc(_userProfile?.userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> loadUserProfile(String userId) async {
    try {
      _loading = true;
      _error = null; 
      notifyListeners();

      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        _error = 'Profile not found';
        _loading = false;
        notifyListeners();
        return;
      }

      _userProfile = UserProfile.fromMap(docSnapshot.data()!, docSnapshot.id);
      _loading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading profile: $e');
      _error = 'Error loading profile';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUnitValue(double newValue) async {
    if (_userProfile?.userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userProfile!.userId)
          .update({'unitValue': newValue});
    } catch (e) {
      print('Error updating unit value: $e');
      _error = 'Error updating unit value';
      notifyListeners();
    }
  }

  Future<void> updateBankroll(double newValue) async {
    if (_userProfile?.userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userProfile!.userId)
          .update({'bankroll': newValue});
    } catch (e) {
      print('Error updating bankroll: $e');
      _error = 'Error updating bankroll';
      notifyListeners();
    }
  }
} 