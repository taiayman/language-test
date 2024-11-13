import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alc_eljadida_tests/services/auth_service.dart';
import 'package:alc_eljadida_tests/services/test_results_service.dart';
import 'package:alc_eljadida_tests/models/test_result.dart';
import 'package:alc_eljadida_tests/services/test_session_service.dart';
import 'package:alc_eljadida_tests/services/firestore_service.dart';
import 'package:alc_eljadida_tests/screens/home_page.dart';
import 'package:alc_eljadida_tests/services/score_calculator.dart';

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - (trackHeight ?? 4)) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight ?? 4);
  }
}

class ListeningTestPage extends StatefulWidget {
  final Duration? remainingTime;
  final String firstName;
  final String lastName;
  final Function(Duration, int)? onTestComplete;

  const ListeningTestPage({
    Key? key,
    this.remainingTime,
    required this.firstName,
    required this.lastName,
    this.onTestComplete,
  }) : super(key: key);

  @override
  _ListeningTestPageState createState() => _ListeningTestPageState();
}

class _ListeningTestPageState extends State<ListeningTestPage> {
  late final AudioPlayer _audioPlayer;
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final int _totalTimeInMinutes = 15;
  late Timer _timer;
  Duration _remainingTime = Duration(minutes: 15);
  double _progress = 1.0;
  Duration _bufferedPosition = Duration.zero;
  bool _isSeeking = false;
  double? _dragValue;
  List<String?> _userAnswers = [];
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TestSessionService _testSessionService = TestSessionService();
  DateTime _startTime = DateTime.now();
  bool _hasFinishedPlaying = false;
  bool _isAudioEnabled = true;
  int _currentSituationNumber = 1;

  final List<Map<String, dynamic>> _questions = [
    {
      'situation': 1,
      'audioUrl': 'assets/audio/situation1.mp3',
      'question':
          'Situation 1: Emily and Jason are talking about work.\nWhat is true about Emily?',
      'options': [
        'a) works at a café',
        'b) never goes to the mall',
        'c) works every weekend',
        'd) goes to the mall every day'
      ],
      'correctAnswer': 'a) works at a café',
    },
    {
      'situation': 2,
      'audioUrl': 'assets/audio/situation2.mp3',
      'question':
          'Situation 2: Jessica is buying clothes.\nWhat is true about Jessica?',
      'options': [
        'a) is buying a dress and a skirt',
        'b) thinks the skirts are expensive',
        'c) can\'t find a red skirt',
        'd) pays \$30 for the skirt'
      ],
      'correctAnswer': 'c) can\'t find a red skirt',
    },
    {
      'situation': 3,
      'audioUrl': 'assets/audio/situation3.mp3',
      'question':
          'Situation 3: Rachel and Michael are talking in a mall.\nWhat is true about Rachel and Michael?',
      'options': [
        'a) are having lunch together',
        'b) are buying gifts for their children',
        'c) are busy tomorrow afternoon',
        'd) are going to meet again tomorrow'
      ],
      'correctAnswer': 'c) are busy tomorrow afternoon',
    },
    {
      'situation': 4,
      'audioUrl': 'assets/audio/situation4.mp3',
      'question':
          'Situation 4: Andrew is talking to a waitress at a restaurant.\nWhat is true about Andrew?',
      'options': [
        'a) didn\'t enjoy the food',
        'b) ate just a little pasta',
        'c) ordered a salad',
        'd) didn\'t like the dressing'
      ],
      'correctAnswer': 'c) ordered a salad',
    },
    {
      'situation': 4,
      'audioUrl': 'assets/audio/situation4.mp3',
      'question': 'Situation 4: What is true about the waitress?',
      'options': [
        'a) can make the salad dressing',
        'b) is going to talk to the chef',
        'c) doesn\'t offer a dessert to Andrew',
        'd) is going to bring Andrew some coffee'
      ],
      'correctAnswer': 'd) is going to bring Andrew some coffee',
    },
    {
      'situation': 5,
      'audioUrl': 'assets/audio/situation5.mp3',
      'question':
          'Situation 5: Laura is talking to her father about a health problem.\nWhat is true about Laura?',
      'options': [
        'a) hit her head in a basketball game',
        'b) ate some bad food at school yesterday',
        'c) has a horrible pain in her stomach',
        'd) has a very bad headache'
      ],
      'correctAnswer': 'd) has a very bad headache',
    },
    {
      'situation': 5,
      'audioUrl': 'assets/audio/situation5.mp3',
      'question': 'Situation 5: What is true about Laura\'s father?',
      'options': [
        'a) has a stomachache too',
        'b) offers to take her to the doctor',
        'c) is going to call a doctor',
        'd) wants to rest a little'
      ],
      'correctAnswer': 'b) offers to take her to the doctor',
    },
    {
      'situation': 6,
      'audioUrl': 'assets/audio/situation6.mp3',
      'question':
          'Situation 6: Jack is talking to his friend Olivia on the phone.\nWhen Jack called Olivia, she:',
      'options': [
        'a) couldn\'t hear him because of a bad connection',
        'b) was in a noisy area, but she moved',
        'c) was at the bus stop with her friend Katie',
        'd) was on her way to see a play'
      ],
      'correctAnswer': 'b) was in a noisy area, but she moved',
    },
    {
      'situation': 6,
      'audioUrl': 'assets/audio/situation6.mp3',
      'question': 'Situation 6: What is true about Jack?',
      'options': [
        'a) thought the movie was not very exciting',
        'b) thought the movie had too much action',
        'c) thinks Olivia shouldn\'t see the movie',
        'd) is going out with Olivia and Katie on Friday'
      ],
      'correctAnswer': 'a) thought the movie was not very exciting',
    },
    {
      'situation': 7,
      'audioUrl': 'assets/audio/situation7.mp3',
      'question':
          'Situation 7: Amanda is meeting her friend Patrick at a café.\nWhat is true about Amanda and Patrick?',
      'options': [
        'a) last met in January',
        'b) went to a concert together',
        'c) haven\'t seen each other since April',
        'd) have been spending a lot of time together lately'
      ],
      'correctAnswer': 'b) went to a concert together',
    },
    {
      'situation': 7,
      'audioUrl': 'assets/audio/situation7.mp3',
      'question': 'Situation 7: What is true about Amanda?',
      'options': [
        'a) has found a new job',
        'b) is looking for another job',
        'c) finds her work too challenging',
        'd) has been having problems at work'
      ],
      'correctAnswer': 'a) has found a new job',
    },
    {
      'situation': 7,
      'audioUrl': 'assets/audio/situation7.mp3',
      'question': 'Situation 7: What is true about Patrick?',
      'options': [
        'a) has been learning Spanish',
        'b) isn\'t enjoying his cooking class very much',
        'c) has been all over the world lately',
        'd) wants to cook for Amanda and Jim'
      ],
      'correctAnswer': 'd) wants to cook for Amanda and Jim',
    },
    {
      'situation': 8,
      'audioUrl': 'assets/audio/situation8.mp3',
      'question':
          'Situation 8: Nicole is talking to her teacher, Mr. Kushner, about her exam grade.\nWhat is true about Mr. Kushner?',
      'options': [
        'a) thought that Nicole was disappointed with her grade',
        'b) doesn\'t think Nicole knows about his rules',
        'c) usually lets students take exams a second time',
        'd) thinks that Nicole will get a better grade next time'
      ],
      'correctAnswer': 'a) thought that Nicole was disappointed with her grade',
    },
    {
      'situation': 8,
      'audioUrl': 'assets/audio/situation8.mp3',
      'question':
          'Situation 8: Nicole thinks that she got a low grade because:',
      'options': [
        'a) she only had time to answer the reading questions',
        'b) she didn\'t get a grade on the reading section',
        'c) she forgot to answer the reading questions',
        'd) she did badly on the reading section'
      ],
      'correctAnswer': 'b) she didn\'t get a grade on the reading section',
    },
    {
      'situation': 8,
      'audioUrl': 'assets/audio/situation8.mp3',
      'question': 'Situation 8: In the end, Mr. Kushner:',
      'options': [
        'a) wasn\'t able to help Nicole',
        'b) asked Nicole not to miss an exam again',
        'c) apologized to Nicole for the problem',
        'd) realized that Nicole\'s exam was missing'
      ],
      'correctAnswer': 'c) apologized to Nicole for the problem',
    },
    {
      'situation': 9,
      'audioUrl': 'assets/audio/situation9.mp3',
      'question':
          'Situation 9: Lisa is talking to Eric about her job interview.\nAfter Lisa\'s interview, she felt:',
      'options': [
        'a) more optimistic than she did before',
        'b) she was well prepared for it',
        'c) uncertain about it',
        'd) her answers sounded very confident'
      ],
      'correctAnswer': 'a) more optimistic than she did before',
    },
    {
      'situation': 9,
      'audioUrl': 'assets/audio/situation9.mp3',
      'question': 'Situation 9: During the interview, Lisa:',
      'options': [
        'a) recognized that she\'s an impatient person',
        'b) said she tended to be too positive about things',
        'c) admitted she didn\'t enjoy working on big projects',
        'd) boasted that she always met her deadlines'
      ],
      'correctAnswer': 'd) boasted that she always met her deadlines',
    },
    {
      'situation': 9,
      'audioUrl': 'assets/audio/situation9.mp3',
      'question':
          'Situation 9: According to Eric, what can make a person seem intelligent?',
      'options': [
        'a) taking less time to answer a question',
        'b) staying calm throughout an interview',
        'c) speaking naturally and showing no anxiety',
        'd) pausing before saying something'
      ],
      'correctAnswer': 'd) pausing before saying something',
    },
    {
      'situation': 9,
      'audioUrl': 'assets/audio/situation9.mp3',
      'question': 'Situation 9: What is true about Lisa?',
      'options': [
        'a) thinks she could find a much better job',
        'b) usually believes in miracles',
        'c) expects to be offered the position',
        'd) feels frustrated about the situation'
      ],
      'correctAnswer': 'd) feels frustrated about the situation',
    },
    {
      'situation': 9,
      'audioUrl': 'assets/audio/situation9.mp3',
      'question': 'Situation 9: What is true about Eric?',
      'options': [
        'a) agrees with Lisa\'s views on her performance at the interview',
        'b) thinks people naturally have a good opinion about Lisa',
        'c) is concerned that Lisa might quit her job',
        'd) advises her not to be so proud of herself'
      ],
      'correctAnswer':
          'b) thinks people naturally have a good opinion about Lisa',
    },
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentSituationNumber = _questions[_currentQuestionIndex]['situation'];
    _isAudioEnabled = true;
    _loadNewAudio();
    _startTime = DateTime.now();

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _hasFinishedPlaying = true;
        });
      }
    });

    _initializeTimer();

    _loadQuestionsAndAnswers();
  }

  void _initializeTimer() async {
    final remainingTime = await _testSessionService.getListeningRemainingTime();

    if (remainingTime == null || remainingTime.inSeconds <= 0) {
      _handleTimeUp();
      return;
    }

    setState(() {
      _remainingTime = remainingTime;
      _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
    });

    _startTimer();
  }

  void _startTimer() {
    const oneSecond = Duration(seconds: 1);
    _timer = Timer.periodic(oneSecond, (timer) async {
      final remainingTime =
          await _testSessionService.getListeningRemainingTime();

      if (mounted) {
        if (remainingTime == null || remainingTime.inSeconds <= 0) {
          _timer.cancel();
          _handleTimeUp();
          return;
        }

        setState(() {
          _remainingTime = remainingTime;
          _progress = _remainingTime.inSeconds / (_totalTimeInMinutes * 60);
        });
      }
    });
  }

  Future<void> _loadNewAudio() async {
    try {
      // Reset states
      setState(() {
        _position = Duration.zero;
        _bufferedPosition = Duration.zero;
        _duration = Duration.zero;
        _isPlaying = false;
        _hasFinishedPlaying = false;
      });

      // Stop current audio if playing
      await _audioPlayer.stop();

      // Load the new audio file
      final audioSource =
          AudioSource.asset(_questions[_currentQuestionIndex]['audioUrl']);
      await _audioPlayer.setAudioSource(audioSource, preload: true);

      // Get new duration
      _duration = await _audioPlayer.duration ?? Duration.zero;

      // Add stream listeners
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
        if (mounted) {
          setState(() {
            _bufferedPosition = bufferedPosition;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((playerState) {
        if (mounted) {
          setState(() {
            _isPlaying = playerState.playing;
          });
        }
      });

      setState(() {
        _isAudioEnabled = true;
      }); // Update UI with new duration and enable audio
    } catch (e) {
      print('Error loading new audio: $e');
    }
  }

  Future<void> _handlePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error playing/pausing audio: $e');
    }
  }

  Future<void> _handleTestCompletion() async {
    try {
      _timer.cancel();
      await _testSessionService.endListeningTest();
      await _testSessionService.markTestAsCompleted('listening');

      int correctAnswers = 0;

      for (int i = 0; i < _questions.length; i++) {
        String? userAnswer =
            _userAnswers.length > i ? _userAnswers[i] : null;
        String correctAnswer = _questions[i]['correctAnswer'];

        bool isMatch = userAnswer?.trim() == correctAnswer.trim();

        if (isMatch) {
          correctAnswers++;
        }
      }

      final testDuration = DateTime.now().difference(_startTime);
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setInt('listening_test_score', correctAnswers),
        prefs.setInt('listening_test_duration', testDuration.inSeconds),
        prefs.setBool('listening_test_completed', true),
        prefs.setInt('listening_total_questions', _questions.length),
      ]);

      // Save to Firestore
      final authService = AuthService();
      final testResultsService = TestResultsService(authService.projectId);
      final userId = await authService.getUserId();

      final result = TestResult(
        userId: userId ?? 'anonymous',
        firstName: widget.firstName,
        lastName: widget.lastName,
        testType: 'Listening Test',
        score: correctAnswers,
        totalQuestions: _questions.length,
        timestamp: DateTime.now(),
      );

      await testResultsService.saveTestResult(result);
      widget.onTestComplete?.call(testDuration, correctAnswers);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error in handleTestCompletion: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving test results'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleTimeUp() async {
    // Cancel timer and update state immediately
    _timer.cancel();
    await _testSessionService.endListeningTest();
    await _testSessionService.markTestAsCompleted('listening');

    // Calculate raw score from answered questions
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers.length > i &&
          _userAnswers[i] == _questions[i]['correctAnswer']) {
        correctAnswers++;
      }
    }

    // Calculate standardized score
    final standardizedScore = ScoreCalculator.calculateListeningScore(
        correctAnswers, _questions.length);

    final testDuration = DateTime.now().difference(_startTime);

    // Store completion status, score and duration
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('listening_test_completed', true),
      prefs.setInt('listening_test_score', standardizedScore),
      prefs.setInt('listening_test_duration', testDuration.inSeconds),
      prefs.setInt('listening_total_questions', _questions.length),
    ]);

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
        testType: 'Listening Test',
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

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
            child: Padding(
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Color(0xFF2193b0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF2193b0),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _lastNameController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFF2193b0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF2193b0),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2193b0),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (_firstNameController.text.isNotEmpty &&
                                _lastNameController.text.isNotEmpty) {
                              Navigator.of(context).pop(true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter both first and last name',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              MaterialCommunityIcons.headphones,
              color: Color(0xFF2193b0),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Listening Test',
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
                                      _questions[_currentQuestionIndex]
                                          ['question'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2193b0),
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 36,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SliderTheme(
                                                  data: SliderThemeData(
                                                    trackHeight: 4,
                                                    thumbShape:
                                                        RoundSliderThumbShape(
                                                            enabledThumbRadius:
                                                                0),
                                                    overlayShape:
                                                        RoundSliderOverlayShape(
                                                            overlayRadius: 0),
                                                    trackShape:
                                                        CustomTrackShape(),
                                                    rangeTrackShape:
                                                        RoundedRectRangeSliderTrackShape(),
                                                    showValueIndicator:
                                                        ShowValueIndicator
                                                            .never,
                                                  ),
                                                  child: Slider(
                                                    value: min(
                                                        _bufferedPosition
                                                            .inSeconds
                                                            .toDouble(),
                                                        _duration.inSeconds
                                                            .toDouble()),
                                                    max: _duration.inSeconds
                                                        .toDouble(),
                                                    onChanged: null,
                                                    activeColor:
                                                        Color(0xFF2193b0)
                                                            .withOpacity(0.24),
                                                    inactiveColor:
                                                        Colors.grey.shade200,
                                                  ),
                                                ),
                                                SliderTheme(
                                                  data: SliderThemeData(
                                                    trackHeight: 4,
                                                    thumbShape:
                                                        RoundSliderThumbShape(
                                                            enabledThumbRadius:
                                                                8),
                                                    overlayShape:
                                                        RoundSliderOverlayShape(
                                                            overlayRadius: 16),
                                                    trackShape:
                                                        CustomTrackShape(),
                                                    activeTrackColor:
                                                        Color(0xFF2193b0),
                                                    inactiveTrackColor:
                                                        Colors.transparent,
                                                    thumbColor:
                                                        Color(0xFF2193b0),
                                                    overlayColor:
                                                        Color(0xFF2193b0)
                                                            .withOpacity(0.12),
                                                  ),
                                                  child: Slider(
                                                    value: _position.inSeconds
                                                        .toDouble(),
                                                    max: _duration.inSeconds
                                                        .toDouble(),
                                                    onChanged: null,
                                                    onChangeEnd: null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(_position),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDuration(_duration),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                iconSize: 48,
                                                icon: AnimatedSwitcher(
                                                  duration: Duration(
                                                      milliseconds: 200),
                                                  transitionBuilder:
                                                      (child, animation) =>
                                                          ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                                  child: Icon(
                                                    _isPlaying
                                                        ? Icons
                                                            .pause_circle_filled
                                                        : Icons
                                                            .play_circle_filled,
                                                    key: ValueKey<bool>(
                                                        _isPlaying),
                                                    size: 48,
                                                    color: _hasFinishedPlaying ||
                                                            !_isAudioEnabled
                                                        ? Colors.grey
                                                        : Color(0xFF2193b0),
                                                  ),
                                                ),
                                                onPressed: _hasFinishedPlaying ||
                                                        !_isAudioEnabled
                                                    ? null
                                                    : _handlePlayPause,
                                              ),
                                            ],
                                          ),
                                        ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                          padding: const EdgeInsets.only(
                              left: 24.0, top: 24.0, bottom: 24.0, right: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Select your answer:',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2193b0),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: Scrollbar(
                                  thickness: 8,
                                  radius: Radius.circular(4),
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ..._questions[_currentQuestionIndex]
                                                  ['options']
                                              .map<Widget>(
                                                  (option) => _buildOptionButton(
                                                      option))
                                              .toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                onPressed: _selectedAnswer != null
                                    ? () async {
                                        if (_currentQuestionIndex <
                                            _questions.length - 1) {
                                          _userAnswers.add(_selectedAnswer);

                                          int nextQuestionIndex =
                                              _currentQuestionIndex + 1;
                                          int nextSituationNumber =
                                              _questions[nextQuestionIndex]
                                                  ['situation'];

                                          setState(() {
                                            _currentQuestionIndex++;
                                            _selectedAnswer = null;
                                            if (nextSituationNumber !=
                                                _currentSituationNumber) {
                                              _currentSituationNumber =
                                                  nextSituationNumber;
                                              _isAudioEnabled = true;
                                              _loadNewAudio();
                                            } else {
                                              _isAudioEnabled = false;
                                            }
                                          });
                                        } else {
                                          _timer.cancel();

                                          _userAnswers.add(_selectedAnswer);

                                          await _handleTestCompletion();
                                        }
                                      }
                                    : null,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF2193b0),
                                        Color(0xFF6dd5ed)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: Text(
                                      _currentQuestionIndex <
                                              _questions.length - 1
                                          ? 'Next Question'
                                          : 'Finish Test',
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
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _handleAnswerSelection(String answer) {
    while (_userAnswers.length <= _currentQuestionIndex) {
      _userAnswers.add(null);
    }

    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
      _selectedAnswer = answer;
    });
  }

  void _storeAnswer(String answer) {
    while (_userAnswers.length <= _currentQuestionIndex) {
      _userAnswers.add(null);
    }

    setState(() {
      _userAnswers[_currentQuestionIndex] = answer.trim();
      _selectedAnswer = answer;
    });
  }

  void _loadQuestionsAndAnswers() {
    // No additional code needed here
  }

  Widget _buildOptionButton(String option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                _selectedAnswer == option ? Color(0xFF2193b0) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            _handleAnswerSelection(option);
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
      await _testSessionService.endListeningTest();
      await _testSessionService.markTestAsCompleted('listening');

      // Calculate score based on answered questions
      int correctAnswers = 0;
      for (int i = 0; i < _questions.length; i++) {
        if (_userAnswers.length > i && 
            _userAnswers[i] == _questions[i]['correctAnswer']) {
          correctAnswers++;
        }
      }

      final testDuration = DateTime.now().difference(_startTime);
      final prefs = await SharedPreferences.getInstance();

      // Save test results
      await Future.wait([
        prefs.setInt('listening_test_score', correctAnswers),
        prefs.setInt('listening_test_duration', testDuration.inSeconds),
        prefs.setBool('listening_test_completed', true),
        prefs.setInt('listening_total_questions', _questions.length),
      ]);

      // Save to Firestore
      try {
        final authService = AuthService();
        final testResultsService = TestResultsService(authService.projectId);
        final userId = await authService.getUserId();

        final result = TestResult(
          userId: userId ?? 'anonymous',
          firstName: widget.firstName,
          lastName: widget.lastName,
          testType: 'Listening Test',
          score: correctAnswers,
          totalQuestions: _questions.length,
          timestamp: DateTime.now(),
        );

        await testResultsService.saveTestResult(result);
      } catch (e) {
        print('Error saving test result: $e');
      }

      // Notify parent and navigate back
      widget.onTestComplete?.call(testDuration, correctAnswers);
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    }
  }
}
