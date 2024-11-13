import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alc_eljadida_tests/services/test_session_service.dart';
import 'package:alc_eljadida_tests/services/auth_service.dart';
import 'package:alc_eljadida_tests/services/test_results_service.dart';
import 'package:alc_eljadida_tests/models/test_result.dart';
import 'package:alc_eljadida_tests/services/firestore_service.dart';
import 'package:alc_eljadida_tests/screens/home_page.dart';
import 'package:alc_eljadida_tests/services/score_calculator.dart';

class GrammarTestPage extends StatefulWidget {
  final Duration? remainingTime;
  final String firstName;
  final String lastName;
  final Function(Duration, int)? onTestComplete;
  
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
  final int _totalTimeInMinutes = 15;  // Test duration in minutes
  late Timer _timer;
  Duration _remainingTime = Duration(minutes: 15);  // Also update this to match
  double _progress = 1.0;
  final TestSessionService _testSessionService = TestSessionService();
  final Map<int, String> _userAnswers = {};
  DateTime _startTime = DateTime.now();

  final List<Map<String, dynamic>> _questions = [
  {
    'question': 'Complete the sentence:',
    'sentence': 'My daughter sometimes _____ to school with her friends.',
    'options': ['walk', 'walks', 'walking', 'not walk'],
    'correctAnswer': 'walks'
  },
  {
    'question': 'Complete the question:',
    'sentence': '_____ eat dinner on Sundays?',
    'options': [
      'Where your family',
      'How is your family',
      'When your family do',
      'What time does your family'
    ],
    'correctAnswer': 'What time does your family'
  },
  {
    'question': 'Choose the correct form:',
    'sentence': '_____ a lot of people in the park today.',
    'options': ['There', 'There\'s', 'There are', 'There is no'],
    'correctAnswer': 'There are'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': '_____, but I\'m not very good.',
    'options': [
      'I can play the guitar',
      'I don\'t play the guitar',
      'I play the guitar very well',
      'I can\'t play the guitar well'
    ],
    'correctAnswer': 'I can play the guitar'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'We had a nice vacation. The weather _____ beautiful.',
    'options': ['did', 'was', 'does', 'were'],
    'correctAnswer': 'was'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Tom _____ home right now. He\'s still at the office.',
    'options': [
      'isn\'t driving',
      'doesn\'t drive',
      'didn\'t drive',
      'drives'
    ],
    'correctAnswer': 'isn\'t driving'
  },
  {
    'question': 'Complete the question:',
    'sentence': 'Is it true? _____ a grandparent yesterday?',
    'options': [
      'Are you becoming',
      'Does she become',
      'Did he become',
      'They became'
    ],
    'correctAnswer': 'Did he become'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'I go to the gym _____ evenings. I only don\'t go on the weekend.',
    'options': ['some', 'most', 'all of the', 'many of the'],
    'correctAnswer': 'most'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Susan\'s cousin is _____ player on our soccer team.',
    'options': ['bad', 'best', 'worse', 'the worst'],
    'correctAnswer': 'the worst'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Our neighbor _____ the screen of his phone twice last year.',
    'options': ['breaks', 'is breaking', 'has broken', 'broke'],
    'correctAnswer': 'broke'
  },
  {
    'question': 'Complete the dialogue:',
    'sentence': 'A: I can\'t forget to make a reservation at the restaurant before noon.\nB: Don\'t worry. _____ you.',
    'options': [
      'I\'m reminding',
      'I\'ve reminded',
      'I\'ll remind',
      'I remind'
    ],
    'correctAnswer': 'I\'ll remind'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'We _____ for a hotel when the storm began.',
    'options': ['search', 'will search', 'have searched', 'were searching'],
    'correctAnswer': 'were searching'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'If you _____ concentrate on your work, you usually waste a lot of time.',
    'options': ['don\'t', 'won\'t', 'didn\'t', 'couldn\'t'],
    'correctAnswer': 'don\'t'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'I\'m exhausted. _____ to fix this machine since I got here this morning.',
    'options': ['I try', 'I\'ll try', 'I tried', 'I\'ve been trying'],
    'correctAnswer': 'I\'ve been trying'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Several bridges _____ during the earthquake last year.',
    'options': [
      'badly damaged',
      'were badly damaged',
      'have badly damaged',
      'were badly damaging'
    ],
    'correctAnswer': 'were badly damaged'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'The agency _____ that our ideas for the poster seem a little old-fashioned.',
    'options': ['believes', 'is believing', 'was believed', 'has been believing'],
    'correctAnswer': 'believes'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Superhero movies are a kind of entertainment _____ really attracted to.',
    'options': ['which', 'I\'m not', 'who they', 'that aren\'t'],
    'correctAnswer': 'I\'m not'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'More support _____ to groups dealing with environmental issues.',
    'options': [
      'is providing',
      'might provide',
      'must be provided',
      'should be providing'
    ],
    'correctAnswer': 'must be provided'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Employees _____ show their ID cards, or they couldn\'t have access to the research facilities.',
    'options': [
      'were required to',
      'were allowed to',
      'didn\'t have to',
      'could'
    ],
    'correctAnswer': 'were required to'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Our math teacher made _____ a hundred math problems in one hour.',
    'options': ['us to solve', 'be solved', 'us solve', 'solve'],
    'correctAnswer': 'us solve'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'The process _____ be very time-consuming before they launched the new system.',
    'options': ['might', 'would', 'ought to', 'used to'],
    'correctAnswer': 'used to'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'After some time together, those on John\'s team learned not to underestimate _____.',
    'options': ['each other', 'himself', 'another', 'itself'],
    'correctAnswer': 'each other'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'The man next door asked me _____ keep an eye on his apartment while he was away.',
    'options': ['I can', 'would I', 'if I could', 'whether will I'],
    'correctAnswer': 'if I could'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Our niece is very hardworking and determined. She has never had any trouble _____ her exams.',
    'options': ['to pass', 'passing', 'passed', 'pass'],
    'correctAnswer': 'passing'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'If they _____ the damage more carefully, they would have found these other problems.',
    'options': [
      'would assess',
      'had assessed',
      'have assessed',
      'would have assessed'
    ],
    'correctAnswer': 'had assessed'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'By this time next Monday, _____ a new head of the sales department.',
    'options': [
      'we hire',
      'we\'re hiring',
      'we\'ll have hired',
      'we have been hiring'
    ],
    'correctAnswer': 'we\'ll have hired'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'The consultants proposed a number of alternatives, _____ the firm disregarded.',
    'options': [
      'much of what',
      'many of which',
      'some of whom',
      'none of whose'
    ],
    'correctAnswer': 'many of which'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'What _____ a couple of relaxing days at an unspoiled beach.',
    'options': [
      'they actually plan',
      'did they actually plan',
      'they actually planned was',
      'have they actually planned are'
    ],
    'correctAnswer': 'they actually planned was'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'We felt genuinely shocked. Never again _____ at such an overrated place.',
    'options': [
      'ate we',
      'we will eat',
      'did eat we',
      'would we eat'
    ],
    'correctAnswer': 'would we eat'
  },
  {
    'question': 'Complete the sentence:',
    'sentence': 'Authorities recommend that everyone _____ the highway until repairs are completed.',
    'options': ['avoid', 'avoided', 'would avoid', 'is going to avoid'],
    'correctAnswer': 'avoid'
  }
];


  @override
  void initState() {
    super.initState();
    _remainingTime = widget.remainingTime ?? Duration(minutes: _totalTimeInMinutes);
    _initializeTimer();
    _startTime = DateTime.now();
  }

  Future<void> _initializeTimer() async {
    final remainingTime = await _testSessionService.getGrammarRemainingTime();
    if (remainingTime != null) {
      setState(() {
        _remainingTime = remainingTime;
        _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
      });
    } else {
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

      if (mounted) {
        setState(() {
          _remainingTime = remainingTime;
          _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
        });
      }
    });
  }
  

  Future<void> _handleTimeUp() async {
    // Cancel timer and update state immediately
    _timer.cancel();
    await _testSessionService.endGrammarTest();
    await _testSessionService.markTestAsCompleted('grammar');

    int correctAnswers = _calculateRawScore();
    final standardizedScore = ScoreCalculator.calculateGrammarScore(
      correctAnswers,
      _questions.length
    );
    
    final testDuration = DateTime.now().difference(_startTime);
    
    // Store completion status, score and duration
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('grammar_test_completed', true);
    await prefs.setInt('grammar_test_score', standardizedScore);
    await prefs.setInt('grammar_test_duration', testDuration.inSeconds);
    
    // Notify parent
    widget.onTestComplete?.call(testDuration, standardizedScore);

    try {
      final authService = AuthService();
      final testResultsService = TestResultsService(authService.projectId);
      
      final userId = await authService.getUserId();
      final result = TestResult(
        userId: userId ?? 'anonymous',
        firstName: widget.firstName,
        lastName: widget.lastName,
        testType: 'Grammar Test',
        score: standardizedScore,
        totalQuestions: _questions.length,
        timestamp: DateTime.now(),
      );
      
      await testResultsService.saveTestResult(result);
    } catch (e) {
      print('Error saving test result: $e');
    }

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  int _calculateScore() {
    int correctAnswers = _calculateRawScore();
    return ScoreCalculator.calculateGrammarScore(correctAnswers, _questions.length);
  }

  Future<void> _handleTestCompletion() async {
    try {
      _timer.cancel();
      await _testSessionService.endGrammarTest();
      await _testSessionService.markTestAsCompleted('grammar');
      
      // Calculate scores
      int correctAnswers = _calculateRawScore();
      final standardizedScore = ScoreCalculator.calculateGrammarScore(
        correctAnswers, 
        _questions.length
      );
      
      final testDuration = DateTime.now().difference(_startTime);
      
      // Save test data
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setInt('grammar_test_score', standardizedScore),
        prefs.setInt('grammar_test_duration', testDuration.inSeconds),
        prefs.setBool('grammar_test_completed', true),
        prefs.setInt('grammar_total_questions', _questions.length),
      ]);

      // Save to Firestore
      final authService = AuthService();
      final testResultsService = TestResultsService(authService.projectId);
      
      final userId = await authService.getUserId();
      final result = TestResult(
        userId: userId ?? 'anonymous',
        firstName: widget.firstName,
        lastName: widget.lastName,
        testType: 'Grammar Test',
        score: standardizedScore,
        totalQuestions: _questions.length,
        timestamp: DateTime.now(),
      );
      
      await testResultsService.saveTestResult(result);
      widget.onTestComplete?.call(testDuration, standardizedScore);
      
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
      
    } catch (e) {
      print('Error completing grammar test: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save test result. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _handleTestCompletion,
          ),
        ),
      );
    }
  }

  // Helper method to calculate raw score
  int _calculateRawScore() {
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
        if (_userAnswers.length > i && _userAnswers[i] == _questions[i]['correctAnswer']) {
            correctAnswers++;
        }
    }
    return correctAnswers;
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
        automaticallyImplyLeading: false,
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
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.red.shade400),
                ),
              ),
              icon: Icon(
                Icons.exit_to_app,
                color: Colors.red.shade400,
                size: 20,
              ),
              label: Text(
                'Exit Test',
                style: GoogleFonts.poppins(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => _showExitConfirmation(context),
            ),
          ),
        ],
        toolbarHeight: 72,
      ),
      body: Column(
        children: [
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
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Card(
                              margin: EdgeInsets.zero,
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
                                      width: double.infinity,
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
                          Card(
                            margin: EdgeInsets.zero,
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
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
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
                                          setState(() {
                                            if (_selectedAnswer != null) {
                                              _userAnswers[_currentQuestionIndex] = _selectedAnswer!;
                                            }
                                            _currentQuestionIndex++;
                                            _selectedAnswer = null;
                                          });
                                        } else {
                                          // Save last answer
                                          if (_selectedAnswer != null) {
                                            _userAnswers[_currentQuestionIndex] = _selectedAnswer!;
                                          }
                                          
                                          await _handleTestCompletion();
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
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _selectedAnswer = option;
            });
          },
          child: Container(
            padding: EdgeInsets.all(24),
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
                  width: 28,
                  height: 28,
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
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
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

  Future<void> _showExitConfirmation(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: 400, // Fixed width for the dialog
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
                  'Exit Test?',
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
                              'Are you sure you want to exit?',
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
                        'This will mark the test as completed with your current progress.',
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
                      onPressed: () => Navigator.of(context).pop(true),
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
                              Icon(Icons.exit_to_app, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Exit Test',
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

    if (shouldExit == true) {
      // Cancel timer and mark test as completed
      _timer.cancel();
      await _testSessionService.endGrammarTest();
      await _testSessionService.markTestAsCompleted('grammar');

      // Calculate scores
      int correctAnswers = _calculateRawScore();
      final standardizedScore = ScoreCalculator.calculateGrammarScore(
        correctAnswers,
        _questions.length
      );
      
      final testDuration = DateTime.now().difference(_startTime);
      
      // Store completion status, score and duration
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool('grammar_test_completed', true),
        prefs.setInt('grammar_test_score', standardizedScore),
        prefs.setInt('grammar_test_duration', testDuration.inSeconds),
        prefs.setInt('grammar_total_questions', _questions.length),
      ]);

      try {
        final authService = AuthService();
        final testResultsService = TestResultsService(authService.projectId);
        
        final userId = await authService.getUserId();
        final result = TestResult(
          userId: userId ?? 'anonymous',
          firstName: widget.firstName,
          lastName: widget.lastName,
          testType: 'Grammar Test',
          score: standardizedScore,
          totalQuestions: _questions.length,
          timestamp: DateTime.now(),
        );
        
        await testResultsService.saveTestResult(result);
      } catch (e) {
        print('Error saving test result: $e');
      }

      // Notify parent
      widget.onTestComplete?.call(testDuration, standardizedScore);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    }
  }
}
