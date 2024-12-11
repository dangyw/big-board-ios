class ParlayInvitation {
  final String id;
  final String parlayId;
  final String inviterId;
  final String inviteeId;
  final DateTime createdAt;
  final String? status; // 'pending', 'accepted', 'declined'

  ParlayInvitation({
    required this.id,
    required this.parlayId,
    required this.inviterId,
    required this.inviteeId,
    required this.createdAt,
    this.status = 'pending',
  });

  factory ParlayInvitation.fromMap(Map<String, dynamic> map) {
    return ParlayInvitation(
      id: map['id'],
      parlayId: map['parlay_id'],
      inviterId: map['inviter_id'],
      inviteeId: map['invitee_id'],
      createdAt: DateTime.parse(map['created_at']),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parlay_id': parlayId,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
} 