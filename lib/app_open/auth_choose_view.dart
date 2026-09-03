import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:hopin/authentication/login_view.dart';
import 'package:hopin/authentication/signup_view.dart';

class authHome extends StatefulWidget {
  const authHome({super.key});

  @override
  State<authHome> createState() => _authHomeState();
}

class _authHomeState extends State<authHome> {
  Map<String, bool> _isPressed = {'Login': false, 'Register': false};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE5DC), // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Logo Image (Ensure logo.png is in assets/images/)
            Image.asset('assets/images/hopin_logo.png', width: 60),

            const SizedBox(height: 10),

            // App Title
            Text(
              'HopIn',
              style: GoogleFonts.hind(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFF154314),
              ),
            ),

            const SizedBox(height: 15),

            Lottie.network(
              'https://lottie.host/fd10f1ab-254b-4ca9-a5fe-f78abed53fa5/Jr1e7KCyk8.json',
              width: 250,
              height: 180,
              fit: BoxFit.cover,
            ),

            const SizedBox(height: 20),

            // Tagline
            Text(
              'Ride Smart, Ride Fast, Pay Less',
              style: GoogleFonts.hind(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle with Two Lines
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'HopIn is the smartest way \n', // First Line
                    style: GoogleFonts.hind(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: 'to move around in your city.', // Second Line
                    style: GoogleFonts.hind(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Login & Register Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAuthButton(context, 'Login'),
                const SizedBox(width: 10),
                _buildAuthButton(context, 'Register'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function for Login/Register Buttons
  Widget _buildAuthButton(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPressed[text] = true;
        });

        Future.delayed(Duration(milliseconds: 200), () {
          setState(() {
            _isPressed[text] = false;
          });
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isPressed[text]! ? Color(0xFF1E5A20) : Color(0xFF154314), //On Click effect
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPressed[text]! ? Color(0xFF1E5A20) : Color(0xFF154314), //Click effect
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          //on pressed
          onPressed: () {
            if (text == 'Login') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            } else if (text == 'Register') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpView()),
              );
            }
          },
          child: Text(
            text,
            style: GoogleFonts.hind(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
