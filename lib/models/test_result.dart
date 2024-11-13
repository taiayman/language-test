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

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      testType: json['testType'] as String,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'testType': testType,
    'score': score,
    'totalQuestions': totalQuestions,
    'timestamp': timestamp.toIso8601String(),
  };
}
