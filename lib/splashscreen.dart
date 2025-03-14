import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:waaqti/loginscreen.dart';
import 'onboarding.dart';

// ✅ Splash Screen with Lottie Animation
class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  const SplashScreen({super.key, required this.hasSeenOnboarding});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Wait for animation to finish, then navigate
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => widget.hasSeenOnboarding ? LoginScreen() : OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/Waaqti.json', // Replace with your animation file
          // width: 300,
          // height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}