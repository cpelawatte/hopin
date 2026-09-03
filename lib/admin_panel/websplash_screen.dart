import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:hopin/admin_panel/web_admin_panel.dart';

class WebPanelSplashScreen extends StatefulWidget {
  @override
  _WebPanelSplashScreenState createState() => _WebPanelSplashScreenState();
}

class _WebPanelSplashScreenState extends State<WebPanelSplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/images/hopin_anim.gif")
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });

    // Navigate to AdminSignIn after 4 seconds
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminSignIn()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/hopin_anim.gif',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Text(
              'HopIn',
              style: GoogleFonts.poppins(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
