import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:big_board/core/config/supabase_config.dart';
import 'package:big_board/features/auth/services/auth_service.dart';
import 'package:big_board/features/auth/screens/sign_in_screen.dart';
import 'package:big_board/features/auth/widgets/auth_guard.dart';
import 'package:big_board/features/profile/services/user_profile_service.dart';
import 'package:big_board/features/profile/services/user_profile_provider.dart';
import 'package:big_board/features/profile/screens/create_profile_screen.dart';
import 'package:big_board/features/parlays/screens/main_screen.dart';
import 'features/parlays/state/parlay_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(
    ParlayProvider(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<UserProfileService>(
          create: (_) => UserProfileService(),
        ),
        StreamProvider(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Big Board',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthGuard(),
      ),
    );
  }
}

class AuthCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          final user = snapshot.data!.session!.user;  // Get the current user
          
          return FutureBuilder<bool>(
            future: context.read<UserProfileProvider>().hasProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (profileSnapshot.data == true) {
                return MainScreen();
              } else {
                // Pass the user to CreateProfileScreen
                return CreateProfileScreen(user: user);
              }
            },
          );
        }
        
        return SignInScreen();
      },
    );
  }
}
