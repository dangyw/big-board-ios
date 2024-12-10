import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_parlay.dart';

class ParlayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveParlay(SavedParlay parlay) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('parlays')
        .doc(parlay.id)
        .set(parlay.toJson());
  }

  Stream<List<SavedParlay>> getParlays() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('parlays')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedParlay.fromJson(doc.data()))
            .toList());
  }

  Future<void> deleteParlay(String parlayId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('parlays')
        .doc(parlayId)
        .delete();
  }
} 