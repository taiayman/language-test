import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:alc_eljadida_tests/services/score_calculator.dart';

class PDFReportService {
  static final accentColor = PdfColors.blue700;
  static final backgroundColor = PdfColors.grey100;
  static final cardColor = PdfColors.white;
  static final correctColor = PdfColors.green700;
  static final incorrectColor = PdfColors.red700;

  static Future<Uint8List> generateTestReport({
    required String firstName,
    required String lastName,
    required Map<String, dynamic> testData,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      // Extract scores from Firestore data structure
      final listeningScore = int.tryParse(testData['listeningScore']?['integerValue']?.toString() ?? '0') ?? 0;
      final readingScore = int.tryParse(testData['readingScore']?['integerValue']?.toString() ?? '0') ?? 0;
      final grammarScore = int.tryParse(testData['grammarScore']?['integerValue']?.toString() ?? '0') ?? 0;
      final totalScore = listeningScore + readingScore + grammarScore;

      // Parse timestamp
      DateTime testDate = DateTime.now();
      try {
        testDate = DateTime.parse(testData['timestamp']?['timestampValue']?.toString() ?? '');
      } catch (e) {
        print('Error parsing timestamp: $e');
      }

      // Group answers by test type
      final groupedAnswers = _groupAnswersByType(answers);

      // Create PDF document
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
        ),
      );

      // Add cover page
      pdf.addPage(
        pw.Page(
          build: (context) => _buildCoverPage(
            firstName: firstName,
            lastName: lastName,
            testDate: testDate,
            totalScore: totalScore,
          ),
        ),
      );

      // Add test summary page
      pdf.addPage(
        pw.Page(
          build: (context) => _buildScoreSummaryPage(
            listeningScore: listeningScore,
            readingScore: readingScore,
            grammarScore: grammarScore,
            totalScore: totalScore,
          ),
        ),
      );

      // Add detailed answers pages
      for (var testType in ['Listening', 'Reading', 'Grammar']) {
        if (groupedAnswers[testType]?.isNotEmpty ?? false) {
          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              build: (context) => [
                _buildTestTypeHeader(testType),
                ...groupedAnswers[testType]!.map((answer) => 
                  _buildDetailedAnswerSection(answer, testType)
                ).toList(),
              ],
            ),
          );
        }
      }

      return pdf.save();
    } catch (e, stack) {
      print('Error generating PDF report: $e');
      print('Stack trace: $stack');
      throw Exception('Failed to generate PDF report: $e');
    }
  }

  static pw.Widget _buildCoverPage({
    required String firstName,
    required String lastName,
    required DateTime testDate,
    required int totalScore,
  }) {
    final alcLevel = ScoreCalculator.calculateALCLevel(totalScore);
    
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: accentColor, width: 2),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'TEST RESULTS REPORT',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  '$firstName $lastName',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'ALC Level: $alcLevel',
                  style: pw.TextStyle(
                    fontSize: 20,
                    color: accentColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  DateFormat('MMMM dd, yyyy').format(testDate),
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    'Total Score: $totalScore/70',
                    style: pw.TextStyle(
                      fontSize: 20,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildScoreSummaryPage({
    required int listeningScore,
    required int readingScore,
    required int grammarScore,
    required int totalScore,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Score Summary',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 30),
          _buildScoreBreakdown(
            'Listening Test',
            listeningScore,
            20,
            'Assessment of listening comprehension skills',
          ),
          pw.SizedBox(height: 20),
          _buildScoreBreakdown(
            'Reading Test',
            readingScore,
            20,
            'Evaluation of reading comprehension abilities',
          ),
          pw.SizedBox(height: 20),
          _buildScoreBreakdown(
            'Grammar Test',
            grammarScore,
            30,
            'Assessment of grammar and language structure knowledge',
          ),
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 20),
          _buildTotalScoreSection(totalScore),
        ],
      ),
    );
  }

  static pw.Widget _buildScoreBreakdown(
    String title,
    int score,
    int maxScore,
    String description,
  ) {
    final percentage = (score / maxScore * 100).round();
    
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '$score/$maxScore',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            description,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 10,
            child: pw.ClipRRect(
              verticalRadius: 5,
              horizontalRadius: 5,
              child: pw.Stack(
                children: [
                  pw.Container(
                    color: PdfColors.grey300,
                  ),
                  pw.Container(
                    width: score / maxScore * 500,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '$percentage%',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalScoreSection(int totalScore) {
    final alcLevel = ScoreCalculator.calculateALCLevel(totalScore);
    final percentage = (totalScore / 70 * 100).round();
    
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Total Score',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '$totalScore/70 ($percentage%)',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'ALC Level: $alcLevel',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTestTypeHeader(String testType) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$testType Test - Detailed Answers',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey300),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailedAnswerSection(
    Map<String, dynamic> answer,
    String testType,
  ) {
    final isCorrect = answer['isCorrect'] as bool;
    final backgroundColor = isCorrect ? PdfColors.green50 : PdfColors.red50;
    
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 20),
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        border: pw.Border.all(
          color: isCorrect ? PdfColors.green200 : PdfColors.red200,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Question ${answer['questionNumber']}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: isCorrect ? correctColor : incorrectColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  isCorrect ? 'Correct' : 'Incorrect',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            answer['question'],
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Your answer:',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                answer['userAnswer'],
                style: pw.TextStyle(
                  fontSize: 12,
                  color: isCorrect ? correctColor : incorrectColor,
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Correct answer:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  answer['correctAnswer'],
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: correctColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Map<String, List<Map<String, dynamic>>> _groupAnswersByType(
    List<Map<String, dynamic>> answers
  ) {
    return {
      'Listening': answers.where((a) => a['section'] == 'listening').toList(),
      'Reading': answers.where((a) => a['section'] == 'reading').toList(),
      'Grammar': answers.where((a) => a['section'] == 'grammar').toList(),
    };
  }

  static pw.Widget _buildAnswerOptionsSection(List<String> options) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Answer Options:',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        ...options.map((option) => pw.Padding(
          padding: pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            option,
            style: pw.TextStyle(fontSize: 10),
          ),
        )).toList(),
      ],
    );
  }

  static String _getScoreCategory(int score, int maxScore) {
    final percentage = (score / maxScore) * 100;
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Very Good';
    if (percentage >= 70) return 'Good';
    if (percentage >= 60) return 'Fair';
    if (percentage >= 50) return 'Needs Improvement';
    return 'Requires Attention';
  }

  static String _getRecommendation(String testType, int score, int maxScore) {
    final percentage = (score / maxScore) * 100;
    
    if (percentage >= 80) {
      return 'Keep up the excellent work! Consider moving to more advanced $testType exercises.';
    } else if (percentage >= 60) {
      return 'Good progress. Focus on challenging $testType tasks to further improve your skills.';
    } else {
      switch (testType.toLowerCase()) {
        case 'listening':
          return 'Regular practice with varied listening materials and native speakers is recommended.';
        case 'reading':
          return 'Try reading diverse materials and focus on comprehension strategies.';
        case 'grammar':
          return 'Review fundamental grammar rules and practice with structured exercises.';
        default:
          return 'Additional practice and structured learning is recommended.';
      }
    }
  }

  static pw.Widget _buildPerformanceAnalysis(
    String testType,
    int score,
    int maxScore,
    List<Map<String, dynamic>> answers,
  ) {
    final correctAnswers = answers.where((a) => a['isCorrect'] == true).length;
    final incorrectAnswers = answers.length - correctAnswers;
    final percentage = (score / maxScore) * 100;

    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 20),
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Performance Analysis',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatisticBox(
                'Correct Answers',
                correctAnswers.toString(),
                correctColor,
              ),
              _buildStatisticBox(
                'Incorrect Answers',
                incorrectAnswers.toString(),
                incorrectColor,
              ),
              _buildStatisticBox(
                'Success Rate',
                '${percentage.round()}%',
                accentColor,
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Category: ${_getScoreCategory(score, maxScore)}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Recommendation:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _getRecommendation(testType, score, maxScore),
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatisticBox(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(String timestampValue) {
    try {
      final dateTime = DateTime.parse(timestampValue);
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  static pw.Widget _buildFooter(String studentName, int pageNumber) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            studentName,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Page $pageNumber',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWatermark() {
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.5,
        child: pw.Text(
          'ALC El Jadida',
          style: pw.TextStyle(
            color: PdfColors.grey300,
            fontSize: 60,
          ),
        ),
      ),
    );
  }
}