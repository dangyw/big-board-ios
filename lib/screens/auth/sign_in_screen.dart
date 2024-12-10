import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:big_board/services/auth_service.dart';

class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Big Board'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.apple),
              label: Text('Sign in with Apple'),
              onPressed: () async {
                try {
                  final result = await authService.signInWithApple();
                  if (result != null) {
                    print('Signed in: ${result.user?.uid}');
                  }
                } catch (e) {
                  print('Error signing in: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sign in failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 