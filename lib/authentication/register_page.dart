import 'dart:ui'; // Import this for BackdropFilter and ImageFilter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scan_pay/components/my_button.dart';
import 'package:scan_pay/components/my_textfield.dart';
import 'package:scan_pay/pages/dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final businessNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isConfirmPasswordVisible = ValueNotifier<bool>(
    false,
  );

  bool isLoading = false;

  @override
  void dispose() {
    businessNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _isPasswordVisible.dispose();
    _isConfirmPasswordVisible.dispose();
    super.dispose();
  }

  void signUserUp() async {
    // Validate input fields
    if (businessNameController.text.trim().isEmpty) {
      showErrorMessage("Business name is required.");
      return;
    }
    if (emailController.text.trim().isEmpty) {
      showErrorMessage("Email is required.");
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      showErrorMessage("Please enter a valid email address.");
      return;
    }
    if (passwordController.text.isEmpty) {
      showErrorMessage("Password is required.");
      return;
    }
    if (passwordController.text.length < 6) {
      showErrorMessage("Password must be at least 6 characters long.");
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showErrorMessage("Passwords don't match.");
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Attempt to create user with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      String userId = userCredential.user?.uid ?? '';
      if (userId.isNotEmpty) {
        // Save additional user details to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': emailController.text.trim(),
          'businessName': businessNameController.text.trim(),
        }, SetOptions(merge: true));
      }

      // Navigate to Dashboard only if the widget is still mounted
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered. Please log in.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak.";
      }

      showErrorMessage(errorMessage);
    } catch (e) {
      showErrorMessage("Unexpected error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/screenshot.png',
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
                    const SizedBox(height: 90),
                    Text(
                      "W E L C O M E",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 35),

                    // Business Name TextField
                    MyTextfield(
                      controller: businessNameController,
                      hintText: "User Name",
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
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

                    // Confirm Password TextField with visibility toggle
                    ValueListenableBuilder<bool>(
                      valueListenable: _isConfirmPasswordVisible,
                      builder: (context, isVisible, child) {
                        return MyTextfield(
                          controller: confirmPasswordController,
                          hintText: "Confirm Password",
                          obscureText: !isVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _isConfirmPasswordVisible.value = !isVisible;
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    // Sign Up Button
                    MyButton(text: "Sign up", onTap: signUserUp),
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
                    const SizedBox(height: 20),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            "Login now",
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
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.green)),
        ],
      ),
    );
  }
}
