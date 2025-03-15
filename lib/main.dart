import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bizreg.dart';
import 'servicebooking.dart';
import 'package:waaqti/splashscreen.dart';
import 'loginscreen.dart';
import 'signupscreen.dart';
import 'onboarding.dart';
import 'home.dart'; // Import your Home screen
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart';
import 'bizreg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({Key? key, required this.hasSeenOnboarding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waaqti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      // home: SplashScreen(hasSeenOnboarding: hasSeenOnboarding),  // Remove the home property
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => SplashScreen(
            hasSeenOnboarding:
            hasSeenOnboarding), // Use the SplashScreen as the root route
        '/onboarding': (context) =>
        const OnboardingScreen(), // Define the onboarding route
        '/login': (context) =>
        const LoginScreen(), // Define the login route
        '/signup': (context) =>
        const SignUpScreen(), // Define the signup route
        '/home': (context) =>
        const SearchScreen(), // Define the home route
        '/booking': (context) =>
        Booking(),
        '/bizreg': (context) =>
            BizRegScreen(),
      },
    );
  }
}