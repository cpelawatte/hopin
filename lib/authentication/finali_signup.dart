import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hopin/user_home/home_page.dart';
import 'package:hopin/app_open/auth_choose_view.dart';
import 'package:intl/intl.dart';

class RegisterFinal extends StatefulWidget {
  final String phoneNumber;

  const RegisterFinal({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<RegisterFinal> createState() => _RegisterFinalState();
}

class _RegisterFinalState extends State<RegisterFinal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();



  // Email regex pattern
  final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$');

  String? _confirmPasswordError;
  String? _selectedGender;

  // Initialize Firebase Realtime Database with region-specific URL
  late final FirebaseDatabase _database;

  @override
  void initState() {
    super.initState();

    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(), // Ensure Firebase is initialized first
      databaseURL: "https://hopin-146af-default-rtdb.asia-southeast1.firebasedatabase.app",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE5DC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/hopin_logo.png',
                    height: 70,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "HopIn",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF154314),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Create your account",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF154314),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                          Icons.person,
                        color: Color(0xffe154314),
                      ),
                      hintText: "Username",
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email, color: Color(0xffe154314),),
                      hintText: "Email",
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!_emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Color(0xffe154314),),
                      hintText: "Password",
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      } else if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      } else if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                          .hasMatch(value)) {
                        return 'Password must contain letters, numbers, and special characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Color(0xffe154314),),
                      hintText: "Confirm password",
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != _passwordController.text) {
                        setState(() {
                          _confirmPasswordError = 'Passwords do not match';
                        });
                        return _confirmPasswordError;
                      }
                      setState(() {
                        _confirmPasswordError = null;
                      });
                      return null;
                    },
                  ),
                  if (_confirmPasswordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _confirmPasswordError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Age field (only numeric input and minimum age 16)
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.cake, color: Color(0xffe154314),),
                      hintText: "Age",
                      border: UnderlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      } else if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      } else if (int.parse(value) < 16) {
                        return 'You must be at least 16 years old';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Gender dropdown (only selectable options)
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xffe154314),),
                      hintText: "Gender",
                      border: UnderlineInputBorder(),
                    ),
                    items: ["Female", "Male", "Rather not say"]
                        .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit button with Firebase Realtime Database integration
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154314),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            if (_usernameController.text.isEmpty ||
                                _emailController.text.isEmpty ||
                                _passwordController.text.isEmpty ||
                                _confirmPasswordController.text.isEmpty ||
                                _ageController.text.isEmpty ||
                                _selectedGender == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill in all the fields')),
                              );
                              return;
                            }

                            try {
                              String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

                              DatabaseReference userRef = _database.ref().child("Users").push();

                              await userRef.set({
                                "username": _usernameController.text.trim(),
                                "email": _emailController.text.trim().toLowerCase(),
                                "phone": widget.phoneNumber,
                                "password": _passwordController.text,
                                "age": int.parse(_ageController.text),
                                "gender": _selectedGender,
                                "registered_date": formattedDate,
                              });

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomePage(phoneNumber: widget.phoneNumber)),
                              );
                            } catch (e) {
                              print("Error: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Registration failed: ${e.toString()}")),
                              );
                            }
                          }
                        },

                      child: Text(
                        'Create',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Go back button
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const authHome()),
                      );
                    },
                    child: Text(
                      "Go back? Click here!",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF154314),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
