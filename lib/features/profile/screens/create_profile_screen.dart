import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/profile/services/user_profile_provider.dart';
import 'package:big_board/features/profile/services/user_profile_service.dart';
import 'package:big_board/features/parlays/screens/main_screen.dart';
import '../models/user_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

class CreateProfileScreen extends StatefulWidget {
  final User user;
  
  const CreateProfileScreen({Key? key, required this.user}) : super(key: key);
  
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  File? _imageFile;
  final _picker = ImagePicker();
  final _displayNameController = TextEditingController();
  final _unitValueController = TextEditingController(text: '10.0');

  Future<void> _pickAndCropImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,  // Limit image size
        maxHeight: 500,
      );
      
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        cropStyle: CropStyle.circle,
        compressQuality: 70, // Compress image quality
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
        setState(() {
          _imageFile = File(croppedFile.path);
        });
      }
    } catch (e) {
      print('Error picking/cropping image: $e');
    }
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _pickAndCropImage,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: _imageFile != null
              ? Image.file(
                  _imageFile!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: Colors.grey[600],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              _buildProfileImagePicker(),
              SizedBox(height: 32),
              Text(
                'Welcome to Big Board!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Set up your profile to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _unitValueController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Unit Value (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  helperText: 'The dollar amount that represents one unit in your bets',
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _createProfile(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Create Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createProfile(BuildContext context) async {
    try {
      final provider = context.read<UserProfileProvider>();
      final unitValue = double.tryParse(_unitValueController.text) ?? 10.0;
      
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await provider.uploadProfileImage(File(_imageFile!.path));
      }

      await provider.createInitialProfile(
        displayName: _displayNameController.text,
        photoUrl: photoUrl,
        unitValue: unitValue,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainScreen()),
        );
      }
    } catch (e) {
      print('Error creating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile')),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _unitValueController.dispose();
    super.dispose();
  }
} 