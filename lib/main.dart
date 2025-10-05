import 'package:expense_tracker_application/onboardlogin.dart';
import 'package:flutter/material.dart';
import 'loginpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Start with OnboardLoginPage
      home: const OnboardLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

