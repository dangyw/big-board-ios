import 'package:flutter/material.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/parlays/services/parlay_service.dart';
import 'package:big_board/core/utils/odds_calculator.dart';

class SavedParlaysScreen extends StatefulWidget {
  final String? groupId;
  
  const SavedParlaysScreen({
    Key? key,
    this.groupId,
  }) : super(key: key);

  @override
  _SavedParlaysScreenState createState() => _SavedParlaysScreenState();
}

class _SavedParlaysScreenState extends State<SavedParlaysScreen> {
  final ParlayService _parlayService = ParlayService();

  @override
  void initState() {
    super.initState();
    print('SavedParlaysScreen initialized - groupId: ${widget.groupId}');
  }

  @override
  Widget build(BuildContext context) {
    print('SavedParlaysScreen building - groupId: ${widget.groupId}');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId != null ? 'Group Parlays' : 'My Parlays'),
      ),
      body: StreamBuilder<List<SavedParlay>>(
        stream: _parlayService.getParlays(groupId: widget.groupId),
        builder: (context, snapshot) {
          print('SavedParlaysScreen StreamBuilder update:'
              '\n  - connectionState: ${snapshot.connectionState}'
              '\n  - hasData: ${snapshot.hasData}'
              '\n  - hasError: ${snapshot.hasError}'
              '\n  - error: ${snapshot.error}'
              '\n  - stackTrace: ${snapshot.stackTrace}'
              '\n  - dataLength: ${snapshot.data?.length}');
              
          if (snapshot.hasError) {
            print('SavedParlaysScreen error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading parlays'),
                  if (snapshot.error != null)
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('SavedParlaysScreen showing loading indicator');
            return Center(child: CircularProgressIndicator());
          }

          final parlays = snapshot.data ?? [];
          print('SavedParlaysScreen received ${parlays.length} parlays');
          
          if (parlays.isEmpty) {
            return Center(child: Text('No saved parlays yet'));
          }

          return ListView.builder(
            itemCount: parlays.length,
            itemBuilder: (context, index) {
              final parlay = parlays[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    '${parlay.picks.length} Team Parlay',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Odds: ${OddsCalculator.formatOdds(parlay.totalOdds)}',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(parlay.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    ...parlay.picks.map((pick) => ListTile(
                      title: Text(pick.teamName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pick.betType),
                          Text(
                            'vs ${pick.opponent}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        pick.betType == 'Spread'
                            ? '${pick.spreadValue} (${OddsCalculator.formatOdds(pick.odds)})'
                            : OddsCalculator.formatOdds(pick.odds),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => _confirmAndDeleteParlay(context, parlay.id),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _confirmAndDeleteParlay(BuildContext context, String parlayId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Parlay'),
        content: Text('Are you sure you want to delete this parlay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _parlayService.deleteParlay(parlayId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parlay deleted')),
        );
      } catch (e) {
        print('Error deleting parlay: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting parlay')),
        );
      }
    }
  }

  @override
  void dispose() {
    _parlayService.dispose();
    super.dispose();
  }
} 
