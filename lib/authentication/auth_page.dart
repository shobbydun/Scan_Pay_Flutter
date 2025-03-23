import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scan_pay/authentication/login_or_register_page.dart';
import 'package:scan_pay/pages/dashboard_page.dart';


class AuthPage extends StatelessWidget {

  const AuthPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final User? user = snapshot.data;
            if (user != null) {
              print('User authenticated: ${user.uid}');
              // Pass user.uid to FirestoreServices
              return DashboardPage(
              
              );
            }
          }

          print('No user authenticated');
          // Default to LoginOrRegisterPage if no user is authenticated
          return LoginOrRegisterPage();
        },
      ),
    );
  }
}
