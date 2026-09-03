import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/app_open/auth_choose_view.dart';
import 'package:hopin/authentication/reset_pass_confirm.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("Users");
  int attempts = 0;
  String verificationId = '';
  String? phoneNumber;
  bool isLockedOut = false;
  Timer? lockoutTimer;

  void startLockout() {
    setState(() {
      isLockedOut = true;
    });
    lockoutTimer = Timer(Duration(minutes: 10), () {
      setState(() {
        isLockedOut = false;
        attempts = 0;
      });
      showToast("Lockout period ended. You can try again.");
    });
  }

  void validateUser() async {
    if (isLockedOut) {
      showToast("Too many failed attempts. Try again after 10 minutes.", isError: true);
      return;
    }

    String input = _controller.text.trim();

    if (input.isEmpty) {
      showToast("Fields cannot be empty!", isError: true);
      return;
    }

    bool isValid = false;

    try {
      final snapshot = await _dbRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        users.forEach((key, value) {
          if (value["email"] == input || value["phone"] == input) {
            isValid = true;
            phoneNumber = value["phone"];
          }
        });
      }

      if (isValid && phoneNumber != null) {
        sendOtp(phoneNumber!);
      } else {
        attempts++;
        if (attempts >= 3) {
          showToast("Too many failed attempts! Locking out for 10 minutes.", isError: true);
          startLockout();
        } else {
          showToast("Invalid email or phone number. Try again.");
        }
      }
    } catch (e) {
      showToast("Error fetching data. Check connection.");
    }
  }

  void sendOtp(String phone) {
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        showToast("OTP auto-verified");
      },
      verificationFailed: (FirebaseAuthException e) {
        showToast("Verification failed: ${e.message}", isError: true);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          this.verificationId = verificationId;
        });
        showOtpDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void showOtpDialog() {
    TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF0E7DA),
          title: Text("Enter OTP", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF154314))),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter 6-digit OTP",
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF154314))),
            ),
            ElevatedButton(
              onPressed: () => verifyOtp(otpController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF154314),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Verify", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void verifyOtp(String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      showToast("OTP Verified Successfully!");

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PassResetConfirmScreen(
            phoneNumber: phoneNumber!,
            verificationId: verificationId,
            otpCode: otp,
          ),
        ),
      );
    } catch (e) {
      attempts++;

      if (attempts >= 3) {
        showToast("Too many incorrect attempts. Redirecting to AuthHome.", isError: true);
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => authHome()),
          );
        });
      } else {
        showToast("Invalid OTP. Try again.", isError: true);
      }
    }
  }

  void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  void dispose() {
    lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0E7DA),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/hopin_logo.png", height: 80),
              SizedBox(height: 10),
              Text("HopIn", style: GoogleFonts.hind(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF154314))),
              SizedBox(height: 30),
              Text("Reset Password", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF154314))),
              SizedBox(height: 10),
              Text("Enter your email or mobile number", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 15, color: Colors.black54)),
              SizedBox(height: 25),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Phone number/email",
                    hintStyle: GoogleFonts.poppins(fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: validateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF154314),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Reset", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Go back? Click here!", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF154314))),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
