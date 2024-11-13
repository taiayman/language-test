import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:alc_eljadida_tests/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alc_eljadida_tests/screens/listening_test_page.dart';
import 'package:alc_eljadida_tests/screens/reading_test_page.dart';
import 'package:alc_eljadida_tests/screens/grammar_test_page.dart';
import 'package:alc_eljadida_tests/services/test_session_service.dart';
import 'package:alc_eljadida_tests/screens/registration_page.dart';
import 'dart:ui';
import 'package:alc_eljadida_tests/screens/test_results_page.dart';
import 'package:alc_eljadida_tests/services/firestore_service.dart';
import 'package:alc_eljadida_tests/screens/dashboard_page.dart';
import 'package:alc_eljadida_tests/widgets/video_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic> _userData = {};
  final TestSessionService _testSessionService = TestSessionService();
  bool _isListeningTestActive = false;
  bool _isReadingTestActive = false;
  bool _isGrammarTestActive = false;
  late StreamSubscription _testStatusSubscription;

  bool _allTestsCompleted = false;
  bool _resultsAlreadySaved = false;
  bool _isSaving = false;
  bool _hasCheckedResults = false;

  Duration _listeningTestDuration = Duration.zero;
  int _listeningTestScore = 0;
  Duration _readingTestDuration = Duration.zero;
  int _readingTestScore = 0;
  Duration _grammarTestDuration = Duration.zero;
  int _grammarTestScore = 0;

  static const String _SAVE_STATUS_KEY = 'results_save_status';
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _loadUserData();
    _checkActiveTests();
    
    _testStatusSubscription = _testSessionService.testStatusStream.listen((testStatus) {
      if (mounted) {
        setState(() {
          _isListeningTestActive = testStatus.isListeningActive;
          _isReadingTestActive = testStatus.isReadingActive;
          _isGrammarTestActive = testStatus.isGrammarActive;
        });
      }
      _checkTestsAndSave();
    });
  }

  Future<void> _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSessionId = prefs.getString('current_session_id') ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString('current_session_id', _currentSessionId!);
  }

  @override
  void dispose() {
    _testStatusSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _checkActiveTests() async {
    final isListening = await _testSessionService.isListeningTestActive();
    final isReading = await _testSessionService.isReadingTestActive();
    final isGrammar = await _testSessionService.isGrammarTestActive();
    
    if (mounted) {
      setState(() {
        _isListeningTestActive = isListening;
        _isReadingTestActive = isReading;
        _isGrammarTestActive = isGrammar;
      });
    }
  }

  Future<void> _checkTestsAndSave() async {
    if (!mounted || _isSaving) return;

    final prefs = await SharedPreferences.getInstance();
    final isListeningCompleted = await _testSessionService.isTestCompleted('listening');
    final isReadingCompleted = await _testSessionService.isTestCompleted('reading');
    final isGrammarCompleted = await _testSessionService.isTestCompleted('grammar');

    final allCompleted = isListeningCompleted && isReadingCompleted && isGrammarCompleted;
    final saveStatus = prefs.getString(_SAVE_STATUS_KEY);

    if (allCompleted && saveStatus != _currentSessionId) {
      setState(() {
        _isSaving = true;
      });

      try {
        final listeningRawScore = prefs.getInt('listening_test_score') ?? 0;
        final readingRawScore = prefs.getInt('reading_test_score') ?? 0;
        final grammarRawScore = prefs.getInt('grammar_test_score') ?? 0;
        
        final listeningDuration = Duration(
          seconds: prefs.getInt('listening_test_duration') ?? 0
        );
        final readingDuration = Duration(
          seconds: prefs.getInt('reading_test_duration') ?? 0
        );
        final grammarDuration = Duration(
          seconds: prefs.getInt('grammar_test_duration') ?? 0
        );

        final listeningTotalQuestions = prefs.getInt('listening_total_questions') ?? 20;
        final readingTotalQuestions = prefs.getInt('reading_total_questions') ?? 20;
        final grammarTotalQuestions = prefs.getInt('grammar_total_questions') ?? 20;

        final userData = await _authService.getUserData();
        
        bool isParentPhone = false;
        try {
          isParentPhone = userData['isParentPhone'] == true || 
                         userData['isParentPhone'] == 'true';
        } catch (e) {
          print('Error parsing isParentPhone: $e');
        }

        bool isExistingStudent = false;
        try {
          isExistingStudent = userData['isExistingStudent'] == true || 
                             userData['isExistingStudent'] == 'true';
        } catch (e) {
          print('Error parsing isExistingStudent: $e');
        }

        await _firestoreService.saveBulkResults(
          firstName: userData['firstName']?.toString() ?? '',
          lastName: userData['lastName']?.toString() ?? '',
          birthDate: userData['birthDate']?.toString(),
          address: userData['address']?.toString(),
          phone: userData['phone']?.toString() ?? '',
          isParentPhone: isParentPhone,
          email: userData['email']?.toString() ?? '',
          cin: userData['cin']?.toString(),
          isExistingStudent: isExistingStudent,
          schoolCode: userData['schoolCode']?.toString() ?? '',
          listeningRawScore: listeningRawScore,
          listeningDuration: listeningDuration,
          readingRawScore: readingRawScore,
          readingDuration: readingDuration,
          grammarRawScore: grammarRawScore,
          grammarDuration: grammarDuration,
          timestamp: DateTime.now(),
          listeningTotalQuestions: listeningTotalQuestions,
          readingTotalQuestions: readingTotalQuestions,
          grammarTotalQuestions: grammarTotalQuestions,
        );

        await prefs.setString(_SAVE_STATUS_KEY, _currentSessionId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test results saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error saving results: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save results: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _allTestsCompleted = true;
          });
        }
      }
    } else {
      setState(() {
        _allTestsCompleted = allCompleted;
      });
    }
  }

  Future<Map<String, String>?> _getStoredOrInputName() async {
    if (_userData['firstName'] != null && _userData['lastName'] != null) {
      return {
        'firstName': _userData['firstName']!,
        'lastName': _userData['lastName']!,
      };
    }
    return null;
  }

  Future<void> _handleListeningTestStart() async {
    try {
      // Show video instructions first
      final shouldStartTest = await _showTestInstructions(context, 'listening');
      if (!shouldStartTest || !mounted) return;

      print('\n=== Starting Listening Test Handler ===');
      print('Checking test session status...');
      
      final isActive = await _testSessionService.isListeningTestActive();
      print('Test Active Status: $isActive');
      
      final remainingTime = await _testSessionService.getListeningRemainingTime();
      print('Remaining Time: ${remainingTime?.toString() ?? 'null'}');

      if (isActive && remainingTime != null && remainingTime > Duration.zero) {
        print('\n=== Resuming Active Test Session ===');
        print('Remaining Time: ${remainingTime.toString()}');
        print('Current User Data:');
        print('First Name: ${_userData['firstName'] ?? 'User'}');
        print('Last Name: ${_userData['lastName'] ?? ''}');

        if (!mounted) {
          print('Widget no longer mounted, canceling navigation');
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListeningTestPage(
              remainingTime: remainingTime,
              firstName: _userData['firstName'] ?? 'User',
              lastName: _userData['lastName'] ?? '',
              onTestComplete: (duration, score) async {
                print('\n=== Test Completion Callback ===');
                print('Test Duration: ${duration.toString()}');
                print('Raw Score: $score');
                print('Updating state variables...');
                
                setState(() {
                  _isListeningTestActive = false;
                  _listeningTestDuration = duration;
                  _listeningTestScore = score;
                });
                
                print('Starting test completion checks...');
                await _checkTestsAndSave();
                print('Test completion process finished');
              },
            ),
          ),
        );
      } else {
        print('\n=== Starting New Test Session ===');
        print('Requesting user data...');
        
        final userData = await _getStoredOrInputName();
        if (userData == null) {
          print('User data collection cancelled or failed');
          return;
        }
        
        print('User Data Collected:');
        print('First Name: ${userData['firstName']}');
        print('Last Name: ${userData['lastName']}');

        print('Initializing new test session...');
        await _testSessionService.startListeningTest();
        print('Test session initialized successfully');

        if (!mounted) {
          print('Widget no longer mounted, canceling navigation');
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListeningTestPage(
              firstName: userData['firstName']!,
              lastName: userData['lastName']!,
              onTestComplete: (duration, score) async {
                print('\n=== New Test Completion Callback ===');
                print('Test Duration: ${duration.toString()}');
                print('Raw Score: $score');
                print('Updating state variables...');
                
                setState(() {
                  _isListeningTestActive = false;
                  _listeningTestDuration = duration;
                  _listeningTestScore = score;
                });
                
                print('Starting test completion checks...');
                await _checkTestsAndSave();
                print('Test completion process finished');
              },
            ),
          ),
        );
      }
      
      print('=== Listening Test Handler Completed Successfully ===\n');
      
    } catch (e, stackTrace) {
      print('\n=== Error in Listening Test Handler ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('=== End Error Report ===\n');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start listening test: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(40),
          ),
        );
      }
    }
  }

  Future<void> _handleReadingTestStart() async {
    try {
      // Show video instructions first
      final shouldStartTest = await _showTestInstructions(context, 'reading');
      if (!shouldStartTest || !mounted) return;

      final isActive = await _testSessionService.isReadingTestActive();
      final remainingTime = await _testSessionService.getReadingRemainingTime();
      final isCompleted = await _testSessionService.isTestCompleted('reading');

      if (isCompleted) return;

      if (isActive && remainingTime != null && remainingTime > Duration.zero) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReadingTestPage(
              remainingTime: remainingTime,
              firstName: _userData['firstName'] ?? 'User',
              lastName: _userData['lastName'] ?? '',
              onTestComplete: (duration, score) async {
                setState(() {
                  _isReadingTestActive = false;
                  _readingTestDuration = duration;
                  _readingTestScore = score;
                });
                await _checkTestsAndSave();
              },
            ),
          ),
        );
      } else {
        final userData = await _getStoredOrInputName();
        if (userData == null) return;

        await _testSessionService.startReadingTest();
        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReadingTestPage(
              firstName: userData['firstName']!,
              lastName: userData['lastName']!,
              onTestComplete: (duration, score) async {
                setState(() {
                  _isReadingTestActive = false;
                  _readingTestDuration = duration;
                  _readingTestScore = score;
                });
                await _checkTestsAndSave();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in Reading Test Handler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start reading test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGrammarTestStart() async {
    try {
      // Show video instructions first
      final shouldStartTest = await _showTestInstructions(context, 'grammar');
      if (!shouldStartTest || !mounted) return;

      final isActive = await _testSessionService.isGrammarTestActive();
      final remainingTime = await _testSessionService.getGrammarRemainingTime();
      final isCompleted = await _testSessionService.isTestCompleted('grammar');

      if (isCompleted) return;

      if (isActive && remainingTime != null && remainingTime > Duration.zero) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GrammarTestPage(
              remainingTime: remainingTime,
              firstName: _userData['firstName'] ?? 'User',
              lastName: _userData['lastName'] ?? '',
              onTestComplete: (duration, score) async {
                setState(() {
                  _isGrammarTestActive = false;
                  _grammarTestDuration = duration;
                  _grammarTestScore = score;
                });
                await _checkTestsAndSave();
              },
            ),
          ),
        );
      } else {
        final userData = await _getStoredOrInputName();
        if (userData == null) return;

        await _testSessionService.startGrammarTest();
        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GrammarTestPage(
              firstName: userData['firstName']!,
              lastName: userData['lastName']!,
              onTestComplete: (duration, score) async {
                setState(() {
                  _isGrammarTestActive = false;
                  _grammarTestDuration = duration;
                  _grammarTestScore = score;
                });
                await _checkTestsAndSave();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in Grammar Test Handler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start grammar test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('listening_test_completed');
      await prefs.remove('reading_test_completed');
      await prefs.remove('grammar_test_completed');
      
      await prefs.remove('listening_test_score');
      await prefs.remove('reading_test_score');
      await prefs.remove('grammar_test_score');
      
      await prefs.remove('listening_test_duration');
      await prefs.remove('reading_test_duration');
      await prefs.remove('grammar_test_duration');
      
      await prefs.remove('current_student_first_name');
      await prefs.remove('current_student_last_name');
      
      await prefs.remove('current_session_id');
      await prefs.remove(_SAVE_STATUS_KEY);
      
      await prefs.remove('current_question_index');
      await prefs.remove('user_answers');
      
      await _testSessionService.clearAllSessions();
      
      await _authService.signOut();
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

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
                
                Text(
                  'Confirm Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                SizedBox(height: 16),
                
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
                        'All test progress and session data will be reset.',
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
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                    
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _resetAllData();
                          
                          if (!mounted) return;
                          
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => RegistrationPage()),
                            (route) => false,
                          );
                        } catch (e) {
                          print('Error during logout: $e');
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error logging out. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
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
  }

  Future<Map<String, bool>> _getTestCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'listening_test_completed': prefs.getBool('listening_test_completed') ?? false,
      'reading_test_completed': prefs.getBool('reading_test_completed') ?? false,
      'grammar_test_completed': prefs.getBool('grammar_test_completed') ?? false,
    };
  }

  bool _areAllTestsCompleted(
    bool listeningCompleted, 
    bool readingCompleted, 
    bool grammarCompleted
  ) {
    return listeningCompleted && readingCompleted && grammarCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future: _getTestCompletionStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final bool listeningCompleted = snapshot.data!['listening_test_completed'] ?? false;
        final bool readingCompleted = snapshot.data!['reading_test_completed'] ?? false;
        final bool grammarCompleted = snapshot.data!['grammar_test_completed'] ?? false;
        
        final bool allTestsCompleted = _areAllTestsCompleted(
          listeningCompleted, 
          readingCompleted, 
          grammarCompleted
        );

        // Add automatic navigation when all tests are completed
        if (allTestsCompleted && !_hasCheckedResults) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _hasCheckedResults = true);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TestResultsPage(
                  firstName: _userData['firstName'] ?? '',
                  lastName: _userData['lastName'] ?? '',
                ),
              ),
            ).then((_) => _checkTestsAndSave());
          });
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
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
                      onTap: _handleGrammarTestStart,
                      isActive: _isGrammarTestActive,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: allTestsCompleted 
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TestResultsPage(
                        firstName: _userData['firstName'] ?? '',
                        lastName: _userData['lastName'] ?? '',
                      ),
                    ),
                  ).then((_) => _checkTestsAndSave());
                },
                icon: Icon(Icons.assessment_outlined, color: Colors.white),
                label: Text(
                  'See Results',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Color(0xFF2193b0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                isExtended: true,
                extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ) 
            : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildTestCard({
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return FutureBuilder<bool>(
      future: _testSessionService.isTestCompleted(title.toLowerCase().split(' ')[0]),
      builder: (context, snapshot) {
        bool isCompleted = snapshot.data ?? false;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Card(
            elevation: 12,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(32),
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
                          size: 36,
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
                                  fontSize: 26,
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
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isCompleted ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
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
                        padding: EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          isCompleted
                              ? 'Test Completed'
                              : isActive
                                  ? 'Continue Test'
                                  : 'Start Test',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'ALC El Jadida',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2193b0),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: const Color(0xFF2193b0),
              size: 28,
            ),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }

  Future<void> _resubmitData(BuildContext context) async {
    try {
      setState(() => _isSaving = true);
      print('\n=== Starting Data Resubmission ===');

      final prefs = await SharedPreferences.getInstance();
      
      // Debug logging for test scores
      print('\n=== Test Scores ===');
      final listeningScore = prefs.getInt('listening_test_score') ?? 0;
      print('Listening Score: $listeningScore');
      final readingScore = prefs.getInt('reading_test_score') ?? 0;
      print('Reading Score: $readingScore');
      final grammarScore = prefs.getInt('grammar_test_score') ?? 0;
      print('Grammar Score: $grammarScore');
      
      // Debug logging for durations
      print('\n=== Test Durations ===');
      final listeningDuration = Duration(
        seconds: prefs.getInt('listening_test_duration') ?? 0
      );
      print('Listening Duration: $listeningDuration');
      final readingDuration = Duration(
        seconds: prefs.getInt('reading_test_duration') ?? 0
      );
      print('Reading Duration: $readingDuration');
      final grammarDuration = Duration(
        seconds: prefs.getInt('grammar_test_duration') ?? 0
      );
      print('Grammar Duration: $grammarDuration');

      // Debug logging for question counts
      print('\n=== Question Counts ===');
      final listeningTotalQuestions = prefs.getInt('listening_total_questions') ?? 20;
      print('Listening Questions: $listeningTotalQuestions');
      final readingTotalQuestions = prefs.getInt('reading_total_questions') ?? 20;
      print('Reading Questions: $readingTotalQuestions');
      final grammarTotalQuestions = prefs.getInt('grammar_total_questions') ?? 20;
      print('Grammar Questions: $grammarTotalQuestions');

      print('\n=== Fetching User Data ===');
      final userData = await _authService.getUserData();
      print('User Data Retrieved: ${userData.toString()}');

      // Parse boolean values with debug logging
      print('\n=== Parsing Boolean Values ===');
      bool isParentPhone = false;
      try {
        isParentPhone = userData['isParentPhone'] == true || 
                       userData['isParentPhone'] == 'true';
        print('isParentPhone parsed as: $isParentPhone');
      } catch (e) {
        print('Error parsing isParentPhone: $e');
      }

      bool isExistingStudent = false;
      try {
        isExistingStudent = userData['isExistingStudent'] == true || 
                           userData['isExistingStudent'] == 'true';
        print('isExistingStudent parsed as: $isExistingStudent');
      } catch (e) {
        print('Error parsing isExistingStudent: $e');
      }

      print('\n=== Submitting to Firestore ===');
      await _firestoreService.saveBulkResults(
        firstName: userData['firstName']?.toString() ?? '',
        lastName: userData['lastName']?.toString() ?? '',
        birthDate: userData['birthDate']?.toString(),
        address: userData['address']?.toString(),
        phone: userData['phone']?.toString() ?? '',
        isParentPhone: isParentPhone,
        email: userData['email']?.toString() ?? '',
        cin: userData['cin']?.toString(),
        isExistingStudent: isExistingStudent,
        schoolCode: userData['schoolCode']?.toString() ?? '',
        listeningRawScore: listeningScore,
        listeningDuration: listeningDuration,
        readingRawScore: readingScore,
        readingDuration: readingDuration,
        grammarRawScore: grammarScore,
        grammarDuration: grammarDuration,
        timestamp: DateTime.now(),
        listeningTotalQuestions: listeningTotalQuestions,
        readingTotalQuestions: readingTotalQuestions,
        grammarTotalQuestions: grammarTotalQuestions,
      );
      print('Data successfully submitted to Firestore');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test results resubmitted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(40),
        ),
      );
      print('\n=== Data Resubmission Completed Successfully ===');
      
    } catch (e, stackTrace) {
      print('\n=== Error During Data Resubmission ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resubmit data: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(40),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        print('\n=== Resubmission Process Completed ===');
      }
    }
  }

  Future<bool> _showTestInstructions(BuildContext context, String testType) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return VideoOverlay(
          videoType: testType,
          onClose: () {
            Navigator.of(context).pop(true);
          },
        );
      },
    ) ?? false;
  }
}
