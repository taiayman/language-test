import 'package:alc_eljadida_tests/services/score_calculator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alc_eljadida_tests/services/firestore_service.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:alc_eljadida_tests/screens/selection_page.dart';
import 'package:printing/printing.dart';
import 'package:alc_eljadida_tests/services/pdf_report_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:alc_eljadida_tests/screens/registration_page.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy HH:mm');
  bool _isLoading = true;

  int _totalStudents = 0;
  int _totalTests = 0;
  double _averageScore = 0;
  List<Map<String, dynamic>> _recentTests = [];
  Map<String, int> _testTypeCounts = {
    'Listening': 0,
    'Reading': 0,
    'Grammar': 0
  };

  String _selectedPage = 'Overview';

  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  String _codeSearchQuery = '';
  List<Map<String, dynamic>> _codeSearchResults = [];
  bool _isCodeSearching = false;

  final Map<String, bool> _generatingPDFs = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final stats = await _firestoreService.fetchDashboardStats();

      setState(() {
        _totalStudents = stats['totalStudents'] as int;
        _totalTests = stats['totalTests'] as int;
        _averageScore = stats['averageScore'] as double;
        _recentTests = List<Map<String, dynamic>>.from(stats['recentTests']);
        _testTypeCounts = Map<String, int>.from(stats['testTypeCounts']);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            width: 400,
            margin: EdgeInsets.only(bottom: 40),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchStudent(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _firestoreService.searchStudentResults(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching for student'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchByCode(String code) async {
    if (code.isEmpty) {
      setState(() {
        _codeSearchResults = [];
        _isCodeSearching = false;
      });
      return;
    }

    setState(() => _isCodeSearching = true);

    try {
      final results = await _firestoreService.searchBySchoolCode(code);
      setState(() {
        _codeSearchResults = results;
        _isCodeSearching = false;
      });
    } catch (e) {
      print('Error searching by code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching by code'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isCodeSearching = false);
    }
  }

  Future<void> _generatePDFReport(Map<String, dynamic> result) async {
    final timestamp = result['timestamp']?['timestampValue'];
    if (timestamp == null) return;

    setState(() {
      _generatingPDFs[timestamp] = true;
    });

    try {
      final firstName = result['firstName']?['stringValue'] ?? 'Unknown';
      final lastName = result['lastName']?['stringValue'] ?? 'Unknown';
      
      final answers = await _firestoreService.fetchTestAnswers(timestamp);
      
      final pdfData = await PDFReportService.generateTestReport(
        firstName: firstName,
        lastName: lastName,
        testData: result,
        answers: answers.map((a) => Map<String, dynamic>.from(a)).toList(),
      );

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF Report',
        fileName: '${firstName}_${lastName}_test_report.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final String filePath = outputFile.toLowerCase().endsWith('.pdf') 
            ? outputFile 
            : '$outputFile.pdf';
        
        await File(filePath).writeAsBytes(pdfData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF Report saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate PDF report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _generatingPDFs[timestamp] = false;
      });
    }
  }

  Widget _buildSidebarButton(String label, IconData icon,
      {bool isSelected = false, VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap ??
            () {
              setState(() {
                _selectedPage = label;
              });
            },
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF2193b0).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Color(0xFF2193b0) : Colors.grey[600],
                size: 24,
              ),
              SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isSelected ? Color(0xFF2193b0) : Colors.grey[600],
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          'Total Students',
          _totalStudents.toString(),
          MaterialCommunityIcons.account_group,
          Color(0xFF2193b0),
          'Active students who have taken tests',
        ),
        SizedBox(width: 24),
        _buildStatCard(
          'Total Tests',
          _totalTests.toString(),
          MaterialCommunityIcons.file_document,
          Colors.orange,
          'Total number of tests completed',
        ),
        SizedBox(width: 24),
        _buildStatCard(
          'Average Score',
          '${_averageScore.toStringAsFixed(1)}%',
          MaterialCommunityIcons.chart_line,
          Colors.green,
          'Average score across all tests',
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      String tooltip) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: color,
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
    );
  }

  Widget _buildRecentTestsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Test Results',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.visibility),
                    label: Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF2193b0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 48,
                dataRowHeight: 56,
                columnSpacing: 32,
                headingTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2193b0),
                ),
                columns: [
                  DataColumn(label: Text('Student Name')),
                  DataColumn(label: Text('Listening (/20)')),
                  DataColumn(label: Text('Reading (/20)')),
                  DataColumn(label: Text('Grammar (/30)')),
                  DataColumn(label: Text('Total (/70)')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _recentTests.map((result) {
                  final listeningScore = int.parse(
                      result['listeningScore']?['integerValue'] ?? '0');
                  final readingScore =
                      int.parse(result['readingScore']?['integerValue'] ?? '0');
                  final grammarScore =
                      int.parse(result['grammarScore']?['integerValue'] ?? '0');
                  final totalScore =
                      listeningScore + readingScore + grammarScore;
                  final timestamp =
                      DateTime.parse(result['timestamp']['timestampValue']);

                  return DataRow(
                    cells: [
                      DataCell(Text(
                        '${result['firstName']['stringValue']} ${result['lastName']['stringValue']}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      )),
                      DataCell(_buildScoreCell(listeningScore, 20)),
                      DataCell(_buildScoreCell(readingScore, 20)),
                      DataCell(_buildScoreCell(grammarScore, 30)),
                      DataCell(_buildScoreCell(totalScore, 70)),
                      DataCell(Text(
                        _dateFormatter.format(timestamp),
                        style: GoogleFonts.poppins(),
                      )),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: IconButton(
                                icon: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                                      ),
                                    )
                                  : Icon(Icons.download_rounded, 
                                      color: Color(0xFF2193b0)),
                                onPressed: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                  ? null
                                  : () => _generatePDFReport(result),
                                tooltip: 'Download PDF Report',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDistributionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Distribution',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2193b0),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _testTypeCounts.entries.map((entry) {
                return Expanded(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2193b0).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF2193b0).withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          entry.value.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2193b0),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${entry.key}\nTests',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int totalScore) {
    final alcLevel = ScoreCalculator.calculateALCLevel(totalScore);
    Color badgeColor;
    
    // Color coding for different levels
    if (alcLevel.startsWith('Adv')) {
      badgeColor = Colors.purple;
    } else if (alcLevel.startsWith('Int')) {
      badgeColor = Colors.blue;
    } else {
      badgeColor = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school,
            size: 16,
            color: badgeColor,
          ),
          SizedBox(width: 6),
          Text(
            'ALC Level: $alcLevel',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Test Results',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2193b0),
              ),
            ),
            SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _recentTests.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final result = _recentTests[index];
                final totalScore = int.parse(result['totalScore']?['integerValue'] ?? '0');
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2193b0).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Student info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${result['firstName']['stringValue']} ${result['lastName']['stringValue']}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _dateFormatter.format(DateTime.parse(
                                  result['timestamp']['timestampValue'])),
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Score and level
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getScoreColor(totalScore).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalScore/70',
                              style: GoogleFonts.poppins(
                                color: _getScoreColor(totalScore),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          _buildLevelBadge(totalScore),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCell(int score, int maxScore) {
    double percentage = (score / maxScore) * 100;
    Color color = _getScoreColor(percentage.round());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$score/$maxScore',
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading dashboard data...',
              style: GoogleFonts.poppins(
                color: Color(0xFF2193b0),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 64,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 32),
              if (_selectedPage == 'Overview') ...[
                _buildStatsRow(),
                SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildRecentTestsCard(),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTestDistributionCard(),
                          SizedBox(height: 32),
                          _buildTopPerformersCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedPage == 'Students') _buildRecentTestsCard(),
              if (_selectedPage == 'Test Results')
                Column(
                  children: [
                    _buildTestDistributionCard(),
                    SizedBox(height: 32),
                    _buildAllTestResultsCard(),
                  ],
                ),
              if (_selectedPage == 'Analytics')
                Column(
                  children: [
                    _buildStatsRow(),
                    SizedBox(height: 32),
                    _buildTestDistributionCard(),
                    SizedBox(height: 32),
                    _buildTopPerformersCard(),
                  ],
                ),
              if (_selectedPage == 'Search') _buildSearchCard(),
              if (_selectedPage == 'Code Search') _buildCodeSearchCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPage,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _getPageDescription(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              'Refresh Data',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Color(0xFF2193b0),
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPageDescription() {
    switch (_selectedPage) {
      case 'Overview':
        return 'Monitor test performance and student progress';
      case 'Students':
        return 'View all student test results';
      case 'Test Results':
        return 'Analyze test distributions and recent results';
      case 'Analytics':
        return 'View detailed performance metrics';
      default:
        return '';
    }
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Search',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2193b0),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF2193b0)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Color(0xFF2193b0), width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _searchStudent(value);
              },
            ),
            SizedBox(height: 24),
            if (_isSearching)
              Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                ),
              )
            else if (_searchQuery.isNotEmpty && _searchResults.isEmpty)
              Center(
                child: Text(
                  'No results found',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              )
            else if (_searchResults.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 48,
                  dataRowHeight: 56,
                  columnSpacing: 32,
                  headingTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2193b0),
                  ),
                  columns: [
                    DataColumn(label: Text('Student Name')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Birth Date')),
                    DataColumn(label: Text('Listening')),
                    DataColumn(label: Text('Reading')),
                    DataColumn(label: Text('Grammar')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _searchResults.map((result) {
                    final firstName =
                        result['firstName']?['stringValue'] ?? '';
                    final lastName =
                        result['lastName']?['stringValue'] ?? '';
                    final email = result['email']?['stringValue'] ?? '';
                    final phone = result['phone']?['stringValue'] ?? '';
                    final birthDate =
                        result['birthDate']?['stringValue'] ?? '';
                    final isExistingStudent =
                        result['isExistingStudent']?['booleanValue'] ?? false;

                    final listeningScore = int.tryParse(
                            result['listeningScore']?['integerValue']
                                    ?.toString() ??
                                '0') ??
                        0;
                    final readingScore = int.tryParse(
                            result['readingScore']?['integerValue']
                                    ?.toString() ??
                                '0') ??
                        0;
                    final grammarScore = int.tryParse(
                            result['grammarScore']?['integerValue']
                                    ?.toString() ??
                                '0') ??
                        0;

                    final totalScore =
                        listeningScore + readingScore + grammarScore;

                    DateTime? timestamp;
                    try {
                      timestamp = DateTime.parse(result['timestamp']
                              ?['timestampValue']
                              ?.toString() ??
                          '');
                    } catch (e) {
                      timestamp = null;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(
                          '$firstName $lastName',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        )),
                        DataCell(Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isExistingStudent
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isExistingStudent ? 'ALC Student' : 'New Student',
                            style: GoogleFonts.poppins(
                              color: isExistingStudent
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        )),
                        DataCell(Text(email)),
                        DataCell(Text(phone)),
                        DataCell(Text(birthDate)),
                        DataCell(_buildScoreCell(listeningScore, 20)),
                        DataCell(_buildScoreCell(readingScore, 20)),
                        DataCell(_buildScoreCell(grammarScore, 30)),
                        DataCell(_buildScoreCell(totalScore, 70)),
                        DataCell(Text(timestamp != null
                            ? _dateFormatter.format(timestamp)
                            : 'N/A')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: IconButton(
                                  icon: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                                        ),
                                      )
                                    : Icon(Icons.download_rounded, 
                                        color: Color(0xFF2193b0)),
                                  onPressed: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                    ? null
                                    : () => _generatePDFReport(result),
                                  tooltip: 'Download PDF Report',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSearchCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  MaterialCommunityIcons.key_variant,
                  color: Color(0xFF2193b0),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Search by School Code',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Enter the school code to find student results',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: TextField(
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'Enter school code...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF2193b0)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Color(0xFF2193b0), width: 2),
                  ),
                  suffixIcon: _isCodeSearching
                      ? Container(
                          width: 20,
                          height: 20,
                          margin: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2193b0)),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _codeSearchQuery = value);
                  if (value.isNotEmpty) {
                    _searchByCode(value);
                  } else {
                    setState(() => _codeSearchResults = []);
                  }
                },
              ),
            ),
            SizedBox(height: 24),
            if (_isCodeSearching)
              Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                ),
              )
            else if (_codeSearchQuery.isNotEmpty &&
                _codeSearchResults.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No results found for code: $_codeSearchQuery',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else if (_codeSearchResults.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Results found: ${_codeSearchResults.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2193b0),
                        ),
                      ),
                      if (_codeSearchResults.length > 1)
                        Text(
                          'School Code: $_codeSearchQuery',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 48,
                          dataRowHeight: 56,
                          columnSpacing: 32,
                          headingTextStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2193b0),
                          ),
                          columns: [
                            DataColumn(label: Text('Student Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Test Date')),
                            DataColumn(label: Text('Listening (/20)')),
                            DataColumn(label: Text('Reading (/20)')),
                            DataColumn(label: Text('Grammar (/30)')),
                            DataColumn(label: Text('Total (/70)')),
                            DataColumn(label: Text('EVOLVE Level')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _codeSearchResults.map((result) {
                            final firstName =
                                result['firstName']?['stringValue'] ?? '';
                            final lastName =
                                result['lastName']?['stringValue'] ?? '';
                            final email =
                                result['email']?['stringValue'] ?? '';

                            final listeningScore = int.tryParse(
                                    result['listeningScore']?['integerValue']
                                            ?.toString() ??
                                        '0') ??
                                0;
                            final readingScore = int.tryParse(
                                    result['readingScore']?['integerValue']
                                            ?.toString() ??
                                        '0') ??
                                0;
                            final grammarScore = int.tryParse(
                                    result['grammarScore']?['integerValue']
                                            ?.toString() ??
                                        '0') ??
                                0;

                            final totalScore =
                                listeningScore + readingScore + grammarScore;
                            final evolveLevel =
                                result['evolveLevel']?['stringValue'] ??
                                    'N/A';

                            DateTime? timestamp;
                            try {
                              timestamp = DateTime.parse(result['timestamp']
                                      ?['timestampValue']
                                      ?.toString() ??
                                  '');
                            } catch (e) {
                              timestamp = null;
                            }

                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  '$firstName $lastName',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500),
                                )),
                                DataCell(Text(
                                  email,
                                  style: GoogleFonts.poppins(),
                                )),
                                DataCell(Text(timestamp != null
                                    ? _dateFormatter.format(timestamp)
                                    : 'N/A')),
                                DataCell(
                                    _buildScoreCell(listeningScore, 20)),
                                DataCell(_buildScoreCell(readingScore, 20)),
                                DataCell(_buildScoreCell(grammarScore, 30)),
                                DataCell(_buildScoreCell(totalScore, 70)),
                                DataCell(Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2193b0)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    evolveLevel,
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFF2193b0),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                )),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: IconButton(
                                          icon: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                                                ),
                                              )
                                            : Icon(Icons.download_rounded, 
                                                color: Color(0xFF2193b0)),
                                          onPressed: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                            ? null
                                            : () => _generatePDFReport(result),
                                          tooltip: 'Download PDF Report',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
  }

  Widget _buildAllTestResultsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Test Results',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: TextButton.icon(
                    onPressed: _loadDashboardData,
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF2193b0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _firestoreService.fetchAllTestResults(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading test results',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                final allTests = snapshot.data ?? [];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowHeight: 56,
                    columnSpacing: 32,
                    headingTextStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2193b0),
                    ),
                    columns: [
                      DataColumn(label: Text('Student Name')),
                      DataColumn(label: Text('Listening (/20)')),
                      DataColumn(label: Text('Reading (/20)')),
                      DataColumn(label: Text('Grammar (/30)')),
                      DataColumn(label: Text('Total (/70)')),
                      DataColumn(label: Text('EVOLVE Level')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: allTests.map((result) {
                      final listeningScore = int.parse(
                          result['listeningScore']?['integerValue'] ?? '0');
                      final readingScore =
                          int.parse(result['readingScore']?['integerValue'] ?? '0');
                      final grammarScore =
                          int.parse(result['grammarScore']?['integerValue'] ?? '0');
                      final totalScore =
                          listeningScore + readingScore + grammarScore;
                      final timestamp =
                          DateTime.parse(result['timestamp']['timestampValue']);

                      return DataRow(
                        cells: [
                          DataCell(Text(
                            '${result['firstName']['stringValue']} ${result['lastName']['stringValue']}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          )),
                          DataCell(_buildScoreCell(listeningScore, 20)),
                          DataCell(_buildScoreCell(readingScore, 20)),
                          DataCell(_buildScoreCell(grammarScore, 30)),
                          DataCell(_buildScoreCell(totalScore, 70)),
                          DataCell(Text(
                            result['evolveLevel']?['stringValue'] ?? 'N/A',
                            style: GoogleFonts.poppins(),
                          )),
                          DataCell(Text(
                            _dateFormatter.format(timestamp),
                            style: GoogleFonts.poppins(),
                          )),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: IconButton(
                                    icon: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2193b0)),
                                          ),
                                        )
                                      : Icon(Icons.download_rounded, 
                                          color: Color(0xFF2193b0)),
                                    onPressed: _generatingPDFs[result['timestamp']?['timestampValue']] == true
                                      ? null
                                      : () => _generatePDFReport(result),
                                    tooltip: 'Download PDF Report',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: const Color(0xFF2193b0),
          size: 28,
        ),
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => SelectionPage()),
          );
        },
        tooltip: 'Back to Selection',
      ),
      title: Text(
        'ALC El Jadida',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2193b0),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: const Color(0xFF2193b0),
              size: 28,
            ),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          child: Container(
            width: 400,
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
                  'Confirm Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to logout?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => RegistrationPage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALC Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2193b0),
                  ),
                ),
                SizedBox(height: 48),

                // Navigation Buttons
                _buildSidebarButton(
                  'Overview',
                  MaterialCommunityIcons.view_dashboard_outline,
                  isSelected: _selectedPage == 'Overview',
                ),
                _buildSidebarButton(
                  'Students',
                  MaterialCommunityIcons.account_group_outline,
                  isSelected: _selectedPage == 'Students',
                ),
                _buildSidebarButton(
                  'Test Results',
                  MaterialCommunityIcons.file_document_outline,
                  isSelected: _selectedPage == 'Test Results',
                ),
                _buildSidebarButton(
                  'Analytics',
                  MaterialCommunityIcons.chart_box_outline,
                  isSelected: _selectedPage == 'Analytics',
                ),
                _buildSidebarButton(
                  'Search',
                  MaterialCommunityIcons.account_search,
                  isSelected: _selectedPage == 'Search',
                ),
                _buildSidebarButton(
                  'Code Search',
                  MaterialCommunityIcons.key_variant,
                  isSelected: _selectedPage == 'Code Search',
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }
}
