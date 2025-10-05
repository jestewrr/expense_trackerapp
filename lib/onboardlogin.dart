import 'package:flutter/material.dart';
import 'loginpage.dart';

class OnboardLoginPage extends StatelessWidget {
  const OnboardLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 202, 222, 237), // Background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start, // align left
            children: [
              // Piggy bank image
              Center(
                child: Image.asset(
                  "images/pig.png", // your piggy asset
                  height: 300,
                ),
              ),
              const SizedBox(height: 40),

              // Welcome text (bold + italic + left aligned)
              const Text(
                "Welcome to\nSave Expense",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 38, // larger than body text
                  color: Color(0xFF1A237E), // navy blue
                ),
              ),
              const SizedBox(height: 16),

              // Description text (left aligned + bigger font)
              const Text(
                "Track your spending,\nsave more, and take control of your money.",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 28, // slightly larger
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 35),

              // Get Started button (centered full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0, // remove shadow
                    backgroundColor: const Color.fromARGB(255, 70, 188, 243), // light blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      color: Colors.black,
                    ),
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
