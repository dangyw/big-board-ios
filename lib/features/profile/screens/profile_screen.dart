import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:big_board/features/profile/models/user_profile.dart';
import 'package:big_board/features/profile/services/user_profile_service.dart';
import 'package:big_board/features/profile/services/user_profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile userProfile;

  ProfileScreen({Key? key, required this.userProfile}) : super(key: key);

  void clearImageCache(String url) {
    final image = NetworkImage(url);
    image.evict();
  }

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
                        _buildAvatarWithOptions(context, profile),
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

  Future<File?> _pickAndCropImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (pickedFile == null) return null;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        cropStyle: CropStyle.circle,
        compressQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {}
    return null;
  }

  void _showAvatarOptions(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userProfileProvider = context.read<UserProfileProvider>();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  
                  final imageFile = await _pickAndCropImage();
                  if (imageFile != null) {
                    try {
                      // Clear cache for the old image
                      if (userProfile.photoURL != null) {
                        clearImageCache(userProfile.photoURL!);
                      }

                      final uploadedUrl = await userProfileProvider
                          .uploadProfileImage(imageFile);
                      
                      if (uploadedUrl != null) {
                        await userProfileProvider.updateAvatarUrl(uploadedUrl);
                      }
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Failed to upload image: $e')),
                      );
                    }
                  }
                },
              ),
              if (userProfile.photoURL != null)
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Remove photo'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      await userProfileProvider.removeProfileImage();
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Failed to remove image: $e')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarWithOptions(BuildContext context, UserProfile userProfile) {
    return GestureDetector(
      onTap: () => _showAvatarOptions(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: userProfile.photoURL != null
                ? NetworkImage(userProfile.photoURL!)
                : null,
            child: userProfile.photoURL == null
                ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
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