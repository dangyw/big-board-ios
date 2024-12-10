import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: context.read<UserProfileProvider>().profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return Center(child: Text('Error loading profile'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profile.photoURL != null 
                              ? NetworkImage(profile.photoURL!)
                              : null,
                          child: profile.photoURL == null 
                              ? Text(
                                  profile.displayName[0].toUpperCase(),
                                  style: TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        SizedBox(height: 16),
                        Text(
                          profile.displayName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile.email ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Stats Section
                  Text(
                    'Stats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _StatTile(
                    title: 'Total Parlays',
                    value: '${profile.parlayCount}',
                    icon: Icons.analytics,
                  ),
                  _StatTile(
                    title: 'Member Since',
                    value: _formatDate(profile.joinedAt),
                    icon: Icons.calendar_today,
                  ),

                  SizedBox(height: 32),

                  // Settings Section
                  Text(
                    'Betting Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _EditableSettingTile(
                    title: 'Unit Value',
                    value: '\$${profile.unitValue.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    onEdit: () => _editUnitValue(context, profile),
                  ),
                  _EditableSettingTile(
                    title: 'Bankroll',
                    value: '\$${profile.bankroll.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    onEdit: () => _editBankroll(context, profile),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _editUnitValue(BuildContext context, UserProfile profile) async {
    final controller = TextEditingController(
      text: profile.unitValue.toStringAsFixed(2),
    );

    final newValue = await showDialog<double>(
      context: context,
      builder: (context) => _EditDialog(
        title: 'Edit Unit Value',
        controller: controller,
        initialValue: profile.unitValue,
      ),
    );

    if (newValue != null) {
      await context.read<UserProfileProvider>().updateUnitValue(newValue);
    }
  }

  Future<void> _editBankroll(BuildContext context, UserProfile profile) async {
    final controller = TextEditingController(
      text: profile.bankroll.toStringAsFixed(2),
    );

    final newValue = await showDialog<double>(
      context: context,
      builder: (context) => _EditDialog(
        title: 'Edit Bankroll',
        controller: controller,
        initialValue: profile.bankroll,
      ),
    );

    if (newValue != null) {
      await context.read<UserProfileProvider>().updateBankroll(newValue);
    }
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _EditableSettingTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  const _EditableSettingTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit, size: 20),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _EditDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final double initialValue;

  const _EditDialog({
    required this.title,
    required this.controller,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixText: '\$',
          border: OutlineInputBorder(),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(controller.text);
            if (value != null) {
              Navigator.pop(context, value);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
} 