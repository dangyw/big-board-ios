import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'user_profile_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _profileService = UserProfileService();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Apple Sign In
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      print('Got apple credential: ${appleCredential.identityToken != null}');

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: null,
      );

      print('Created oauth credential');

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      print('Signed in to Firebase: ${userCredential.user?.uid}');
      
      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create initial profile for new users
        await _profileService.createInitialProfile(userCredential.user!);
      }
      
      return userCredential;
    } catch (e) {
      print('Apple sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
} 