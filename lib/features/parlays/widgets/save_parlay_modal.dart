import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/core/utils/odds_calculator.dart';

class SaveParlayModal extends StatefulWidget {
  final List<SavedPick> picks;
  final int totalOdds;
  final Function(double, String?) onSave;
  final List<Group> userGroups;

  const SaveParlayModal({
    Key? key,
    required this.picks,
    required this.totalOdds,
    required this.onSave,
    required this.userGroups,
  }) : super(key: key);

  @override
  _SaveParlayModalState createState() => _SaveParlayModalState();
}

class _SaveParlayModalState extends State<SaveParlayModal> {
  final _amountController = TextEditingController();
  double _potentialPayout = 0;
  String? _errorMessage;
  String? _selectedGroupId;

  void _calculatePayout(String value) {
    setState(() {
      _errorMessage = null;
      if (value.isEmpty) {
        _potentialPayout = 0;
        return;
      }

      final units = double.tryParse(value) ?? 0;
      final decimal = OddsCalculator.usToDecimal(widget.totalOdds);
      _potentialPayout = units * decimal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.picks.length} Team Parlay',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // List of picks
            ...widget.picks.map((pick) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pick.teamName,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    pick.betType == 'Spread' 
                        ? '${pick.spreadValue} (${pick.odds > 0 ? '+' : ''}${pick.odds})'
                        : '${pick.odds > 0 ? '+' : ''}${pick.odds}',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            )),
            
            if (widget.userGroups.isNotEmpty) ...[
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGroupId,
                decoration: InputDecoration(
                  labelText: 'Share with Group (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('Personal Parlay'),
                  ),
                  ...widget.userGroups.map((group) => DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGroupId = value;
                  });
                },
              ),
            ],

            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Enter Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              onChanged: _calculatePayout,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Potential Payout: \$${_potentialPayout.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final units = double.tryParse(_amountController.text) ?? 0;
                    if (units <= 0) {
                      setState(() {
                        _errorMessage = 'Please enter a valid amount';
                      });
                      return;
                    }
                    widget.onSave(units, _selectedGroupId);
                    Navigator.pop(context);
                  },
                  child: Text('Save Parlay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 