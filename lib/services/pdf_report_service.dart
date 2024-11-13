import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PDFReportService {
  static final accentColor = PdfColors.blue700;
  static final backgroundColor = PdfColors.grey100;
  static final cardColor = PdfColors.white;

  static Future<Uint8List> generateTestReport({
    required String firstName,
    required String lastName,
    required Map<String, dynamic> testData,
    required List<Map<String, dynamic>> answers,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      ),
    );
    final dateFormatter = DateFormat('MMMM dd, yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(firstName, lastName),
          _buildSummary(testData),
          _buildScoresSection(testData),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String firstName, String lastName) {
    return pw.Container(
      padding: pw.EdgeInsets.all(30),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Test Results Report',
            style: pw.TextStyle(
              fontSize: 28,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: cardColor,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Student',
                      style: pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      '$firstName $lastName',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Date',
                      style: pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now()),
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(Map<String, dynamic> testData) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 20),
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: cardColor,
        borderRadius: pw.BorderRadius.circular(15),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 25,
                margin: pw.EdgeInsets.only(right: 10),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
              ),
              pw.Text(
                'Test Summary',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Total Score', '${testData['totalScore']}/70'),
              _buildSummaryCard('ALC Level', testData['alcLevel']),
              _buildSummaryCard('Duration', _formatDuration(testData['totalDuration'])),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(String label, String value) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildScoresSection(Map<String, dynamic> testData) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Detailed Scores',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildScoreTable(testData),
        ],
      ),
    );
  }

  static pw.Widget _buildScoreTable(Map<String, dynamic> testData) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Table(
        border: pw.TableBorder.symmetric(
          inside: pw.BorderSide(color: PdfColors.grey300),
        ),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: backgroundColor,
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(10)),
            ),
            children: [
              _buildTableCell('Test Section', header: true),
              _buildTableCell('Score', header: true),
              _buildTableCell('Duration', header: true),
            ],
          ),
          _buildScoreRow('Listening', testData['listeningScore'], testData['listeningDuration']),
          _buildScoreRow('Reading', testData['readingScore'], testData['readingDuration']),
          _buildScoreRow('Grammar', testData['grammarScore'], testData['grammarDuration']),
        ],
      ),
    );
  }

  static pw.TableRow _buildScoreRow(String section, int score, Duration duration) {
    return pw.TableRow(
      children: [
        _buildTableCell(section),
        _buildTableCell('$score'),
        _buildTableCell(_formatDuration(duration)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool header = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: header ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}