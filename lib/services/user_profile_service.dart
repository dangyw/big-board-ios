import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create initial profile for new users
  Future<void> createInitialProfile(User user) async {
    final profile = UserProfile(
      userId: user.uid,
      displayName: user.displayName ?? 'User',
      email: user.email,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(profile.toMap());
  }

  // Get user profile stream
  Stream<UserProfile?> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromMap(doc.data()!, doc.id) : null);
  }

  // Update unit value
  Future<void> updateUnitValue(double unitValue) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({'unitValue': unitValue});
  }

  // Update bankroll
  Future<void> updateBankroll(double bankroll) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({'bankroll': bankroll});
  }

  // Increment parlay count
  Future<void> incrementParlayCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({'parlayCount': FieldValue.increment(1)});
  }
} 