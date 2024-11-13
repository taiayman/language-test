import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class TestStatus {
  final bool isListeningActive;
  final bool isReadingActive;
  final bool isGrammarActive;

  TestStatus({
    required this.isListeningActive,
    required this.isReadingActive,
    required this.isGrammarActive,
  });
}

class TestSessionService {
  static const String _listeningStartTimeKey = 'listening_start_time';
  static const String _listeningActiveKey = 'listening_test_active';
  static const String _listeningEndTimeKey = 'listening_end_time';
  static const String _readingActiveKey = 'reading_test_active';
  static const String _readingEndTimeKey = 'reading_end_time';
  static const String _grammarActiveKey = 'grammar_test_active';
  static const String _grammarEndTimeKey = 'grammar_end_time';
  static const String _listeningCompletedKey = 'listening_test_completed';
  static const String _readingCompletedKey = 'reading_test_completed';
  static const String _grammarCompletedKey = 'grammar_test_completed';
  
  static const int testDurationMinutes = 15;  // Listening test duration
  static const int readingTestDurationMinutes = 20;  // Reading test duration
  static const int grammarTestDurationMinutes = 15;  // Grammar test duration

  // Add StreamController for test status
  static final _testStatusController = StreamController<TestStatus>.broadcast();
  Stream<TestStatus> get testStatusStream => _testStatusController.stream;

  // Start a new test session by storing the end time
  Future<void> startListeningTest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: testDurationMinutes));
    
    await prefs.setBool(_listeningActiveKey, true);
    await prefs.setString(_listeningEndTimeKey, endTime.toIso8601String());
    await _updateTestStatus();
  }

  // Get remaining time based on stored end time
  Future<Duration?> getListeningRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_listeningActiveKey) ?? false;
    if (!isActive) return null;

    final endTimeStr = prefs.getString(_listeningEndTimeKey);
    if (endTimeStr == null) return null;

    final endTime = DateTime.parse(endTimeStr);
    final now = DateTime.now();
    final remaining = endTime.difference(now);

    // If time has expired
    if (remaining.isNegative) {
      await endListeningTest();
      return Duration.zero;
    }

    return remaining;
  }

  // End the test session
  Future<void> endListeningTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listeningStartTimeKey);
    await prefs.remove(_listeningEndTimeKey);
    await prefs.setBool(_listeningActiveKey, false);
    await _updateTestStatus();
  }

  // Check if test is active and not expired
  Future<bool> isListeningTestActive() async {
    final remainingTime = await getListeningRemainingTime();
    return remainingTime != null && !remainingTime.isNegative;
  }

  Future<bool> isReadingTestActive() async {
    final remainingTime = await getReadingRemainingTime();
    return remainingTime != null && !remainingTime.isNegative;
  }

  Future<Duration?> getReadingRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_readingActiveKey) ?? false;
    if (!isActive) return null;

    final endTimeStr = prefs.getString(_readingEndTimeKey);
    if (endTimeStr == null) return null;

    final endTime = DateTime.parse(endTimeStr);
    final now = DateTime.now();
    final remaining = endTime.difference(now);

    if (remaining.isNegative) {
      await endReadingTest();
      return Duration.zero;
    }

    return remaining;
  }

  Future<void> startReadingTest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: readingTestDurationMinutes));
    
    await prefs.setBool(_readingActiveKey, true);
    await prefs.setString(_readingEndTimeKey, endTime.toIso8601String());
    await _updateTestStatus();
  }

  Future<void> endReadingTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readingEndTimeKey);
    await prefs.setBool(_readingActiveKey, false);
    await _updateTestStatus();
  }

  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear listening test session
    await prefs.remove(_listeningStartTimeKey);
    await prefs.remove(_listeningActiveKey);
    await prefs.remove(_listeningEndTimeKey);
    await prefs.remove(_listeningCompletedKey);
    
    // Clear reading test session
    await prefs.remove(_readingActiveKey);
    await prefs.remove(_readingEndTimeKey);
    await prefs.remove(_readingCompletedKey);
    
    // Clear grammar test session
    await prefs.remove(_grammarActiveKey);
    await prefs.remove(_grammarEndTimeKey);
    await prefs.remove(_grammarCompletedKey);
    
    // Clear any other test-related data
    await prefs.remove('current_test_type');
    await prefs.remove('current_question_index');
    await prefs.remove('test_answers');
    await prefs.remove('test_score');
    
    // Update test status
    await _updateTestStatus();
  }

  // Add method to check if any test is active
  Future<bool> isAnyTestActive() async {
    final isListening = await isListeningTestActive();
    final isReading = await isReadingTestActive();
    return isListening || isReading;
  }

  // Add dispose method
  void dispose() {
    _testStatusController.close();
  }

  Future<void> startGrammarTest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: grammarTestDurationMinutes));
    
    await prefs.setBool(_grammarActiveKey, true);
    await prefs.setString(_grammarEndTimeKey, endTime.toIso8601String());
    await _updateTestStatus();
  }

  Future<Duration?> getGrammarRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_grammarActiveKey) ?? false;
    if (!isActive) return null;

    final endTimeStr = prefs.getString(_grammarEndTimeKey);
    if (endTimeStr == null) return null;

    final endTime = DateTime.parse(endTimeStr);
    final now = DateTime.now();
    final remaining = endTime.difference(now);

    if (remaining.isNegative) {
      await endGrammarTest();
      return Duration.zero;
    }

    return remaining;
  }

  Future<bool> isGrammarTestActive() async {
    final remainingTime = await getGrammarRemainingTime();
    return remainingTime != null && !remainingTime.isNegative;
  }

  Future<void> endGrammarTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_grammarEndTimeKey);
    await prefs.setBool(_grammarActiveKey, false);
    await _updateTestStatus();
  }

  Future<void> _updateTestStatus() async {
    final isListening = await isListeningTestActive();
    final isReading = await isReadingTestActive();
    final isGrammar = await isGrammarTestActive();
    _testStatusController.add(TestStatus(
      isListeningActive: isListening,
      isReadingActive: isReading,
      isGrammarActive: isGrammar,
    ));
  }

  Future<void> markTestAsCompleted(String testType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${testType}_test_completed', true);
  }

  Future<bool> isTestCompleted(String testType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${testType}_test_completed') ?? false;
  }

  // Add methods to get test scores
  Future<int?> getListeningTestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('listening_test_score');
  }

  Future<int?> getReadingTestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reading_test_score');
  }

  Future<int?> getGrammarTestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('grammar_test_score');
  }
}
