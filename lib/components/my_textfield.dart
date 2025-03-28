import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon; // Add this property for suffixIcon

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.suffixIcon, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          fillColor: Colors.grey[700],
          filled: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.white,
          ),
          suffixIcon: suffixIcon, // Add suffixIcon to InputDecoration
        ),
      ),
    );
  }
}
