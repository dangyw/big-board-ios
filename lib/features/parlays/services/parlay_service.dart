import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/parlays/models/parlay_invitation.dart';
import 'dart:async';
import '../models/placeholder_pick.dart';

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

  Stream<List<SavedParlay>> getParlays({String? groupId}) {
    if (groupId != null) {
      return getGroupParlays(groupId);
    }
    return _streamController.stream;
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

  Stream<List<SavedParlay>> getGroupParlays(String groupId) {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Initial load and setup stream
      _refreshGroupParlays(groupId);

      return _streamController.stream;
    } catch (e) {
      print('Error in getGroupParlays: $e');
      rethrow;
    }
  }

  Future<void> _refreshGroupParlays(String groupId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('parlays')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      final parlays = data.map((json) => SavedParlay.fromJson(json)).toList();
      _streamController.add(parlays);
    } catch (e) {
      print('Error refreshing group parlays: $e');
    }
  }

  void dispose() {
    _streamController.close();
  }

  Future<void> inviteToParlay({
    required String parlayId,
    required String inviteeId,
  }) async {
    try {
      await _supabase.from('parlay_invitations').insert({
        'parlay_id': parlayId,
        'inviter_id': _supabase.auth.currentUser!.id,
        'invitee_id': inviteeId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error inviting to parlay: $e');
      rethrow;
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _supabase.rpc(
        'accept_parlay_invitation',
        params: {'invitation_id_param': invitationId},
      );
    } catch (e) {
      print('Error accepting invitation: $e');
      rethrow;
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase
          .from('parlay_invitations')
          .update({'status': 'declined'})
          .eq('id', invitationId);
    } catch (e) {
      print('Error declining invitation: $e');
      rethrow;
    }
  }

  Future<List<ParlayInvitation>> getPendingInvitations() async {
    try {
      final response = await _supabase
          .from('parlay_invitations')
          .select()
          .eq('invitee_id', _supabase.auth.currentUser!.id)
          .eq('status', 'pending');
      
      return (response as List)
          .map((data) => ParlayInvitation.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting pending invitations: $e');
      rethrow;
    }
  }

  Future<String> createGroupParlay(String creatorId, String groupId, List<PlaceholderPick> picks) async {
    final response = await _supabase.from('parlays').insert({
      'creator_id': creatorId,
      'group_id': groupId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final parlayId = response['id'];

    // Create placeholder picks
    for (var pick in picks) {
      await _supabase.from('parlay_picks').insert({
        'parlay_id': parlayId,
        'assigned_member_id': pick.assignedMemberId,
        'status': 'pending',
      });
    }

    return parlayId;
  }

  Future<void> submitPick(String parlayId, String memberId, String gameId, String team, String betType) async {
    await _supabase.from('parlay_picks')
        .update({
          'game_id': gameId,
          'selected_team': team,
          'bet_type': betType,
          'status': 'completed'
        })
        .eq('parlay_id', parlayId)
        .eq('assigned_member_id', memberId);
  }
} 