import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:just_audio/just_audio.dart';

class VideoOverlay extends StatefulWidget {
  final String videoType;
  final VoidCallback onClose;
  final bool showCloseButton;
  final bool showTutorial;

  const VideoOverlay({
    Key? key,
    required this.videoType,
    required this.onClose,
    this.showCloseButton = true,
    this.showTutorial = true,
  }) : super(key: key);

  @override
  State<VideoOverlay> createState() => _VideoOverlayState();
}

class _VideoOverlayState extends State<VideoOverlay> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showTutorial = false;
  final ScrollController _scrollController = ScrollController();

  final Map<String, dynamic> _tutorialExercise = {
    'situation': 'Example',
    'audioUrl': 'assets/audio/test_exemple.mp3',
    'question': 'Example Situation: A man is asking a woman for directions.\nThe Science Museum:',
    'options': [
      'a) isn\'t near the hospital',
      'b) is on the left side of the street',
      'c) is two blocks from the hospital',
      'd) and the hospital are on the same street'
    ],
    'correctAnswer': 'd) and the hospital are on the same street',
  };
  String? _selectedAnswer;
  bool _hasFinishedPlaying = false;
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  bool _hasSelectedCorrectAnswer = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    if (widget.videoType.toLowerCase() == 'listening') {
      _audioPlayer = AudioPlayer();
      _loadTutorialAudio();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final videoPath = _getVideoAsset();
      print('Attempting to load video from: $videoPath');
      
      // Initialize player
      _player = Player();
      _controller = VideoController(_player);
      
      // Open the video file
      await _player.open(Media('asset:///$videoPath'));
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _errorMessage = null;
        });
        _player.play();
      }
    } catch (e, stackTrace) {
      print('Error initializing video: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _getVideoAsset() {
    switch (widget.videoType.toLowerCase()) {
      case 'listening':
        return 'assets/videos/listening_instructions.mp4';
      case 'reading':
        return 'assets/videos/reading_instructions.mp4';
      case 'grammar':
        return 'assets/videos/grammar_instructions.mp4';
      default:
        throw Exception('Unknown video type: ${widget.videoType}');
    }
  }

  Future<void> _loadTutorialAudio() async {
    try {
      await _audioPlayer.setAsset(_tutorialExercise['audioUrl']);
      _duration = await _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
        if (mounted) {
          setState(() => _bufferedPosition = bufferedPosition);
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _hasFinishedPlaying = true;
            }
          });
        }
      });
    } catch (e) {
      print('Error loading tutorial audio: $e');
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
      print('Error playing/pausing tutorial audio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    if (widget.videoType.toLowerCase() == 'listening') {
      _audioPlayer.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 800,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              margin: EdgeInsets.all(32),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _showTutorial && widget.videoType.toLowerCase() == 'listening'
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Scrollbar(
                          controller: _scrollController,
                          thickness: 8,
                          radius: Radius.circular(4),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: _buildTutorialContent(),
                            ),
                          ),
                        ),
                      )
                    : _buildVideoContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice Exercise',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try this example before starting the test',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Audio Player Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              // Play/Pause Button
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 48,
                  color: Color(0xFF2193b0),
                ),
                onPressed: _handlePlayPause,
              ),
              SizedBox(height: 16),
              
              // Progress Bar
              SliderTheme(
                data: SliderThemeData(
                  thumbColor: Color(0xFF2193b0),
                  activeTrackColor: Color(0xFF2193b0),
                  inactiveTrackColor: Colors.grey[300],
                  trackHeight: 4.0,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble(),
                  max: _duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              
              // Duration Labels
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Question Text
        Text(
          _tutorialExercise['question'],
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 24),

        // Answer Options
        ...(_tutorialExercise['options'] as List<String>).map((option) {
          bool isSelected = _selectedAnswer == option;
          bool isCorrect = option == _tutorialExercise['correctAnswer'];
          
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAnswer = option;
                  if (isCorrect) {
                    _hasSelectedCorrectAnswer = true;
                    _feedbackMessage = 'Correct! You can now start the test.';
                  } else {
                    _hasSelectedCorrectAnswer = false;
                    _feedbackMessage = 'Try again. Hint: Listen carefully to where both buildings are located.';
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1))
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.error,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        
        // Feedback Message
        if (_feedbackMessage != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hasSelectedCorrectAnswer 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasSelectedCorrectAnswer 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasSelectedCorrectAnswer 
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _hasSelectedCorrectAnswer 
                      ? Colors.green
                      : Colors.orange,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedbackMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _hasSelectedCorrectAnswer 
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        SizedBox(height: 24),

        // Continue Button
        ElevatedButton(
          onPressed: _hasSelectedCorrectAnswer ? widget.onClose : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2193b0),
            disabledBackgroundColor: Colors.grey[300],
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _hasSelectedCorrectAnswer ? 'Start Test' : 'Select the Correct Answer',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        
        if (!_hasSelectedCorrectAnswer && _selectedAnswer != null) ...[
          SizedBox(height: 12),
          Text(
            'Please select the correct answer to continue',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${widget.videoType} Test Instructions',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.showCloseButton)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        // Video content
        Flexible(
          child: Container(
            padding: EdgeInsets.all(24),
            child: _hasError
                ? _buildErrorState()
                : !_isInitialized
                    ? _buildLoadingState()
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Video(
                          controller: _controller,
                          controls: null,
                        ),
                      ),
          ),
        ),
        // Controls
        if (_isInitialized && !_hasError)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: _buildVideoControls(),
          ),
        // Action Buttons
        Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  if (widget.videoType.toLowerCase() == 'listening') {
                    await _player.pause(); // Stop video playback
                    setState(() => _showTutorial = true);
                  } else {
                    widget.onClose();
                  }
                },
                child: Text(
                  'Skip Video',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  if (widget.videoType.toLowerCase() == 'listening') {
                    await _player.pause(); // Stop video playback
                    setState(() => _showTutorial = true);
                  } else {
                    widget.onClose();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2193b0),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24, 
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'Failed to load video',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2193b0),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar and time
        Row(
          children: [
            StreamBuilder<Duration>(
              stream: _player.stream.position,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return Text(
                  _formatDuration(position),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: _player.stream.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: _player.stream.duration,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return SliderTheme(
                        data: SliderThemeData(
                          thumbColor: Color(0xFF2193b0),
                          activeTrackColor: Color(0xFF2193b0),
                          inactiveTrackColor: Colors.grey[300],
                          trackHeight: 4.0,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble(),
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _player.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            StreamBuilder<Duration>(
              stream: _player.stream.duration,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return Text(
                  _formatDuration(duration),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ],
        ),
        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10),
              color: Colors.grey[600],
              onPressed: () {
                _player.seek(Duration(
                  milliseconds: (_player.state.position.inMilliseconds - 10000).clamp(0, _player.state.duration.inMilliseconds),
                ));
              },
            ),
            StreamBuilder<bool>(
              stream: _player.stream.playing,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 48,
                  ),
                  color: Color(0xFF2193b0),
                  onPressed: () {
                    if (isPlaying) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.forward_10),
              color: Colors.grey[600],
              onPressed: () {
                _player.seek(Duration(
                  milliseconds: (_player.state.position.inMilliseconds + 10000).clamp(0, _player.state.duration.inMilliseconds),
                ));
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}