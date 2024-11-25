import 'package:shared_preferences/shared_preferences.dart';

class ScoreCalculator {
  static const int MAX_GRAMMAR_SCORE = 30;
  static const int MAX_LISTENING_SCORE = 20;
  static const int MAX_READING_SCORE = 20;
  static const int MAX_TOTAL_SCORE = 70;

  static int calculateStandardizedScore(int correctAnswers, int totalQuestions, int maxScore) {
    if (totalQuestions == 0) return 0;
    
    // For listening test, use direct scoring (1 point per correct answer)
    if (maxScore == MAX_LISTENING_SCORE) {
      return correctAnswers.clamp(0, MAX_LISTENING_SCORE);
    }
    
    // For other tests, calculate proportional score
    double scorePerQuestion = maxScore / totalQuestions;
    double rawScore = correctAnswers * scorePerQuestion;
    return rawScore.round().clamp(0, maxScore);
  }

  static int calculateGrammarScore(int correctAnswers, int totalQuestions) {
    return calculateStandardizedScore(correctAnswers, totalQuestions, MAX_GRAMMAR_SCORE);
  }

  static int calculateListeningScore(int correctAnswers, int totalQuestions) {
    print('\n=== Score Calculator ===');
    print('Correct Answers: $correctAnswers');
    print('Total Questions: $totalQuestions');
    print('Max Listening Score: $MAX_LISTENING_SCORE');
    
    // Ensure score doesn't exceed maximum
    final clampedScore = correctAnswers.clamp(0, MAX_LISTENING_SCORE);
    print('Final Score: $clampedScore');
    
    return clampedScore;
  }

  static int calculateReadingScore(int correctAnswers, int totalQuestions) {
    return calculateStandardizedScore(correctAnswers, totalQuestions, MAX_READING_SCORE);
  }

  static int calculateTotalScore({
    required int listeningScore,
    required int readingScore,
    required int grammarScore,
  }) {
    // Ensure individual scores don't exceed their maximums
    final clampedListening = listeningScore.clamp(0, MAX_LISTENING_SCORE);
    final clampedReading = readingScore.clamp(0, MAX_READING_SCORE);
    final clampedGrammar = grammarScore.clamp(0, MAX_GRAMMAR_SCORE);
    
    return clampedListening + clampedReading + clampedGrammar;
  }

  static double calculatePercentage(int score, int maxScore) {
    if (maxScore == 0) return 0.0;
    return (score / maxScore) * 100;
  }

  static String getGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  static String getGradeFromScore(int score, int maxScore) {
    return getGrade(calculatePercentage(score, maxScore));
  }

  static Future<void> saveStandardizedScores({
    required int listeningRawScore,
    required int listeningTotalQuestions,
    required int readingRawScore,
    required int readingTotalQuestions,
    required int grammarRawScore,
    required int grammarTotalQuestions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final standardizedListeningScore = calculateListeningScore(
      listeningRawScore, 
      listeningTotalQuestions
    );
    final standardizedReadingScore = calculateReadingScore(
      readingRawScore, 
      readingTotalQuestions
    );
    final standardizedGrammarScore = calculateGrammarScore(
      grammarRawScore, 
      grammarTotalQuestions
    );

    final totalScore = calculateTotalScore(
      listeningScore: standardizedListeningScore,
      readingScore: standardizedReadingScore,
      grammarScore: standardizedGrammarScore,
    );

    await Future.wait([
      prefs.setInt('listening_test_score', standardizedListeningScore),
      prefs.setInt('reading_test_score', standardizedReadingScore),
      prefs.setInt('grammar_test_score', standardizedGrammarScore),
      prefs.setInt('total_test_score', totalScore),
      prefs.setInt('listening_max_score', MAX_LISTENING_SCORE),
      prefs.setInt('reading_max_score', MAX_READING_SCORE),
      prefs.setInt('grammar_max_score', MAX_GRAMMAR_SCORE),
      prefs.setInt('total_max_score', MAX_TOTAL_SCORE),
      prefs.setInt('listening_total_questions', listeningTotalQuestions),
      prefs.setInt('reading_total_questions', readingTotalQuestions),
      prefs.setInt('grammar_total_questions', grammarTotalQuestions),
    ]);
  }

  static Future<Map<String, int>> getStoredScores() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'listeningScore': prefs.getInt('listening_test_score') ?? 0,
      'readingScore': prefs.getInt('reading_test_score') ?? 0,
      'grammarScore': prefs.getInt('grammar_test_score') ?? 0,
      'totalScore': prefs.getInt('total_test_score') ?? 0,
      'listeningMaxScore': prefs.getInt('listening_max_score') ?? MAX_LISTENING_SCORE,
      'readingMaxScore': prefs.getInt('reading_max_score') ?? MAX_READING_SCORE,
      'grammarMaxScore': prefs.getInt('grammar_max_score') ?? MAX_GRAMMAR_SCORE,
      'totalMaxScore': prefs.getInt('total_max_score') ?? MAX_TOTAL_SCORE,
      'listeningTotalQuestions': prefs.getInt('listening_total_questions') ?? 0,
      'readingTotalQuestions': prefs.getInt('reading_total_questions') ?? 0,
      'grammarTotalQuestions': prefs.getInt('grammar_total_questions') ?? 0,
    };
  }

  static Future<void> clearStoredScores() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('listening_test_score'),
      prefs.remove('reading_test_score'),
      prefs.remove('grammar_test_score'),
      prefs.remove('total_test_score'),
      prefs.remove('listening_max_score'),
      prefs.remove('reading_max_score'),
      prefs.remove('grammar_max_score'),
      prefs.remove('total_max_score'),
      prefs.remove('listening_total_questions'),
      prefs.remove('reading_total_questions'),
      prefs.remove('grammar_total_questions'),
    ]);
  }

  static String calculateALCLevel(int totalScore) {
    if (totalScore >= 62) return 'Adv 4';
    if (totalScore >= 58) return 'Adv 3';
    if (totalScore >= 54) return 'Adv 2';
    if (totalScore >= 50) return 'Adv 1';
    if (totalScore >= 46) return 'Int 6';
    if (totalScore >= 42) return 'Int 5';
    if (totalScore >= 37) return 'Int 4';
    if (totalScore >= 33) return 'Int 3';
    if (totalScore >= 29) return 'Int 2';
    if (totalScore >= 24) return 'Int 1';
    if (totalScore >= 20) return 'Beg 6';
    if (totalScore >= 16) return 'Beg 5';
    if (totalScore >= 12) return 'Beg 4';
    if (totalScore >= 9) return 'Beg 3';
    if (totalScore >= 5) return 'Beg 2';
    if (totalScore >= 1) return 'Beg 1';
    return 'Beg 1';
  }
}