import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'home_page.dart';

class InstructionPage extends StatefulWidget {
  const InstructionPage({super.key});

  @override
  State<InstructionPage> createState() => _InstructionPageState();
}

class _InstructionPageState extends State<InstructionPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final Player _player;
  late final VideoController _controller;
  bool _isVideoInitialized = false;
  // Add offset state for draggable video
  Offset _videoPosition = const Offset(24, -24); // Initial position at the very bottom left with small padding

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _player = Player();
      _controller = VideoController(_player);
      
      await _player.open(Media('asset:///assets/videos/welcome_video.mp4'));
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _player.play();
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  final List<InstructionSlide> _slides = [
    InstructionSlide(
      title: 'Listening Section',
      content: 'You will have 15 minutes to answer 20 audio questions. Each question has multiple choice answers (a, b, c, d).',
      icon: MaterialCommunityIcons.headphones,
    ),
    InstructionSlide(
      title: 'Reading Section',
      content: 'You will be presented with reading comprehension questions. Each question has multiple choice answers (a, b, c, d).',
      icon: MaterialCommunityIcons.book_open_variant,
    ),
    InstructionSlide(
      title: 'Language in Use',
      content: 'Test your grammar and vocabulary knowledge through multiple choice questions. Pay attention to sentence structure and word usage.',
      icon: MaterialCommunityIcons.translate,  // Changed icon to be more appropriate
    ),
    // ... Ajoutez plus de diapositives si nécessaire
  ];

  // Add progress indicator
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Added vertical padding
      margin: const EdgeInsets.only(top: 20), // Added top margin
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center the indicators
        children: List.generate(_slides.length, (index) {
          return Container(
            width: 80, // Fixed width instead of Expanded
            height: 6, // Slightly taller
            margin: const EdgeInsets.symmetric(horizontal: 8), // Increased spacing
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _currentPage >= index
                  ? const Color(0xFF2193b0)
                  : Colors.grey.withOpacity(0.3),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Row(
          children: [
            // Enhanced Sidebar
            Container(
              width: 280, // Slightly wider
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFC6352),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return _buildSidebarItem(
                          title: _slides[index].title,
                          isSelected: _currentPage == index,
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Enhanced Main content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildProgressIndicator(),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _slides.length,
                              onPageChanged: (int page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              itemBuilder: (context, index) {
                                return _buildSlide(_slides[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isVideoInitialized)
                      Expanded(
                        flex: 6,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Center(
                                  child: Video(
                                    controller: _controller,
                                    controls: AdaptiveVideoControls,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNavigationButton(
                            onPressed: _currentPage > 0
                                ? () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: Icons.arrow_back,
                            label: 'Previous',
                          ),
                          _buildNavigationButton(
                            onPressed: _currentPage < _slides.length - 1
                                ? () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (context) => const HomePage()),
                                    );
                                  },
                            icon: _currentPage < _slides.length - 1 ? Icons.arrow_forward : Icons.play_arrow,
                            label: _currentPage < _slides.length - 1 ? 'Next' : 'Start Test',
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isSelected
            ? LinearGradient(
                colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  // Update the slide building method
  Widget _buildSlide(InstructionSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 36,
              color: const Color(0xFF2193b0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2193b0),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.content,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isPrimary ? Colors.white : Colors.black87),
              SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isPrimary ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructionSlide {
  final String title;
  final String content;
  final IconData icon;

  InstructionSlide({
    required this.title,
    required this.content,
    required this.icon,
  });
}
