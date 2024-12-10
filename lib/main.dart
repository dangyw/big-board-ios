import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/config/supabase_config.dart';
import 'package:provider/provider.dart';
import 'package:big_board/services/auth_service.dart';
import 'package:big_board/providers/user_profile_provider.dart';
import 'package:big_board/screens/create_profile_screen.dart';
import 'package:big_board/screens/auth/sign_in_screen.dart';  // Use this instead
import 'package:big_board/screens/main_screen.dart';  // Your main app screen
import 'package:big_board/widgets/auth_wrapper.dart';
import 'package:big_board/services/user_profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(const MyApp());
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
        home: AuthWrapper(),
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
