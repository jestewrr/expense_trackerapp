import 'package:flutter/material.dart';
import 'registerpage.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  // Sample user database
  final List<Map<String, dynamic>> users = [
    {
      'username': 'firstuser',
      'password': 'password123',
      'isFirstTime': true,
    },
    {
      'username': 'regularuser',
      'password': 'mypassword',
      'isFirstTime': false,
    },
  ];

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;

  void _login() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    final user = users.firstWhere(
      (u) => u['username'] == username && u['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      // Login success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            isFirstLogin: user['isFirstTime'] ?? false,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = "Invalid username or password.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pig image (large)
                SizedBox(
                  height: 300,
                  child: Image.asset(
                    'images/pig.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),

                // Username field (no icon, large, rounded)
                _buildTextField(
                  hint: "Username",
                  isPassword: false,
                  controller: _usernameController,
                ),
                const SizedBox(height: 18),

                // Password field (no icon, large, rounded)
                _buildTextField(
                  hint: "Password",
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 18),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),

                // Login button (large, rounded)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign-up link (larger font)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t have an account? ",
                      style: TextStyle(fontSize: 15),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign-up here',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Clean, large textfield with rounded corners
  Widget _buildTextField({
    required String hint,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword ? _obscureText : false,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
            border: InputBorder.none,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
