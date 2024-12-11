import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient, Supabase, User, AuthResponse, OAuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:big_board/features/profile/models/user_profile.dart';
import 'package:big_board/features/profile/services/user_profile_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserProfileService _profileService = UserProfileService();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange
      .map((event) {
        print('Auth state change event: ${event.event}'); // Debug log
        print('User in event: ${event.session?.user?.id}'); // Debug log
        return event.session?.user;
      });

  // Apple Sign In
  Future<AuthResponse> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final hashedNonce = sha256ofString(rawNonce);

      print('Starting Apple sign in process...'); // Debug log

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          redirectUri: Uri.parse('https://kdqdcifyabiufhmlmddb.supabase.co/auth/v1/callback'),
          clientId: 'com.bigboard.ios',
        ),
        nonce: hashedNonce,
      );

      print('Got Apple credential'); // Debug log

      // Sign in with Supabase
      final authResponse = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );

      print('Got Supabase auth response: ${authResponse.session?.user?.id}'); // Debug log

      // Important: Wait for auth to be fully processed
      await Future.delayed(Duration(milliseconds: 500));

      // Check and create profile if needed
      if (authResponse.session?.user != null) {
        final userId = authResponse.session!.user.id;
        final hasExistingProfile = await _profileService.hasProfile(userId);
        print('Has existing profile: $hasExistingProfile'); // Debug log
        
        if (!hasExistingProfile && 
            credential.givenName != null && 
            credential.familyName != null) {
          print('Creating new profile...'); // Debug log
          
          // Create profile
          final profile = UserProfile(
            id: userId,
            userId: userId,
            email: authResponse.session!.user.email ?? '',
            displayName: '${credential.givenName} ${credential.familyName}',
            photoURL: authResponse.session!.user.userMetadata?['avatar_url'],
            unitValue: 10.0,
            bankroll: 00.0,
            parlayCount: 0,
            createdAt: DateTime.now(),
            joinedAt: DateTime.now(),
          );

          // Wait for profile creation to complete
          await _profileService.createInitialProfile(profile);
          print('Profile created successfully'); // Debug log
          
          // Verify profile was created
          final profileVerified = await _profileService.hasProfile(userId);
          print('Profile verification after creation: $profileVerified'); // Debug log
        }
      }

      return authResponse;
    } catch (error) {
      print('Error in signInWithApple: $error'); // Debug log
      throw Exception('Error signing in with Apple: $error');
    }
  }

  // Helper function to generate nonce
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Helper function to SHA256 hash the nonce
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
} 