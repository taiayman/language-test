class TestResult {
  final String userId;
  final String firstName;
  final String lastName;
  final String testType;
  final int score;
  final int totalQuestions;
  final DateTime timestamp;

  TestResult({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.testType,
    required this.score,
    required this.totalQuestions,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'testType': testType,
      'score': score,
      'totalQuestions': totalQuestions,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}