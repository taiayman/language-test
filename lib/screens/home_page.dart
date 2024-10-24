import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:test_windows_students/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_windows_students/screens/listening_test_page.dart';
import 'package:test_windows_students/screens/reading_test_page.dart';
import 'package:test_windows_students/screens/grammar_test_page.dart';
import 'package:test_windows_students/services/test_session_service.dart';
import 'package:test_windows_students/screens/registration_page.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  final TestSessionService _testSessionService = TestSessionService();
  bool _isListeningTestActive = false;
  bool _isReadingTestActive = false;
  bool _isGrammarTestActive = false;  // Add this line
  late StreamSubscription _testStatusSubscription;

  // Add these controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkActiveTests();
    
    // Update status subscription to include grammar
    _testStatusSubscription = _testSessionService.testStatusStream.listen((testStatus) {
      setState(() {
        _isListeningTestActive = testStatus.isListeningActive;
        _isReadingTestActive = testStatus.isReadingActive;
        _isGrammarTestActive = testStatus.isGrammarActive;  // Add this line
      });
    });
  }

  @override
  void dispose() {
    _testStatusSubscription.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _authService.getUserId();
      if (userId != null) {
        final url = Uri.parse('https://${_authService.projectId}-default-rtdb.firebaseio.com/users/$userId.json');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          setState(() {
            _userData = json.decode(response.body);
          });
        } else {
          print('Failed to load user data: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Add check for grammar test
  Future<void> _checkActiveTests() async {
    final isListening = await _testSessionService.isListeningTestActive();
    final isReading = await _testSessionService.isReadingTestActive();
    final isGrammar = await _testSessionService.isGrammarTestActive();
    
    // Add these lines to check completed tests
    final isListeningCompleted = await _testSessionService.isTestCompleted('listening');
    final isReadingCompleted = await _testSessionService.isTestCompleted('reading');
    final isGrammarCompleted = await _testSessionService.isTestCompleted('grammar');
    
    if (mounted) {
      setState(() {
        _isListeningTestActive = isListening;
        _isReadingTestActive = isReading;
        _isGrammarTestActive = isGrammar;
      });
    }
  }

  // Add this method
  Future<bool?> _showNameInputDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2193b0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF2193b0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 32,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Your Name',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2193b0),
                            ),
                          ),
                          Text(
                            'Please provide your full name to start the test',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                
                // First Name Field
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    labelStyle: GoogleFonts.poppins(
                      color: Color(0xFF2193b0),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(0xFF2193b0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Color(0xFF2193b0), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 24),
                
                // Last Name Field
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    labelStyle: GoogleFonts.poppins(
                      color: Color(0xFF2193b0),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(0xFF2193b0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Color(0xFF2193b0), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                SizedBox(height: 40),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Start Test Button
                    ElevatedButton(
                      onPressed: () {
                        if (_firstNameController.text.isNotEmpty && 
                            _lastNameController.text.isNotEmpty) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Start Test',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update the test handlers to check if test is active first

  Future<void> _handleListeningTestStart() async {
    final isActive = await _testSessionService.isListeningTestActive();
    final remainingTime = await _testSessionService.getListeningRemainingTime();

    if (isActive && remainingTime != null && remainingTime > Duration.zero) {
      // Continue existing test without showing dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ListeningTestPage(
            remainingTime: remainingTime,
            firstName: _userData?['firstName'] ?? 'User',  // Use stored user data
            lastName: _userData?['lastName'] ?? '',
          ),
        ),
      );
    } else {
      // Show dialog only for new test
      final shouldStart = await _showNameInputDialog(context);
      if (shouldStart != true) return;

      // Save user info to Firebase
      final userId = _authService.getUserId();
      if (userId != null) {
        final url = Uri.parse('https://${_authService.projectId}-default-rtdb.firebaseio.com/users/$userId.json');
        await http.patch(url, body: json.encode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        }));
      }

      await _testSessionService.startListeningTest();
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ListeningTestPage(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
          ),
        ),
      );
    }
  }

  // Similarly update _handleReadingTestStart
  Future<void> _handleReadingTestStart() async {
    final isActive = await _testSessionService.isReadingTestActive();
    final remainingTime = await _testSessionService.getReadingRemainingTime();
    final isCompleted = await _testSessionService.isTestCompleted('reading');

    if (isCompleted) {
      // If test is completed, do nothing (button will be disabled)
      return;
    }

    if (isActive && remainingTime != null && remainingTime > Duration.zero) {
      // Continue existing test without showing dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReadingTestPage(
            remainingTime: remainingTime,
            firstName: _userData?['firstName'] ?? 'User',
            lastName: _userData?['lastName'] ?? '',
            onTestComplete: () {
              setState(() {
                _isReadingTestActive = false;
              });
            },
          ),
        ),
      );
    } else {
      // Show dialog only for new test
      final shouldStart = await _showNameInputDialog(context);
      if (shouldStart != true) return;

      // Save user info to Firebase
      final userId = _authService.getUserId();
      if (userId != null) {
        final url = Uri.parse('https://${_authService.projectId}-default-rtdb.firebaseio.com/users/$userId.json');
        await http.patch(url, body: json.encode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        }));
      }

      await _testSessionService.startReadingTest();
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ReadingTestPage(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            onTestComplete: () {
              setState(() {
                _isReadingTestActive = false;
              });
            },
          ),
        ),
      );
    }
  }

  // And _handleGrammarTestStart
  Future<void> _handleGrammarTestStart() async {
    final isActive = await _testSessionService.isGrammarTestActive();
    final remainingTime = await _testSessionService.getGrammarRemainingTime();
    final isCompleted = await _testSessionService.isTestCompleted('grammar');

    if (isCompleted) {
      // If test is completed, do nothing (button will be disabled)
      return;
    }

    if (isActive && remainingTime != null && remainingTime > Duration.zero) {
      // Continue existing test without showing dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GrammarTestPage(
            remainingTime: remainingTime,
            firstName: _userData?['firstName'] ?? 'User',
            lastName: _userData?['lastName'] ?? '',
            onTestComplete: () {
              setState(() {
                _isGrammarTestActive = false;
              });
            },
          ),
        ),
      );
    } else {
      // Show dialog only for new test
      final shouldStart = await _showNameInputDialog(context);
      if (shouldStart != true) return;

      // Save user info to Firebase
      final userId = _authService.getUserId();
      if (userId != null) {
        final url = Uri.parse('https://${_authService.projectId}-default-rtdb.firebaseio.com/users/$userId.json');
        await http.patch(url, body: json.encode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        }));
      }

      await _testSessionService.startGrammarTest();
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GrammarTestPage(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            onTestComplete: () {
              setState(() {
                _isGrammarTestActive = false;
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Language Test',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2193b0),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2193b0),
                  Color(0xFF6dd5ed),
                ],
              ),
            ),
          ),
          
          // Main content
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTestCard(
                  title: 'Listening Test',
                  icon: MaterialCommunityIcons.headphones,
                  description: 'Test your listening comprehension skills with audio questions',
                  onTap: _handleListeningTestStart,
                  isActive: _isListeningTestActive,
                ),
                const SizedBox(width: 32),
                _buildTestCard(
                  title: 'Reading Test',
                  icon: MaterialCommunityIcons.book_open_variant,
                  description: 'Evaluate your reading comprehension abilities',
                  onTap: _handleReadingTestStart,
                  isActive: _isReadingTestActive,
                ),
                const SizedBox(width: 32),
                _buildTestCard(
                  title: 'Grammar Test',
                  icon: MaterialCommunityIcons.format_text,
                  description: 'Check your grammar and language structure knowledge',
                  onTap: _handleGrammarTestStart,  // Update this line
                  isActive: _isGrammarTestActive,  // Update this line
                ),
              ],
            ),
          ),

          // Logout button
          Positioned(
            left: 24,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutConfirmation(context),
              icon: Icon(
                Icons.logout,
                color: Colors.white,
              ),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Color(0xFF2193b0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    String testType = title.toLowerCase().split(' ')[0];

    return FutureBuilder<bool>(
      future: _testSessionService.isTestCompleted(testType),
      builder: (context, snapshot) {
        bool isCompleted = snapshot.data ?? false;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Card(
            elevation: 12, // Increased elevation
            shadowColor: Colors.black26, // Softer shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32), // More rounded corners
            ),
            child: Container(
              width: 360, // Slightly wider
              padding: const EdgeInsets.all(32), // More padding
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: isCompleted
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green.shade300
                      : isActive
                          ? Color(0xFF2193b0).withOpacity(0.3)
                          : Colors.grey.shade200,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (isCompleted
                              ? Colors.green
                              : isActive
                                  ? Color(0xFF2193b0)
                                  : Colors.grey)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 36, // Larger icon
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? Color(0xFF2193b0)
                                  : Colors.grey,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 26, // Larger font
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.green
                                      : isActive
                                          ? Color(0xFF2193b0)
                                          : Colors.grey,
                                ),
                              ),
                              if (isCompleted || isActive)
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isCompleted
                                            ? Colors.green
                                            : Color(0xFF2193b0))
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : Icons.timer,
                                        color: isCompleted
                                            ? Colors.green
                                            : Color(0xFF2193b0),
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        isCompleted ? 'Completed' : 'In Progress',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: isCompleted
                                              ? Colors.green
                                              : Color(0xFF2193b0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5, // Better line height
                    ),
                  ),
                  SizedBox(height: 32), // More spacing
                  ElevatedButton(
                    onPressed: isCompleted ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // More rounded
                      ),
                      elevation: 4, // Add elevation to button
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? null
                            : LinearGradient(
                                colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16), // Taller button
                        alignment: Alignment.center,
                        child: Text(
                          isCompleted
                              ? 'Test Completed'
                              : isActive
                                  ? 'Continue Test'
                                  : 'Start Test',
                          style: GoogleFonts.poppins(
                            fontSize: 18, // Larger font
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? Colors.grey : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add this new method for the enhanced logout confirmation dialog
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Confirm Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                SizedBox(height: 16),
                
                // Message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Are you sure you want to logout?',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Any active test progress will be lost and cannot be recovered.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Logout Button
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          
                          // Reset completion status for all tests
                          await prefs.remove('listening_test_completed');
                          await prefs.remove('reading_test_completed');
                          await prefs.remove('grammar_test_completed');
                          
                          // Clear all test sessions
                          await _testSessionService.clearAllSessions();
                          
                          // Perform logout
                          await _authService.signOut();
                          
                          if (!mounted) return;
                          
                          // Navigate to login/registration page
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => RegistrationPage()),
                            (route) => false,
                          );
                        } catch (e) {
                          print('Error during logout: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      // Logout logic is now handled in the button's onPressed
    }
  }
}
