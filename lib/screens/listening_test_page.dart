import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:test_windows_students/screens/listening_test_results_page.dart';
import 'package:test_windows_students/services/auth_service.dart';
import 'package:test_windows_students/services/test_results_service.dart';
import 'package:test_windows_students/models/test_result.dart';
import 'package:test_windows_students/services/test_session_service.dart';

// Add this class before ListeningTestPage class
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,  // Changed from SliderTheme to SliderThemeData
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double? trackHeight = sliderTheme.trackHeight;  // Removed .data since SliderThemeData already has trackHeight
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - (trackHeight ?? 4)) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight ?? 4);
  }
}

class ListeningTestPage extends StatefulWidget {
  final Duration? remainingTime;
  final String firstName;
  final String lastName;
  
  const ListeningTestPage({
    Key? key, 
    this.remainingTime,
    required this.firstName,
    required this.lastName,
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
  // Initialize _remainingTime here
  Duration _remainingTime = Duration(minutes: 15);
  double _progress = 1.0;
  // Add these properties to your _ListeningTestPageState class
  Duration _bufferedPosition = Duration.zero;
  bool _isSeeking = false;
  double? _dragValue;
  // Add this property to _ListeningTestPageState
  List<String?> _userAnswers = [];
  // Add these controllers at the top of your _ListeningTestPageState class
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TestSessionService _testSessionService = TestSessionService();

  // Example question data structure
  final List<Map<String, dynamic>> _questions = [
    {
      'audioUrl': 'assets/audio/situation1.mp3',
      'question': 'Situation 1: Emily and Jason are talking about work.\nWhat is true about Emily?',
      'options': [
        'A) Works at a café',
        'B) Never goes to the mall',
        'C) Works every weekend',
        'D) Goes to the mall every day'
      ],
      'correctAnswer': 'A) Works at a café',
    },
    {
      'audioUrl': 'assets/audio/situation2.mp3',
      'question': 'Situation 2: Jessica is buying clothes.\nWhat is true about Jessica?',
      'options': [
        'A) Is buying a dress and a skirt',
        'B) Thinks the skirts are expensive',
        'C) Can\'t find a red skirt',
        'D) Pays \$30 for the skirt'
      ],
      'correctAnswer': 'D) Pays \$30 for the skirt',
    },
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadNewAudio();
    
    // Initialize timer based on remaining time from storage
    _initializeTimer();
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
      final remainingTime = await _testSessionService.getListeningRemainingTime();
      
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
      });

      // Stop current audio if playing
      await _audioPlayer.stop();
      
      // Load the new audio file
      final audioSource = AudioSource.asset(_questions[_currentQuestionIndex]['audioUrl']);
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
      
      setState(() {}); // Update UI with new duration
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

  void _handleTimeUp() async {
    _timer.cancel();  // Stop the timer
    await _testSessionService.endListeningTest();
    await _testSessionService.markTestAsCompleted('listening');  // Mark as completed
    
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
            'Your time for the listening test has ended.',
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
                // Navigate to results page
                Navigator.of(context).pop();
                // Add your navigation logic here
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    // Remove this line to keep the test active when leaving the page
    // _testSessionService.endListeningTest();
    super.dispose();
  }

  // Update the dialog method
  Future<bool?> _showNameInputDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // Make dialog wider for desktop
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4, // 40% of screen width
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
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
                  // First Name field with enhanced styling
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
                  // Last Name field with enhanced styling
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
                  // Buttons with enhanced styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
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
                      // Continue button
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
                              // Show error message if fields are empty
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
        elevation: 0,  // Remove shadow
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF2193b0),
          ),
          onPressed: () {
            // Don't end the test when going back
            Navigator.of(context).pop();
          },
        ),
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
        toolbarHeight: 72, // Added to match other tests
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
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    // Left panel - Question, Audio Controls and Timer
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question and Audio Controls Card (Upper)
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
                                    Spacer(),
                                    // Audio controls
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 24),  // Add padding to container
                                      child: Column(
                                        children: [
                                          // Buffered and played progress bar
                                          Container(
                                            height: 36,  // Fixed height for better touch target
                                            child: Stack(
                                              alignment: Alignment.center,  // Center align the sliders
                                              children: [
                                                // Buffered progress
                                                SliderTheme(
                                                  data: SliderThemeData(
                                                    trackHeight: 4,
                                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0),
                                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                                                    trackShape: CustomTrackShape(),
                                                    // Add these to constrain the buffered track
                                                    rangeTrackShape: RoundedRectRangeSliderTrackShape(),
                                                    showValueIndicator: ShowValueIndicator.never,
                                                  ),
                                                  child: Slider(
                                                    value: min(_bufferedPosition.inSeconds.toDouble(), _duration.inSeconds.toDouble()),
                                                    max: _duration.inSeconds.toDouble(),
                                                    onChanged: null,
                                                    activeColor: Color(0xFF2193b0).withOpacity(0.24),
                                                    inactiveColor: Colors.grey.shade200,
                                                  ),
                                                ),
                                                // Playback progress
                                                SliderTheme(
                                                  data: SliderThemeData(
                                                    trackHeight: 4,
                                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                                                    trackShape: CustomTrackShape(),
                                                    activeTrackColor: Color(0xFF2193b0),
                                                    inactiveTrackColor: Colors.transparent,
                                                    thumbColor: Color(0xFF2193b0),
                                                    overlayColor: Color(0xFF2193b0).withOpacity(0.12),
                                                  ),
                                                  child: Slider(
                                                    value: min(_isSeeking 
                                                        ? _dragValue ?? _position.inSeconds.toDouble() 
                                                        : _position.inSeconds.toDouble(),
                                                        _duration.inSeconds.toDouble()),
                                                    max: _duration.inSeconds.toDouble(),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _dragValue = value;
                                                        _isSeeking = true;
                                                      });
                                                    },
                                                    onChangeEnd: (value) async {
                                                      try {
                                                        final position = Duration(seconds: value.toInt());
                                                        await _audioPlayer.seek(position);
                                                        setState(() {
                                                          _dragValue = null;
                                                          _isSeeking = false;
                                                        });
                                                      } catch (e) {
                                                        print('Error seeking audio: $e');
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Time indicators with proper padding
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(_position),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDuration(_duration),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          // Play/Pause and Replay buttons
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                iconSize: 48,
                                                icon: AnimatedSwitcher(
                                                  duration: Duration(milliseconds: 200),
                                                  transitionBuilder: (child, animation) => ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                                  child: Icon(
                                                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                                    key: ValueKey<bool>(_isPlaying),
                                                    size: 48,
                                                    color: Color(0xFF2193b0),
                                                  ),
                                                ),
                                                onPressed: _handlePlayPause,
                                              ),
                                              SizedBox(width: 16),
                                              IconButton(
                                                iconSize: 48,
                                                icon: Icon(
                                                  Icons.replay_circle_filled,
                                                  size: 48,
                                                  color: Color(0xFF2193b0),
                                                ),
                                                onPressed: () async {
                                                  await _audioPlayer.seek(Duration.zero);
                                                  if (!_isPlaying) {
                                                    await _audioPlayer.play();
                                                  }
                                                },
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
                          // Timer Card (Lower)
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
                    // Right panel - Answer options
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 24.0, right: 8.0),
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
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ..._questions[_currentQuestionIndex]['options']
                                              .map<Widget>((option) => Padding(
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
                                                  ))
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
                                        if (_currentQuestionIndex < _questions.length - 1) {
                                          // Store the answer and continue to next question
                                          _userAnswers.add(_selectedAnswer);
                                          setState(() {
                                            _currentQuestionIndex++;
                                            _selectedAnswer = null;
                                          });
                                          await _loadNewAudio();
                                        } else {
                                          // Stop the timer when finishing the test
                                          _timer.cancel();
                                          
                                          // Store the last answer
                                          _userAnswers.add(_selectedAnswer);
                                          
                                          // Calculate score
                                          int score = 0;
                                          for (int i = 0; i < _questions.length; i++) {
                                            if (_userAnswers[i] == _questions[i]['correctAnswer']) {
                                              score++;
                                            }
                                          }
                                          
                                          // Mark test as completed
                                          await _testSessionService.endListeningTest();
                                          await _testSessionService.markTestAsCompleted('listening');
                                          
                                          // Save test result
                                          final authService = AuthService();
                                          final testResultsService = TestResultsService(authService.projectId);
                                          
                                          final result = TestResult(
                                            userId: authService.getUserId() ?? 'anonymous',
                                            firstName: widget.firstName,  // Use the firstName passed to widget
                                            lastName: widget.lastName,    // Use the lastName passed to widget
                                            testType: 'Listening Test',
                                            score: score,
                                            totalQuestions: _questions.length,
                                            timestamp: DateTime.now(),
                                          );
                                          
                                          try {
                                            await testResultsService.saveTestResult(result);
                                            
                                            // Navigate to results page
                                            if (!mounted) return;
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) => ListeningTestResultsPage(
                                                  score: score,
                                                  totalQuestions: _questions.length,
                                                  questions: _questions,
                                                  userAnswers: _userAnswers,
                                                  firstName: widget.firstName,  // Use the firstName passed to widget
                                                  lastName: widget.lastName,    // Use the lastName passed to widget
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
                                      _currentQuestionIndex < _questions.length - 1
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

  // Add this method to format the remaining time
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Add these helper methods to your _ListeningTestPageState class
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
