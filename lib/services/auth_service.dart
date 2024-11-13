import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _apiKey = 'AIzaSyAyNWHQXz89YL02R4RrSun80w1C2yLsTRY';
  final String projectId = 'testapp-a0f67';
  final String _baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';

  Future<void> saveAuthToken(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);
    await prefs.setString('last_login', DateTime.now().toIso8601String());
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final lastLogin = prefs.getString('last_login');
    if (lastLogin != null) {
      final loginDate = DateTime.parse(lastLogin);
      final now = DateTime.now();
      if (now.difference(loginDate).inHours > 1) {
        await signOut();
        return false;
      }
    }

    return true;
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl:signInWithPassword?key=$_apiKey'),
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await saveAuthToken(data['idToken'], data['localId']);
        return data;
      } else {
        final errorResponse = json.decode(response.body);
        final errorMessage = _getReadableErrorMessage(errorResponse['error']['message']);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  String _getReadableErrorMessage(String firebaseError) {
    switch (firebaseError) {
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password. Please try again.';
      case 'EMAIL_NOT_FOUND':
        return 'No account found with this email.';
      case 'INVALID_PASSWORD':
        return 'Incorrect password.';
      case 'USER_DISABLED':
        return 'This account has been disabled.';
      default:
        return 'An error occurred during sign in. Please try again.';
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('last_login');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
  }

  Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login', DateTime.now().toIso8601String());
  }

  Future<void> saveUserData(
    String firstName, 
    String lastName, 
    Map<String, dynamic> additionalData
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_first_name', firstName);
    await prefs.setString('user_last_name', lastName);
    
    // Save additional data
    for (var entry in additionalData.entries) {
      if (entry.value is String) {
        await prefs.setString('user_${entry.key}', entry.value as String);
      } else if (entry.value is bool) {
        await prefs.setBool('user_${entry.key}', entry.value as bool);
      } else if (entry.value is int) {
        await prefs.setInt('user_${entry.key}', entry.value as int);
      }
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString('user_first_name'),
      'lastName': prefs.getString('user_last_name'),
      'birthDate': prefs.getString('user_birthDate'),
      'address': prefs.getString('user_address'),
      'phone': prefs.getString('user_phone'),
      'isParentPhone': prefs.getBool('user_isParentPhone'),
      'email': prefs.getString('user_email'),
      'cin': prefs.getString('user_cin'),
      'isExistingStudent': prefs.getBool('user_isExistingStudent'),
    };
  }
}
