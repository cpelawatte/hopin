import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hopin/admin_panel/admin_home.dart';
import 'package:hopin/admin_panel/vehicle_registration_request.dart';
import 'package:hopin/admin_panel/admin_chat_support.dart';

void main() {
  runApp(MaterialApp(
    home: AdminSignIn(),
  ));
}

class AdminSignIn extends StatefulWidget {
  @override
  _AdminSignInState createState() => _AdminSignInState();
}

class _AdminSignInState extends State<AdminSignIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child("Admin");

  int failedAttempts = 0;
  bool isLocked = false;

  @override
  void initState() {
    super.initState();
    checkLockStatus();
  }

  Future<void> checkLockStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lockTime = prefs.getInt("lockTime");
    if (lockTime != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime < lockTime) {
        setState(() {
          isLocked = true;
        });
        int remainingTime = lockTime - currentTime;
        Timer(Duration(milliseconds: remainingTime), () {
          setState(() {
            isLocked = false;
            failedAttempts = 0;
          });
          prefs.remove("lockTime");
        });
      }
    }
  }


  Future<void> sendEmailWithOTP(String otp, String recipientEmail) async {
    const serviceId = 'service_zsz6t7u';
    const templateId = 'template_20nqzvv';
    const publicKey = 'D28ijxKAYyPRhR60Y';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': recipientEmail,
          'otp': otp,
        },
      }),
    );

    if (response.statusCode == 200) {
      print('OTP email sent!');
    } else {
      print('Failed to send OTP email: ${response.body}');
    }
  }


  Future<void> signIn() async {
    // Check if the account is locked
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Too many failed attempts. Try again later.")),
      );
      return;
    }

    // Check if the email or password fields are empty
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    // Check if the email and password match in Firebase
    databaseRef.orderByChild("email").equalTo(email).once().then((snapshot) async {
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> users = snapshot.snapshot.value as Map<dynamic, dynamic>;
        bool found = false;
        String adminPhoneNumber = ""; // Variable to store the phone number

        users.forEach((key, value) {
          if (value['password'] == password) {
            found = true;
            adminPhoneNumber = value['phone']; // Fetch the admin's phone number from Firebase
            setState(() {
              failedAttempts = 0;
            });

            // Successfully signed in logic here
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Successful!")));

            // Navigate to AdminHome with the admin's phone number
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboard(adminPhoneNumber: adminPhoneNumber),
              ),
            );
          }
        });
        if (!found) handleFailedAttempt();
      } else {
        handleFailedAttempt();
      }
    });
  }

  Future<void> handleFailedAttempt() async {
    setState(() {
      failedAttempts++;
    });
    if (failedAttempts >= 3) {
      setState(() {
        isLocked = true;
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int lockTime = DateTime.now().millisecondsSinceEpoch + (10 * 60 * 1000);
      await prefs.setInt("lockTime", lockTime);
      Timer(Duration(minutes: 10), () {
        setState(() {
          isLocked = false;
          failedAttempts = 0;
        });
        prefs.remove("lockTime");
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Invalid credentials. Attempts left: ${3 - failedAttempts}"),
    ));
  }

  String generateOTP() {
    var random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
  }

  Future<void> sendForgotPasswordOTP(String emailOrPhone) async {
    final snapshot = await databaseRef.orderByChild("email").equalTo(emailOrPhone).once();
    if (snapshot.snapshot.value != null) {
      String otp = generateOTP();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_reset_otp', otp);
      await prefs.setString('admin_reset_user', emailOrPhone);

      // For testing: show OTP in dialog (replace with SMS or Email sending in production)
      await sendEmailWithOTP(otp, emailOrPhone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP has been sent to your email.")),
      );
      showOTPVerificationDialog();
;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not found.")),
      );
    }
  }

  void showOTPVerificationDialog() {
    TextEditingController otpController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();

    bool validatePassword(String password) {
      final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>])[A-Za-z\d!@#\$%^&*(),.?":{}|<>]{8,}$');
      final forbiddenCharacters = RegExp(r'[=/]');
      return passwordRegex.hasMatch(password) && !forbiddenCharacters.hasMatch(password);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Verify OTP & Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: otpController,
              decoration: InputDecoration(hintText: "Enter OTP"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(hintText: "Enter New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String newPassword = newPasswordController.text.trim();

              // Validate OTP and password
              if (!validatePassword(newPassword)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password must be at least 8 characters long, and contain letters, numbers, and special characters, excluding '=' and '/'.")),
                );
                return;
              }

              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? savedOtp = prefs.getString('admin_reset_otp');
              String? userEmail = prefs.getString('admin_reset_user');

              if (savedOtp == otpController.text.trim()) {
                final userSnapshot = await databaseRef.orderByChild("email").equalTo(userEmail).once();
                if (userSnapshot.snapshot.value != null) {
                  Map<dynamic, dynamic> users = userSnapshot.snapshot.value as Map<dynamic, dynamic>;
                  users.forEach((key, value) async {
                    await databaseRef.child(key).update({
                      'password': newPassword,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password reset successful!")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Invalid OTP.")),
                );
              }
            },
            child: Text("Reset Password"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffefe5dc).withOpacity(0.4),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 900,
                height: 550,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 3,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        color: Color(0xffefe5dc).withOpacity(0.6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                "assets/images/hopin_logo.png",
                                height: 80,
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(
                              child: Text(
                                "HopIn",
                                style: GoogleFonts.poppins(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffe154314),
                                ),
                              ),
                            ),
                            SizedBox(height: 25),
                            Center(
                              child: Text(
                                "Sign In",
                                style: GoogleFonts.poppins(
                                  color: Color(0xffe154314),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text("Email Address", style: GoogleFonts.poppins(color: Color(0xffe154314))),
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text("Your Password", style: GoogleFonts.poppins(color: Color(0xffe154314))),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: isLocked ? null : signIn,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor: Color(0xff154314),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Sign In",
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    TextEditingController forgotController = TextEditingController();
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Forgot Password"),
                                        content: TextField(
                                          controller: forgotController,
                                          decoration: InputDecoration(hintText: "Enter your email"),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              sendForgotPasswordOTP(forgotController.text.trim());
                                            },
                                            child: Text("Send OTP"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.poppins(color: Color(0xffe154314)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/images/sideways.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Welcome Back!",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
