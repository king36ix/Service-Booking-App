import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:waaqti/loginscreen.dart';

/// ✅ Onboarding Screen
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => isLastPage = index == 3);
            },
            children: [
              buildPage("assets/barber1.webp", "Fresh cuts zero Hassle", "Discover new features and amazing UI"),
              buildPage("assets/barber12.webp", "Your Time Matters! \nBook With Ease","No more waiting in line!\nChoose your preferred time slot." ),
              buildPage("assets/barber2.webp", "Look Your Best","Track your past experiences,\nsave favorites."),
              buildPage("assets/barber4.webp", "Personalized Experience", "Save your favorite styles,\ntrack appointments & enjoy\nexclusive deals.")
            ]
          ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 4, // Fixed incorrect count (was 3 instead of 4)
                  effect: ExpandingDotsEffect(dotHeight: 8, dotWidth: 8, activeDotColor: Colors.blue),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: const Text("Skip"),
                      ),
                isLastPage
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: const Text("Get Started"),
                      )
                    : TextButton(
                        onPressed: () {
                          _controller.nextPage(duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
                        },
                        child: const Text("Next"),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage(String image, String title, String description) => Stack(
      children: [
        Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/logo_waaqti.png"),
                Text(title, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
}
