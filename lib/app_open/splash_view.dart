import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/app_open/auth_choose_view.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double carPosition = -40;
  List<double> letterOpacity = [0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 600), () {
      setState(() {
        carPosition = MediaQuery.of(context).size.width / 2 + 100;
      });
    });

    for (int i = 0; i < letterOpacity.length; i++) {
      Future.delayed(Duration(milliseconds: 1000 + (i * 400)), () {
        setState(() {
          letterOpacity[i] = 1;
        });
      });
    }

    Future.delayed(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => authHome()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE5DC),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // HOPIN Animated Text
            Positioned(
              top: MediaQuery.of(context).size.height / 2 + 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedLetter('H', 0),
                  _buildAnimatedLetter('O', 1),
                  _buildAnimatedLetter('P', 2),
                  _buildAnimatedLetter('I', 3),
                  _buildAnimatedLetter('N', 4),
                ],
              ),
            ),

            // Car Animation
            AnimatedPositioned(
              duration: Duration(seconds: 3),
              curve: Curves.easeInOut,
              left: carPosition,
             // left: MediaQuery.of(context).size.width / 2 - 50 + carPosition,
              bottom: MediaQuery.of(context).size.height / 2 + 80, // Move UP
              child: Image.asset(
                'assets/images/car.png',
                width: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Text('Image not found!', style: TextStyle(color: Colors.red));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLetter(String letter, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: letterOpacity[index],
      child: Text(
        letter,
        style: GoogleFonts.hind(
          fontSize: 60,
          fontWeight: FontWeight.bold,
          color: Color(0xFF154314),
        ),
      ),
    );
  }
}
