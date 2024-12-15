import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/parlays/models/game.dart';
import 'package:big_board/features/parlays/models/placeholder_pick.dart';
import 'package:big_board/core/utils/odds_calculator.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/features/parlays/services/parlay_service.dart';
import 'package:big_board/features/parlays/widgets/member_search_dialog.dart';
import 'package:big_board/features/groups/services/groups_service.dart';
import 'package:big_board/features/groups/widgets/create_group_dialog.dart';
import 'package:flutter/services.dart';
import './group_member_assignments.dart';
import 'package:provider/provider.dart';
import 'package:big_board/features/parlays/state/parlay_state.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/parlays/helpers/pick_helper.dart';

class ParlayDetailsSheet extends StatelessWidget {
  final bool isGroupParlay;
  final Function(bool) onGroupParlayChanged;
  final String teamName;
  final String opponent;
  final String betType;
  final double? spreadValue;
  final double odds;
  final List<String> memberNames;
  final List<Game> games;
  final VoidCallback onSave;
  final List<Group> userGroups;
  final Map<String, String> memberPhotos;

  const ParlayDetailsSheet({
    Key? key,
    required this.isGroupParlay,
    required this.onGroupParlayChanged,
    required this.teamName,
    required this.opponent,
    required this.betType,
    this.spreadValue,
    required this.odds,
    required this.memberNames,
    required this.games,
    required this.onSave,
    required this.userGroups,
    required this.memberPhotos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: const Text('Group Parlay Mode'),
          value: isGroupParlay,
          onChanged: onGroupParlayChanged,
        ),
        ListTile(
          title: Text(teamName),
          subtitle: Text('vs $opponent'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(betType),
              if (spreadValue != null) Text(spreadValue.toString()),
              Text(odds.toString()),
            ],
          ),
        ),
      ],
    );
  }
}