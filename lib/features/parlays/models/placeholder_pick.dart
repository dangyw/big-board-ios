class PlaceholderPick {
  String? assignedMemberId;
  String? selectedGameId;
  String? selectedTeam;
  String? selectedBetType;
  bool isLocked = false;

  PlaceholderPick({
    this.assignedMemberId,
    this.selectedGameId,
    this.selectedTeam,
    this.selectedBetType,
  });

  bool get isComplete => selectedGameId != null && 
                        selectedTeam != null && 
                        selectedBetType != null;
} 