import 'package:flutter/material.dart';
import '../models/saved_parlay.dart';
import '../services/parlay_service.dart';
import '../utils/odds_calculator.dart';

class SavedParlaysScreen extends StatelessWidget {
  final ParlayService _parlayService = ParlayService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Parlays'),
      ),
      body: StreamBuilder<List<SavedParlay>>(
        stream: _parlayService.getParlays(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading parlays'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final parlays = snapshot.data ?? [];
          
          if (parlays.isEmpty) {
            return Center(
              child: Text('No saved parlays yet'),
            );
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
                          Text(
                            pick.betType,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                pick.betType == 'Spread'
                                    ? '${pick.spreadValue} (${OddsCalculator.formatOdds(pick.odds)})'
                                    : OddsCalculator.formatOdds(pick.odds),
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'vs ${pick.opponent}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => _parlayService.deleteParlay(parlay.id),
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

  String _formatDate(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    
    // Get day of week
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayOfWeek = days[localTime.weekday % 7];
    
    // Get month
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    final month = months[localTime.month - 1];
    
    final day = localTime.day;
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    
    return '$dayOfWeek, $month $day - $hour:$minute';
  }
} 