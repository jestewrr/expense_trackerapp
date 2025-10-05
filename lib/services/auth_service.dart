import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      List<User> users = [];

      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        users = usersList.map((userJson) => User.fromJson(userJson)).toList();
      }

      // Check if username already exists
      if (users.any((user) => user.username == username)) {
        return {
          'success': false,
          'message': 'Username already exists',
        };
      }

      // Check if email already exists
      if (users.any((user) => user.email == email)) {
        return {
          'success': false,
          'message': 'Email already exists',
        };
      }

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        password: password, // In a real app, you'd hash this
        email: email,
        createdAt: DateTime.now(),
      );

      users.add(newUser);

      // Save users to storage
      await prefs.setString(_usersKey, json.encode(users.map((u) => u.toJson()).toList()));

      return {
        'success': true,
        'message': 'Registration successful',
        'user': newUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);

      if (usersJson == null) {
        return {
          'success': false,
          'message': 'No users found. Please register first.',
        };
      }

      final List<dynamic> usersList = json.decode(usersJson);
      final List<User> users = usersList.map((userJson) => User.fromJson(userJson)).toList();

      // Find user by username
      final user = users.firstWhere(
        (user) => user.username == username,
        orElse: () => User(
          id: '',
          username: '',
          password: '',
          email: '',
          createdAt: DateTime.now(),
        ),
      );

      if (user.id.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Check password
      if (user.password != password) {
        return {
          'success': false,
          'message': 'Invalid password',
        };
      }

      // Save current user session
      await prefs.setString(_currentUserKey, json.encode(user.toJson()));

      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);

      if (userJson == null) return null;

      final userData = json.decode(userJson);
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
