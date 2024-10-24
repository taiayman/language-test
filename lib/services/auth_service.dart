import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String _apiKey = 'AIzaSyAyNWHQXz89YL02R4RrSun80w1C2yLsTRY';
  final String projectId = 'testapp-a0f67'; // Make this accessible
  final String _baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';

  // Sign in with email and password
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
        return json.decode(response.body);
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

  // Register with email and password
  Future<Map<String, dynamic>> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl:signUp?key=$_apiKey'),
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = 'Failed to sign up: ${response.body}';
        print(error); // Log to console
        throw Exception(error);
      }
    } catch (e) {
      print('Error in signUpWithEmailAndPassword: $e'); // Log to console
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // For Firebase REST API, sign out is typically handled on the client side
    // by removing the stored authentication token
    // You may want to clear any stored user data or tokens here
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl:sendOobCode?key=$_apiKey'),
        body: json.encode({
          'email': email,
          'requestType': 'PASSWORD_RESET',
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = 'Failed to send password reset email: ${response.body}';
        print(error); // Log to console
        throw Exception(error);
      }
    } catch (e) {
      print('Error in sendPasswordResetEmail: $e'); // Log to console
      rethrow;
    }
  }

  // Check if user is signed in
  bool isSignedIn() {
    // This would typically involve checking if you have a valid token stored
    // For now, we'll return false as a placeholder
    return false;
  }

  // Get user id
  String? getUserId() {
    // This should return the ID of the currently logged-in user
    // You might need to store this ID when the user logs in
    // For now, let's return null as a placeholder
    return null;
  }

  // Stream of auth state changes
  // Note: Implementing this with REST API is not straightforward
  // You might need to use a different approach for real-time auth state
  Stream<dynamic> get authStateChanges => Stream.empty();
}
