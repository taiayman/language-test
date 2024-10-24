import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:test_windows_students/services/auth_service.dart';
import 'package:test_windows_students/services/test_results_service.dart';
import 'package:test_windows_students/models/test_result.dart';
import 'package:test_windows_students/screens/reading_test_results_page.dart';
import 'package:test_windows_students/services/test_session_service.dart';  // Add this import

class ReadingTestPage extends StatefulWidget {
  final Duration? remainingTime;
  final String firstName;
  final String lastName;
  final VoidCallback? onTestComplete;  // Add this line
  
  const ReadingTestPage({
    Key? key, 
    this.remainingTime,
    required this.firstName,
    required this.lastName,
    this.onTestComplete,  // Add this line
  }) : super(key: key);

  @override
  _ReadingTestPageState createState() => _ReadingTestPageState();
}

class _ReadingTestPageState extends State<ReadingTestPage> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  final int _totalTimeInMinutes = 20; // 20 minutes for the reading test
  late Timer _timer;
  late Duration _remainingTime;
  double _progress = 1.0;
  final TestSessionService _testSessionService = TestSessionService();  // Add this

  // Example reading passage and questions
  final List<Map<String, dynamic>> _readingTests = [
    {
       'passage': '''Passage 1: An email
Subject: Greetings from Florida!
Hi, Sara.
I'm visiting my sister in Florida. It's very warm and nice here. Every morning, I go to the beach and swim.
Sometimes my sister comes home early, and we play tennis in the afternoon. And we always go for a long walk after that. I'm having a great time!
Love,
Heather''',
      'questions': [
        {
          'question': 'Heather every day:',
          'options': [
            'A) swims',
            'B) plays tennis',
            'C) comes home early',
            'D) walks with her sister'
          ],
          'correctAnswer': 'A) swims'
        }
      ]
    },
    {
      'passage': '''Passage 2: Helen is getting married and I'm tired
This has been a crazy week! One of my friends is getting married on Saturday, and I'm helping her with the reception.
It's not going to be a big party, but I still have to do a lot of things. For example, I chose the songs last week, but the band is playing them for me tonight. I bought the flowers today, but I have to pick them up on Friday.
I'm tired. Can someone help me, please?!''',
      'questions': [
        {
          'question': 'The writer:',
          'options': [
            'A) is singing tonight',
            'B) is buying flowers on Friday',
            'C) listened to a band a week ago',
            'D) is going to a party this weekend'
          ],
          'correctAnswer': 'D) is going to a party this weekend'
        }
      ]
    }
  ];

  int _currentExerciseIndex = 0;
  
  // Update these getters to access current exercise
  String get _currentPassage => _readingTests[_currentExerciseIndex]['passage'];
  List<Map<String, dynamic>> get _currentQuestions => 
      _readingTests[_currentExerciseIndex]['questions'];

  // Add this getter for _isLastExercise
  bool get _isLastExercise => _currentExerciseIndex == _readingTests.length - 1;

  // Add this property to track user answers
  List<String?> _userAnswers = [];

  // Add this getter for _isLastQuestion
  bool get _isLastQuestion => 
      _currentQuestionIndex == _currentQuestions.length - 1 && 
      _currentExerciseIndex == _readingTests.length - 1;

  // Add the _showNameInputDialog method
  Future<bool?> _showNameInputDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 32,
                      color: Color(0xFF2193b0),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Enter Your Name',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2193b0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_firstNameController.text.isNotEmpty && 
                            _lastNameController.text.isNotEmpty) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: Text('Continue'),
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

  // Add these controllers at the top of your _ReadingTestPageState class
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Update the Next button handler
  void _handleNextExercise() {
    if (_selectedAnswer == null) return;

    setState(() {
      if (_currentExerciseIndex < _readingTests.length - 1) {
        // Move to next exercise
        _currentExerciseIndex++;
        _selectedAnswer = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    _userAnswers = List.filled(_getTotalQuestions(), null);
  }

  Future<void> _initializeTimer() async {
    // Get remaining time from storage
    final remainingTime = await _testSessionService.getReadingRemainingTime();
    if (remainingTime != null) {
      setState(() {
        _remainingTime = remainingTime;
        _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
      });
    } else {
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
      final remainingTime = await _testSessionService.getReadingRemainingTime();
      
      if (remainingTime == null || remainingTime.inSeconds <= 0) {
        _timer.cancel();
        _handleTimeUp();
        return;
      }

      setState(() {
        _remainingTime = remainingTime;
        _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
      });
    });
  }

  void _handleTimeUp() async {
    _timer.cancel();
    await _testSessionService.endReadingTest();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Time\'s Up!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2193b0),
            ),
          ),
          content: Text(
            'Your time for the reading test has ended.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              child: Text(
                'View Results',
                style: GoogleFonts.poppins(
                  color: Color(0xFF2193b0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Add navigation to results page
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    // Don't end the test when disposing unless explicitly requested
    super.dispose();
  }

  // Update back button handler
  Future<void> _handleBackButton() async {
    _timer.cancel();
    Navigator.of(context).pop();
  }

  // Update AppBar
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF2193b0),
        ),
        onPressed: _handleBackButton,
      ),
      title: Row(
        children: [
          Icon(
            MaterialCommunityIcons.book_open_variant,
            color: Color(0xFF2193b0),
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'Reading Test',
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
      toolbarHeight: 72, // Added to match grammar test
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleBackButton();
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
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
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    children: [
                      // Left panel - Reading passage and timer
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Reading passage card (Upper)
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Reading Passage',
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2193b0),
                                            ),
                                          ),
                                          Text(
                                            'Passage ${_currentExerciseIndex + 1} of ${_readingTests.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 24),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _currentPassage,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              height: 1.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Timer card (Lower)
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
                      // Right panel - Questions
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
                                  _currentQuestions[_currentQuestionIndex]['question'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 24),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _currentQuestions[_currentQuestionIndex]['options'].length,
                                    itemBuilder: (context, index) {
                                      return _buildOptionButton(
                                        _currentQuestions[_currentQuestionIndex]['options'][index]
                                      );
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: _selectedAnswer != null
                                    ? () async {
                                        if (_currentQuestionIndex < _currentQuestions.length - 1) {
                                          // Continue to next question
                                          setState(() {
                                            _userAnswers[_getQuestionIndex(_currentExerciseIndex, _currentQuestionIndex)] = _selectedAnswer;
                                            _currentQuestionIndex++;
                                            _selectedAnswer = null;
                                          });
                                        } else if (_currentExerciseIndex < _readingTests.length - 1) {
                                          // Save answer and move to next passage
                                          _userAnswers[_getQuestionIndex(_currentExerciseIndex, _currentQuestionIndex)] = _selectedAnswer;
                                          setState(() {
                                            _currentExerciseIndex++;
                                            _currentQuestionIndex = 0;
                                            _selectedAnswer = null;
                                          });
                                        } else {
                                          // Save final answer
                                          _userAnswers[_getQuestionIndex(_currentExerciseIndex, _currentQuestionIndex)] = _selectedAnswer;
                                          
                                          // Calculate score correctly for all passages
                                          int score = 0;
                                          for (int i = 0; i < _readingTests.length; i++) {
                                            final questions = _readingTests[i]['questions'] as List;
                                            for (int j = 0; j < questions.length; j++) {
                                              final questionIndex = _getQuestionIndex(i, j);
                                              if (_userAnswers[questionIndex] == questions[j]['correctAnswer']) {
                                                score++;
                                              }
                                            }
                                          }
                                          
                                          try {
                                            // Stop the timer
                                            _timer.cancel();
                                            
                                            // Mark test as completed
                                            await _testSessionService.markTestAsCompleted('reading');
                                            
                                            // Call onTestComplete callback
                                            widget.onTestComplete?.call();
                                            
                                            final authService = AuthService();
                                            final testResultsService = TestResultsService(authService.projectId);
                                            
                                            final result = TestResult(
                                              userId: authService.getUserId() ?? 'anonymous',
                                              firstName: widget.firstName,
                                              lastName: widget.lastName,
                                              testType: 'Reading Test',
                                              score: score,
                                              totalQuestions: _getTotalQuestions(),
                                              timestamp: DateTime.now(),
                                            );
                                            
                                            await testResultsService.saveTestResult(result);
                                            
                                            if (!mounted) return;
                                            
                                            // Navigate to results page
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) => ReadingTestResultsPage(
                                                  score: score,
                                                  totalQuestions: _getTotalQuestions(),
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
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _isLastExercise ? 'Finish Test' : 'Next Passage',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
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
            padding: EdgeInsets.all(16),
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
                  width: 24,
                  height: 24,
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
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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

  // Fix the _getTotalQuestions method
  int _getTotalQuestions() {
    return _readingTests.fold<int>(0, (sum, test) => 
        sum + (test['questions'] as List).length);
  }

  // Fix the getCurrentQuestionNumber method
  int _getCurrentQuestionNumber() {
    int questionNumber = 0;
    for (int i = 0; i < _currentExerciseIndex; i++) {
      questionNumber += (_readingTests[i]['questions'] as List).length;
    }
    return questionNumber + _currentQuestionIndex + 1;
  }

  // Add this helper method to get total questions in current exercise
  int _getTotalQuestionsInCurrentExercise() {
    return _readingTests[_currentExerciseIndex]['questions'].length;
  }

  // Update this helper method to properly cast the questions list
  int _getQuestionIndex(int exerciseIndex, int questionIndex) {
    int index = 0;
    for (int i = 0; i < exerciseIndex; i++) {
      index += (_readingTests[i]['questions'] as List).length;
    }
    return index + questionIndex;
  }
}
