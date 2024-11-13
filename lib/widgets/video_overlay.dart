import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoOverlay extends StatefulWidget {
  final String videoType;
  final VoidCallback onClose;
  final bool showCloseButton;

  const VideoOverlay({
    Key? key,
    required this.videoType,
    required this.onClose,
    this.showCloseButton = true,
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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          
          // Content
          Center(
            child: SingleChildScrollView(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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

                      if (_hasError)
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Note: The instruction video is currently unavailable. '
                            'You may proceed with the test or try again later.',
                            style: GoogleFonts.poppins(
                              color: Colors.orange[700],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Video or Error/Loading State
                      Container(
                        height: 400, // Fixed height for video container
                        margin: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _hasError 
                              ? _buildErrorState()
                              : !_isInitialized 
                                  ? _buildLoadingState()
                                  : _buildVideoPlayer(),
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
                              onPressed: widget.onClose,
                              child: Text(
                                'Skip Video',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: widget.onClose,
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
                                'Start Test',
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return _buildErrorState();
    }
    if (!_isInitialized) {
      return _buildLoadingState();
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Video(
          controller: _controller,
          controls: NoVideoControls,
        ),
        _buildPlayPauseOverlay(),
      ],
    );
  }

  Widget _buildPlayPauseOverlay() {
    return StreamBuilder<bool>(
      stream: _player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return GestureDetector(
          onTap: () {
            isPlaying ? _player.pause() : _player.play();
          },
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 64,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoControls() {
    return Row(
      children: [
        StreamBuilder<Duration>(
          stream: _player.stream.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: _player.stream.duration,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return Text(
                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                );
              },
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
                  return Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _player.seek(Duration(milliseconds: value.toInt()));
                    },
                  );
                },
              );
            },
          ),
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