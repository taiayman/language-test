import 'package:alc_eljadida_tests/screens/registration_page.dart';
import 'package:alc_eljadida_tests/services/score_calculator.dart';
import 'package:alc_eljadida_tests/services/test_session_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alc_eljadida_tests/services/firestore_service.dart';
import 'package:alc_eljadida_tests/services/auth_service.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestResultsPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const TestResultsPage({
    Key? key,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  _TestResultsPageState createState() => _TestResultsPageState();
}

// First, add this class outside of _TestResultsPageState
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 5;
    const dashSpace = 3;
    double startY = 0;
    
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TestResultsPageState extends State<TestResultsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = true;
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy - HH:mm');

  @override
  void initState() {
    super.initState();
    _loadTestResults();
  }

  Future<void> _loadTestResults() async {
    try {
      setState(() => _isLoading = true);
      final results = await _firestoreService.fetchTestResults(
        widget.firstName,
        widget.lastName
      );
      if (mounted) {
        setState(() {
          _testResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching results: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load test results')),
        );
      }
    }
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 90) return Color(0xFF4CAF50);
    if (percentage >= 80) return Color(0xFF8BC34A);
    if (percentage >= 70) return Color(0xFF2196F3);
    if (percentage >= 60) return Color(0xFFFFA726);
    if (percentage >= 50) return Color(0xFFFF7043);
    return Color(0xFFE53935);
  }

  String _formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildScoreCard(Map<String, dynamic> result) {
    try {
      final scores = {
        'listening': int.parse(result['listeningScore']?['integerValue'] ?? '0'),
        'reading': int.parse(result['readingScore']?['integerValue'] ?? '0'),
        'grammar': int.parse(result['grammarScore']?['integerValue'] ?? '0'),
      };
      
      final maxScores = {
        'listening': int.parse(result['listeningMaxScore']?['integerValue'] ?? '100'),
        'reading': int.parse(result['readingMaxScore']?['integerValue'] ?? '100'),
        'grammar': int.parse(result['grammarMaxScore']?['integerValue'] ?? '100'),
      };
      
      final durations = {
        'listening': int.parse(result['listeningDuration']?['integerValue'] ?? '0'),
        'reading': int.parse(result['readingDuration']?['integerValue'] ?? '0'),
        'grammar': int.parse(result['grammarDuration']?['integerValue'] ?? '0'),
      };
      
      final totalScore = int.parse(result['totalScore']?['integerValue'] ?? '0');
      final maxTotalScore = int.parse(result['maxTotalScore']?['integerValue'] ?? '300');
      
      final timestamp = DateTime.parse(result['timestamp']?['timestampValue'] ?? DateTime.now().toIso8601String());
      final formattedDate = _dateFormatter.format(timestamp);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Thank You Section
            Container(
              margin: EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Thank You for Completing the Test!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Here are your detailed results',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoChip(
                        Icons.person_outline,
                        '${widget.firstName} ${widget.lastName}',
                      ),
                      SizedBox(width: 16),
                      _buildInfoChip(
                        Icons.calendar_today_outlined,
                        _dateFormatter.format(timestamp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Existing Ticket Card
            _buildALCLevelTicket(totalScore),
            
            // Rest of the score card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Container(
                padding: EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Results',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2193b0),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2193b0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ALC Level: ${ScoreCalculator.calculateALCLevel(totalScore)}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2193b0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    
                    // Score Grid
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.5,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildTestModule(
                          'Listening',
                          scores['listening']!,
                          maxScores['listening']!,
                          durations['listening']!,
                          MaterialCommunityIcons.headphones,
                        ),
                        _buildTestModule(
                          'Reading',
                          scores['reading']!,
                          maxScores['reading']!,
                          durations['reading']!,
                          MaterialCommunityIcons.book_open_variant,
                        ),
                        _buildTestModule(
                          'Grammar',
                          scores['grammar']!,
                          maxScores['grammar']!,
                          durations['grammar']!,
                          MaterialCommunityIcons.format_text,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Total Score Section
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Score',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '$totalScore/$maxTotalScore',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor((totalScore * 100) ~/ maxTotalScore),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 64,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _formatDuration(
                                    durations['listening']! +
                                    durations['reading']! +
                                    durations['grammar']!
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2193b0),
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
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error building score card: $e');
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Error displaying result'),
        ),
      );
    }
  }

  Widget _buildTestModule(
    String name,
    int score,
    int maxScore,
    int duration,
    IconData icon,
  ) {
    final percentage = (score * 100) ~/ maxScore;
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF2193b0), size: 24),
              SizedBox(width: 12),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$score/$maxScore',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(percentage),
                    ),
                  ),
                  Text(
                    '${_formatDuration(duration)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(percentage).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(percentage),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2193b0),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF2193b0)),
            onPressed: () => _handleBack(context),
          ),
          title: Text(
            'Test Results',
            style: GoogleFonts.poppins(
              color: Color(0xFF2193b0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading test results...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _testResults.isEmpty
                ? Center(
                    child: Text(
                      'No test results found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 1200),
                        child: Column(
                          children: _testResults
                              .map((result) => _buildScoreCard(result))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Show exit confirmation dialog
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
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Color(0xFF2193b0),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  Text(
                    'Exit Test',
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
                                'Ready to finish?',
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
                          'Your results have been saved successfully. You can now exit the test.',
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
                        onPressed: () => Navigator.pop(context, false),
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
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
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
                                  'Exit',
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
        // Clear all preferences
        await Future.wait([
          prefs.remove('listening_test_completed'),
          prefs.remove('reading_test_completed'),
          prefs.remove('grammar_test_completed'),
          prefs.remove('listening_test_score'),
          prefs.remove('reading_test_score'),
          prefs.remove('grammar_test_score'),
          prefs.remove('listening_test_duration'),
          prefs.remove('reading_test_duration'),
          prefs.remove('grammar_test_duration'),
          prefs.remove('current_student_first_name'),
          prefs.remove('current_student_last_name'),
          prefs.remove('current_session_id'),
          prefs.remove('results_save_status'),
          prefs.remove('current_question_index'),
          prefs.remove('user_answers'),
        ]);
        
        await TestSessionService().clearAllSessions();
        await AuthService().signOut();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => RegistrationPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during back navigation: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Error returning to registration. Please try again.',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleBack(context),
          ),
        ),
      );
    }
  }

  String _getEvolveLevel(int score) {
    final levels = {
      69: 'EVOLVE Level 6B',
      62: 'EVOLVE Level 6A',
      56: 'EVOLVE Level 5B',
      50: 'EVOLVE Level 5A',
      43: 'EVOLVE Level 4B',
      37: 'EVOLVE Level 4A',
      31: 'EVOLVE Level 3B',
      24: 'EVOLVE Level 3A',
      18: 'EVOLVE Level 2B',
      12: 'EVOLVE Level 2A',
      6: 'EVOLVE Level 1B',
      1: 'EVOLVE Level 1A',
    };

    for (var threshold in levels.keys) {
      if (score >= threshold) return levels[threshold]!;
    }
    return 'Pre-EVOLVE Level';
  }

  Widget _buildLevelIndicator(String evolveLevel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2193b0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFF2193b0).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 20,
            color: Color(0xFF2193b0),
          ),
          SizedBox(width: 8),
          Text(
            evolveLevel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2193b0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int percentage) {
    return Container(
      height: 4,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage / 100,
        child: Container(
          decoration: BoxDecoration(
            color: _getScoreColor(percentage),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF2193b0)),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2193b0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildALCLevelTicket(int totalScore) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          // Main Ticket Body
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side with level info
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF2193b0).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school,
                          color: Color(0xFF2193b0),
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Your Level',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ALC Level: ${ScoreCalculator.calculateALCLevel(totalScore)}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2193b0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Dotted line separator
                Container(
                  height: 60,
                  child: CustomPaint(
                    painter: DottedLinePainter(),
                  ),
                ),
                
                // Right side with score
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Score',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$totalScore/70',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor((totalScore * 100) ~/ 70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Circular cutouts for ticket effect
          ...List.generate(2, (index) {
            return Positioned(
              top: index == 0 ? -15 : null,
              bottom: index == 1 ? -15 : null,
              left: MediaQuery.of(context).size.width * 0.6 - 15,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xFF2193b0),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}