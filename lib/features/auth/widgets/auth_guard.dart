import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/auth/services/auth_service.dart';
import 'package:big_board/features/auth/screens/sign_in_screen.dart';
import 'package:big_board/features/profile/services/user_profile_service.dart';
import 'package:big_board/features/profile/screens/create_profile_screen.dart';
import 'package:big_board/features/parlays/screens/main_screen.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<UserProfileService>(context, listen: false);

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print('Auth state in wrapper: ${snapshot.data?.event}'); // Debug log
        print('User in wrapper: ${snapshot.data?.session?.user?.id}'); // Debug log
        
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data?.session?.user;
          
          if (user == null) {
            return SignInScreen();
          }

          // User is authenticated, check for profile
          return FutureBuilder<bool>(
            future: profileService.hasProfile(user.id),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (profileSnapshot.data == true) {
                return const MainScreen();
              } else {
                return CreateProfileScreen(user: user);
              }
            },
          );
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
} 