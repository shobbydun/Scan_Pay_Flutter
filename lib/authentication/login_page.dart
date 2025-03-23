import 'dart:ui'; // Import this for BackdropFilter and ImageFilter

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scan_pay/components/my_button.dart';
import 'package:scan_pay/components/my_textfield.dart';
import 'package:scan_pay/pages/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;

  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier(false);
  String _errorMessage = "";

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _isPasswordVisible.dispose();
    super.dispose();
  }

void signUserIn() async {
  // Validate input fields
  if (emailController.text.trim().isEmpty) {
    showErrorMessage("Email is required.");
    return;
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(emailController.text.trim())) {
    showErrorMessage("Please enter a valid email address.");
    return;
  }
  if (passwordController.text.isEmpty) {
    showErrorMessage("Password is required.");
    return;
  }

  // Show loading dialog
  if (mounted) {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.green),
        );
      },
    );
  }

  try {
    // Attempt to sign in the user with Firebase
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text);

    // Navigate to Dashboard if login is successful
    if (mounted) {
      Navigator.pop(context); // Close the loading dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    }
  } on FirebaseAuthException catch (e) {
    // Close the loading dialog
    if (mounted) Navigator.pop(context);

    // Handle specific FirebaseAuth error codes
    String errorMessage = "An error occurred. Please try again.";
    if (e.code == 'user-not-found') {
      errorMessage = "No account matches the provided email.";
    } else if (e.code == 'wrong-password') {
      errorMessage = "Incorrect password. Please try again.";
    } else if (e.code == 'invalid-email') {
      errorMessage = "Invalid email address.";
    }

    // Show user-friendly error message
    showErrorMessage(errorMessage);
  } catch (e) {
    // Handle any unexpected errors
    if (mounted) Navigator.pop(context);
    showErrorMessage("Unexpected error: ${e.toString()}");
  }
}


  void forgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[300],
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your email address and we'll send you a link to reset your password.",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: "Enter email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text;
                if (email.isEmpty) {
                  setState(() {
                    _errorMessage = "Email cannot be empty.";
                    emailController.clear();
                  });
                } else if (!_isValidEmail(email)) {
                  setState(() {
                    _errorMessage = "Invalid email address.";
                    emailController.clear();
                  });
                } else {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: email,
                    );
                    if (mounted)
                      Navigator.of(context).pop(); // Close the dialog
                    if (mounted)
                      showSuccessMessage("Password reset email sent!");
                  } on FirebaseAuthException catch (e) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = e.message ?? "An error occurred";
                      });
                    }
                  }
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  // Helper method to check email validity
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  void showErrorMessage(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 247, 112, 112),
            title: Center(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          );
        },
      );
    }
  }

  void showSuccessMessage(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.green,
            title: Center(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/backkk.png', // Replace with your image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome Back\nScan Pay",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Larger font size
                        fontWeight: FontWeight.bold, // Bold text for emphasis
                        letterSpacing:
                            1.2, // Slightly increased spacing between letters
                        shadows: [
                          Shadow(
                            offset: Offset(2.0, 2.0),
                            blurRadius: 4.0,
                            color: Colors.green.withOpacity(
                              0.6,
                            ), // Text shadow effect
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    MyTextfield(
                      controller: emailController,
                      hintText: "Email",
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    // Password TextField with visibility toggle
                    ValueListenableBuilder<bool>(
                      valueListenable: _isPasswordVisible,
                      builder: (context, isVisible, child) {
                        return MyTextfield(
                          controller: passwordController,
                          hintText: "Password",
                          obscureText: !isVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _isPasswordVisible.value = !isVisible;
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: forgotPassword,
                            child: Text(
                              "Forgot password?",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    MyButton(text: "Sign in", onTap: signUserIn),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Not a member?",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            "Register now",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
