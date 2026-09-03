import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hopin/authentication/signup_otp_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child('Users');

  String? _errorMessage;
  bool _isSending = false;

  void _sendOTP() async {
    setState(() {
      _errorMessage = null;
      _isSending = true;
    });

    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = "Phone number cannot be blank!";
        _isSending = false;
      });
      return;
    }

    if (phone.length != 9 || !RegExp(r'^\d{9}$').hasMatch(phone)) {
      setState(() {
        _errorMessage = "Phone number must be exactly 9 digits";
        _isSending = false;
      });
      return;
    }

    String fullPhoneNumber = "+94$phone";

    try {
      // Check if the phone number already exists in the database
      final snapshot = await _databaseRef.get();

      if (snapshot.exists) {
        bool numberExists = false;
        for (final child in snapshot.children) {
          final data = child.value as Map<dynamic, dynamic>;
          if (data['phone'] == fullPhoneNumber) {
            numberExists = true;
            break;
          }
        }

        if (numberExists) {
          setState(() {
            _errorMessage = "Phone number already registered.";
            _isSending = false;
          });
          return;
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SignupOtp(
                  verificationId: 'auto-verified',
                  phoneNumber: fullPhoneNumber,
                ),
              ),
            );
          } catch (e) {
            setState(() {
              _errorMessage = "Auto-verification failed.";
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = "Verification failed: ${e.message}";
            _isSending = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SignupOtp(
                verificationId: verificationId,
                phoneNumber: fullPhoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _errorMessage = "OTP Timeout! Please try again.";
            _isSending = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Unexpected error: $e";
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE5DC),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/images/hopin_logo.png', height: 80),
                    const SizedBox(height: 15),
                    Text(
                      'HopIn',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF154314),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Text(
                "What's your phone number?",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF154314),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "We’ll text you a verification code",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF154314),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/sri.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "+94",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            keyboardType: TextInputType.number,
                            maxLength: 9,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: "Phone number",
                              counterText: "",
                              border: InputBorder.none,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              setState(() => _errorMessage = null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              Center(
                child: Text(
                  'By clicking “Continue” you agree to our Terms of Use',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF154314),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                      : Text(
                    "Continue",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
