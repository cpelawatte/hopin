import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/user_home/home_page.dart';

class PassResetConfirmScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId; // You can remove this if not needed
  final String otpCode; // You can remove this if not needed

  const PassResetConfirmScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
    required this.otpCode,
  }) : super(key: key);

  @override
  _PassResetConfirmScreenState createState() => _PassResetConfirmScreenState();
}

class _PassResetConfirmScreenState extends State<PassResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Password validation
  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$').hasMatch(password);
  }

  // Update password in Firebase Authentication and Realtime Database
  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update Firebase Authentication password
      await _updateFirebaseAuthPassword(_newPasswordController.text);

      // Update password in Firebase Realtime Database
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("Users");
      DatabaseEvent event = await usersRef.orderByChild("phone").equalTo(widget.phoneNumber).once();

      if (event.snapshot.value != null) {
        Map<String, dynamic> usersMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        String userId = usersMap.keys.first;

        // Update password in the Realtime Database
        await usersRef.child(userId).update({"password": _newPasswordController.text});

        // Show success message & navigate to Home Page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password updated successfully!", style: GoogleFonts.poppins())),
        );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(phoneNumber: widget.phoneNumber)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found!", style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating password: $e", style: GoogleFonts.poppins())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Update Firebase Authentication password
  Future<void> _updateFirebaseAuthPassword(String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE5DC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 70),
                  Image.asset('assets/images/hopin_logo.png', height: 60),
                  const SizedBox(height: 20),
                  Text(
                    "HopIn",
                    style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF154314)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Reset Password",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF154314)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Enter your new password",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w300, color: const Color(0xFF154314)),
                  ),
                  const SizedBox(height: 25),

                  // New Password Field
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || !_isPasswordValid(value)) {
                        return "Must be 8+ chars, include letters, numbers & special characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Confirm Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF154314),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("Confirm Password", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
