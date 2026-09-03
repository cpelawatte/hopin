import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:hopin/app_open/auth_choose_view.dart';
import 'package:hopin/authentication/finali_signup.dart';

class SignupOtp extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const SignupOtp({super.key, required this.verificationId, required this.phoneNumber});

  @override
  _SignupOtpState createState() => _SignupOtpState();
}

class _SignupOtpState extends State<SignupOtp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _otpCode = "";
  int _attempts = 0; // Track wrong attempts
  bool _isLoading = false;
  Color _resendButtonColor = const Color(0xFF154314); // Initial color of the resend button

  void _verifyOTP() async {
    if (_otpCode.length != 6) {
      _showErrorPopup("Please enter a valid 6-digit OTP.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpCode,
      );

      await _auth.signInWithCredential(credential);

      // If successful, navigate to RegisterFinal()
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegisterFinal(phoneNumber: widget.phoneNumber)),
      );
    } catch (e) {
      setState(() {
        _attempts++;
        _isLoading = false;
      });

      if (_attempts >= 3) {
        _showErrorPopup("Too many tries! Redirecting...");
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => authHome()),
          );
        });
      } else {
        _showErrorPopup("Invalid OTP! Attempts left: ${3 - _attempts}");
      }
    }
  }

  void _resendOTP() async {
    setState(() {
      _resendButtonColor = Colors.green[200]!; // Change button color to a lighter shade when clicked
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);

        // Navigate and pass the correct phone number
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterFinal(phoneNumber: widget.phoneNumber),
          ),
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        _showErrorPopup("Failed to resend OTP: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _showSuccessPopup("OTP Resent Successfully!");
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _resendButtonColor = const Color(0xFF154314); // Reset the button color after 1 second
      });
    });
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Error",
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Success",
          style: GoogleFonts.poppins(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE5DC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 70),
              Image.asset(
                'assets/images/hopin_logo.png',
                height: 60,
              ),
              const SizedBox(height: 20),
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
                "Login with phone number",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF154314),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Enter the six-digit code sent to your phone",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF154314),
                ),
              ),
              const SizedBox(height: 25),
              Pinput(
                length: 6,
                onChanged: (value) => _otpCode = value,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 50,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF154314),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: _resendOTP,
                child: Text(
                  "Didn't receive code? Resend",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _resendButtonColor,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF154314),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Confirm OTP",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => authHome()),
                ),
                child: Text(
                  "Go back? Click here!",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
