import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_windows_students/screens/grammar_test_results_page.dart';
import 'package:test_windows_students/services/test_session_service.dart';  // Update to correct path
import 'package:test_windows_students/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_windows_students/services/test_results_service.dart';
import 'package:test_windows_students/models/test_result.dart';

class GrammarTestPage extends StatefulWidget {
  final Duration? remainingTime;
  final String firstName;
  final String lastName;
  final VoidCallback? onTestComplete;
  
  const GrammarTestPage({
    Key? key, 
    this.remainingTime,
    required this.firstName,
    required this.lastName,
    this.onTestComplete,
  }) : super(key: key);

  @override
  _GrammarTestPageState createState() => _GrammarTestPageState();
}

class _GrammarTestPageState extends State<GrammarTestPage> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  final int _totalTimeInMinutes = 15;
  late Timer _timer;
  late Duration _remainingTime;
  double _progress = 1.0;
  final TestSessionService _testSessionService = TestSessionService();
  final Map<int, String> _userAnswers = {};  // Add this line

  // Example grammar questions with different types
  final List<Map<String, dynamic>> _questions = [
    {
      'type': 'multiple_choice',
      'question': 'Choose the correct form of the verb:',
      'sentence': 'If I _____ rich, I would buy a house.',
      'options': ['am', 'were', 'was', 'be'],
      'correctAnswer': 'were',
      'explanation': 'In second conditional sentences, we use "were" for all subjects.'
    },
    {
      'type': 'error_identification',
      'question': 'Identify the error in this sentence:',
      'sentence': 'Neither of the students have completed their assignments.',
      'options': [
        'Neither of',
        'the students',
        'have completed',
        'their assignments'
      ],
      'correctAnswer': 'have completed',
      'explanation': '"Neither" is singular, so it should be "has completed".'
    },
    {
      'type': 'sentence_improvement',
      'question': 'Choose the best way to improve this sentence:',
      'sentence': 'The book was very interesting and I liked it very much.',
      'options': [
        'The book was very interesting and I liked it a lot.',
        'I found the book fascinating.',
        'The book had much interest for me.',
        'It was a very interesting book that I liked.'
      ],
      'correctAnswer': 'I found the book fascinating.',
      'explanation': 'This version is more concise and avoids repetition.'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize remaining time from widget parameter if available
    _remainingTime = widget.remainingTime ?? Duration(minutes: _totalTimeInMinutes);
    _initializeTimer();
  }

  Future<void> _initializeTimer() async {
    final remainingTime = await _testSessionService.getGrammarRemainingTime();
    if (remainingTime != null) {
      setState(() {
        _remainingTime = remainingTime;
        _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
      });
    } else {
      // Start new test
      await _testSessionService.startGrammarTest();
      setState(() {
        _remainingTime = Duration(minutes: _totalTimeInMinutes);
        _progress = 1.0;
      });
    }
    _startTimer();
  }

  void _startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) async {
      final remainingTime = await _testSessionService.getGrammarRemainingTime();
      
      if (remainingTime == null || remainingTime.inSeconds <= 0) {
        _timer.cancel();
        _handleTimeUp();
        return;
      }

      if (mounted) {  // Add mounted check
        setState(() {
          _remainingTime = remainingTime;
          _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
        });
      }
    });
  }

  void _handleTimeUp() async {
    _timer.cancel();
    await _testSessionService.endGrammarTest();
    await _testSessionService.markTestAsCompleted('grammar');
    
    if (!mounted) return;

    // Calculate score
    int correctAnswers = 0;
    _questions.asMap().forEach((index, question) {
      if (_userAnswers[index] == question['correctAnswer']) {
        correctAnswers++;
      }
    });

    // Get user data
    final AuthService _authService = AuthService();
    final userId = _authService.getUserId();
    String firstName = 'User';  // Default value
    String lastName = '';
    
    if (userId != null) {
      try {
        final url = Uri.parse('https://${_authService.projectId}-default-rtdb.firebaseio.com/users/$userId.json');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          firstName = userData['firstName'] ?? 'User';
          lastName = userData['lastName'] ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }

    if (!mounted) return;

    // Navigate to results page with all required parameters
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GrammarTestResultsPage(
          score: correctAnswers,
          totalQuestions: _questions.length,
          firstName: firstName,
          lastName: lastName,
        ),
      ),
    );
  }

  int _calculateScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i]['correctAnswer']) {
        score++;
      }
    }
    return score;
  }

  void _handleTestCompletion() async {
    await _testSessionService.markTestAsCompleted('grammar');
    
    // Calculate score
    int score = _calculateScore();
  

    // Get user data
    final AuthService _authService = AuthService();
    final userId = _authService.getUserId();
    String firstName = 'User';  // Default value
    String lastName = '';
    
    if (userId != null) {
      try {
        final url = Uri.parse('https://${_authService.projectId}-default-rtdb.firebaseio.com/users/$userId.json');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          firstName = userData['firstName'] ?? 'User';
          lastName = userData['lastName'] ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }

    if (!mounted) return;

    // Navigate to results page with all required parameters
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GrammarTestResultsPage(
          score: score,
          totalQuestions: _questions.length,
          firstName: firstName,
          lastName: lastName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF2193b0),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(
              MaterialCommunityIcons.format_text,
              color: Color(0xFF2193b0),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Grammar Test',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2193b0),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF2193b0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Color(0xFF2193b0),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Help',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF2193b0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        toolbarHeight: 72, // Increased height for desktop
      ),
      body: Column(
        children: [
          // Main content - updated layout
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0), // Reduced padding
                child: Row(
                  children: [
                    // Question Card (Left side)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch, // Makes children match parent width
                        children: [
                          // Question Card (Upper)
                          Expanded(
                            flex: 4,
                            child: Card(
                              margin: EdgeInsets.zero, // Removes default card margin
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      _questions[_currentQuestionIndex]['question'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2193b0),
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Container(
                                      width: double.infinity, // Makes container match parent width
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _questions[_currentQuestionIndex]['sentence'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Timer Card (Lower)
                          Card(
                            margin: EdgeInsets.zero, // Removes default card margin
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: _remainingTime.inMinutes < 5 
                                        ? Colors.red 
                                        : Color(0xFF2193b0),
                                    size: 28,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Time Remaining',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _formatTime(_remainingTime),
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: _remainingTime.inMinutes < 5 
                                                ? Colors.red 
                                                : Color(0xFF2193b0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: _progress,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _remainingTime.inMinutes < 5 
                                              ? Colors.red 
                                              : Color(0xFF2193b0),
                                        ),
                                        minHeight: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 32),
                    // Options Card (Right side)
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0), // Reduced padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Select Your Answer',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2193b0),
                                ),
                              ),
                              SizedBox(height: 24),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _questions[_currentQuestionIndex]['options'].length,
                                  itemBuilder: (context, index) {
                                    return _buildOptionButton(
                                      _questions[_currentQuestionIndex]['options'][index]
                                    );
                                  },
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                onPressed: _selectedAnswer != null
                                    ? () async {
                                        if (_currentQuestionIndex < _questions.length - 1) {
                                          // Continue to next question
                                          setState(() {
                                            if (_selectedAnswer != null) {  // Add null check
                                              _userAnswers[_currentQuestionIndex] = _selectedAnswer!;  // Use ! operator
                                            }
                                            _currentQuestionIndex++;
                                            _selectedAnswer = null;
                                          });
                                        } else {
                                          // Save last answer
                                          if (_selectedAnswer != null) {  // Add null check
                                            _userAnswers[_currentQuestionIndex] = _selectedAnswer!;  // Use ! operator
                                          }
                                          
                                          // Calculate score
                                          int score = 0;
                                          _userAnswers.forEach((index, answer) {
                                            if (answer == _questions[index]['correctAnswer']) {
                                              score++;
                                            }
                                          });
                                          
                                          final authService = AuthService();
                                          final testResultsService = TestResultsService(authService.projectId);
                                          
                                          final result = TestResult(
                                            userId: authService.getUserId() ?? 'anonymous',
                                            firstName: widget.firstName,
                                            lastName: widget.lastName,
                                            testType: 'Grammar Test',
                                            score: score,
                                            totalQuestions: _questions.length,
                                            timestamp: DateTime.now(),
                                          );
                                          
                                          try {
                                            // Stop the timer
                                            _timer.cancel();
                                            
                                            // Mark test as completed
                                            await _testSessionService.markTestAsCompleted('grammar');
                                            
                                            // Save test result
                                            await testResultsService.saveTestResult(result);
                                            
                                            if (!mounted) return;
                                            
                                            // Update UI to show completion
                                            widget.onTestComplete?.call();
                                            
                                            // Navigate to results page
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) => GrammarTestResultsPage(
                                                  score: score,
                                                  totalQuestions: _questions.length,
                                                  firstName: widget.firstName,
                                                  lastName: widget.lastName,
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to save test result')),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Container(
                                    height: 56,
                                    alignment: Alignment.center,
                                    child: Text(
                                      _currentQuestionIndex < _questions.length - 1
                                          ? 'Next Question'
                                          : 'Finish Test',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the option button to match reading screen style
  Widget _buildOptionButton(String option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _selectedAnswer == option 
                ? Color(0xFF2193b0) 
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24), // Increased radius
          onTap: () {
            setState(() {
              _selectedAnswer = option;
            });
          },
          child: Container(
            padding: EdgeInsets.all(24), // Increased padding
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: _selectedAnswer == option
                  ? LinearGradient(
                      colors: [
                        Color(0xFF2193b0).withOpacity(0.1),
                        Color(0xFF6dd5ed).withOpacity(0.1)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                  )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 28, // Increased size
                  height: 28, // Increased size
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedAnswer == option 
                          ? Color(0xFF2193b0) 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: _selectedAnswer == option 
                        ? Color(0xFF2193b0) 
                        : Colors.transparent,
                  ),
                  child: _selectedAnswer == option
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 20), // Increased spacing
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 18, // Increased font size
                      color: _selectedAnswer == option 
                          ? Color(0xFF2193b0) 
                          : Colors.black87,
                      fontWeight: _selectedAnswer == option 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Update the answer selection method
  void _handleAnswerSelection(String answer) {
    setState(() {
      _selectedAnswer = answer;
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }
}
