import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'home_page.dart'; // Make sure to import the HomePage

class InstructionPage extends StatefulWidget {
  const InstructionPage({super.key});

  @override
  State<InstructionPage> createState() => _InstructionPageState();
}

class _InstructionPageState extends State<InstructionPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
                    _buildProgressIndicator(), // Add progress indicator
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
                    // Navigation buttons
                    Container(
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
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2193b0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 80,
              color: const Color(0xFF2193b0),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2193b0),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              slide.content,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                height: 1.6,
                color: Colors.black87,
              ),
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
