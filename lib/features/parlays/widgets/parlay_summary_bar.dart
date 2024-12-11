import 'package:flutter/material.dart';
import 'package:big_board/core/utils/odds_calculator.dart';

class ParlaySummaryBar extends StatelessWidget {
  final int numPicks;
  final int odds;
  final VoidCallback onTap;
  final bool isGroupParlay;
  final int? completedPicks;

  const ParlaySummaryBar({
    Key? key,
    required this.numPicks,
    required this.odds,
    required this.onTap,
    this.isGroupParlay = false,
    this.completedPicks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGroupParlay ? 'Group Parlay ($numPicks picks)' : 'Parlay ($numPicks picks)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isGroupParlay && completedPicks != null)
                      Text(
                        '$completedPicks/$numPicks picks completed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      )
                    else
                      Text(
                        'Odds: ${OddsCalculator.formatOdds(odds)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE6D4F3),
                  foregroundColor: Colors.purple[900],
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Review & Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 