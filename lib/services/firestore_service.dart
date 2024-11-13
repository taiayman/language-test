import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alc_eljadida_tests/services/score_calculator.dart';

class FirestoreService {
  final String projectId = "testapp-a0f67";
  final String apiKey = "AIzaSyAyNWHQXz89YL02R4RrSun80w1C2yLsTRY";
  
  String get _baseUrl => 
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<List<Map<String, dynamic>>> fetchTestResults(String firstName, String lastName) async {
    try {
      final queryUrl = Uri.parse('$_baseUrl:runQuery?key=$apiKey');
      final queryBody = {
        'structuredQuery': {
          'from': [{'collectionId': 'testResults'}],
          'where': {
            'compositeFilter': {
              'op': 'AND',
              'filters': [
                {
                  'fieldFilter': {
                    'field': {'fieldPath': 'firstName'},
                    'op': 'EQUAL',
                    'value': {'stringValue': firstName}
                  }
                },
                {
                  'fieldFilter': {
                    'field': {'fieldPath': 'lastName'},
                    'op': 'EQUAL',
                    'value': {'stringValue': lastName}
                  }
                }
              ]
            }
          },
          'orderBy': [
            {
              'field': {'fieldPath': 'timestamp'},
              'direction': 'DESCENDING'
            }
          ]
        }
      };

      final response = await http.post(
        queryUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(queryBody),
      );

      if (response.statusCode != 200) {
        print('Failed to fetch test results. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch test results');
      }

      final List<dynamic> queryResults = json.decode(response.body);
      final List<Map<String, dynamic>> results = [];

      for (var queryResult in queryResults) {
        if (queryResult.containsKey('document')) {
          final document = queryResult['document'];
          if (document.containsKey('fields')) {
            results.add(Map<String, dynamic>.from(document['fields']));
          }
        }
      }

      return results;
    } catch (e) {
      print('Error fetching test results: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllTestResults() async {
    try {
      final queryUrl = Uri.parse('$_baseUrl:runQuery?key=$apiKey');
      final queryBody = {
        'structuredQuery': {
          'from': [{'collectionId': 'testResults'}],
          'orderBy': [
            {
              'field': {'fieldPath': 'timestamp'},
              'direction': 'DESCENDING'
            }
          ]
        }
      };

      final response = await http.post(
        queryUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(queryBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch all test results');
      }

      final List<dynamic> queryResults = json.decode(response.body);
      final List<Map<String, dynamic>> results = [];

      for (var queryResult in queryResults) {
        if (queryResult.containsKey('document')) {
          final document = queryResult['document'];
          if (document.containsKey('fields')) {
            results.add(Map<String, dynamic>.from(document['fields']));
          }
        }
      }

      return results;
    } catch (e) {
      print('Error fetching all test results: $e');
      rethrow;
    }
  }

  Future<void> saveBulkResults({
    required String firstName,
    required String lastName,
    required String? birthDate,
    required String? address,
    required String phone,
    required bool isParentPhone,
    required String email,
    required String? cin,
    required bool isExistingStudent,
    required int listeningRawScore,
    required Duration listeningDuration,
    required int readingRawScore,
    required Duration readingDuration,
    required int grammarRawScore,
    required Duration grammarDuration,
    required DateTime timestamp,
    required int listeningTotalQuestions,
    required int readingTotalQuestions,
    required int grammarTotalQuestions,
    required String schoolCode,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/testResults?key=$apiKey');

      // Calculate standardized scores
      final listeningScore = ScoreCalculator.calculateListeningScore(
        listeningRawScore, 
        listeningTotalQuestions
      );
      final readingScore = ScoreCalculator.calculateReadingScore(
        readingRawScore, 
        readingTotalQuestions
      );
      final grammarScore = ScoreCalculator.calculateGrammarScore(
        grammarRawScore, 
        grammarTotalQuestions
      );

      final totalScore = listeningScore + readingScore + grammarScore;

      final testResult = {
        'fields': {
          'firstName': {'stringValue': firstName},
          'lastName': {'stringValue': lastName},
          'birthDate': {'stringValue': birthDate ?? ''},
          'address': {'stringValue': address ?? ''},
          'phone': {'stringValue': phone},
          'isParentPhone': {'booleanValue': isParentPhone},
          'email': {'stringValue': email},
          'cin': {'stringValue': cin ?? ''},
          'isExistingStudent': {'booleanValue': isExistingStudent},
          'listeningScore': {'integerValue': listeningScore},
          'listeningMaxScore': {'integerValue': ScoreCalculator.MAX_LISTENING_SCORE},
          'listeningDuration': {'integerValue': listeningDuration.inSeconds},
          'readingScore': {'integerValue': readingScore},
          'readingMaxScore': {'integerValue': ScoreCalculator.MAX_READING_SCORE},
          'readingDuration': {'integerValue': readingDuration.inSeconds},
          'grammarScore': {'integerValue': grammarScore},
          'grammarMaxScore': {'integerValue': ScoreCalculator.MAX_GRAMMAR_SCORE},
          'grammarDuration': {'integerValue': grammarDuration.inSeconds},
          'searchName': {'stringValue': '$firstName $lastName'.toLowerCase()},
          'testType': {'stringValue': 'complete'},
          'timestamp': {'timestampValue': timestamp.toUtc().toIso8601String()},
          'totalScore': {'integerValue': totalScore},
          'maxTotalScore': {'integerValue': ScoreCalculator.MAX_TOTAL_SCORE},
          'evolveLevel': {'stringValue': _calculateEvolveLevel(totalScore)},
          'schoolCode': {'stringValue': schoolCode},
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(testResult),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save test results');
      }
    } catch (e) {
      print('Error in saveBulkResults: $e');
      rethrow;
    }
  }

  String _calculateEvolveLevel(int totalScore) {
    return ScoreCalculator.calculateALCLevel(totalScore);
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
  try {
    final allResults = await fetchAllTestResults();
    
    Set<String> uniqueStudents = {};
    double totalPercentage = 0;
    int totalTests = 0;
    Map<String, int> testTypeCounts = {
      'Listening': 0,
      'Reading': 0,
      'Grammar': 0
    };

    for (var result in allResults) {
      String studentName = '${result['firstName']['stringValue']} ${result['lastName']['stringValue']}';
      uniqueStudents.add(studentName);

      if (result.containsKey('listeningScore')) {
        testTypeCounts['Listening'] = testTypeCounts['Listening']! + 1;
        int score = int.parse(result['listeningScore']['integerValue']);
        totalPercentage += (score / ScoreCalculator.MAX_LISTENING_SCORE) * 100;
        totalTests++;
      }
      if (result.containsKey('readingScore')) {
        testTypeCounts['Reading'] = testTypeCounts['Reading']! + 1;
        int score = int.parse(result['readingScore']['integerValue']);
        totalPercentage += (score / ScoreCalculator.MAX_READING_SCORE) * 100;
        totalTests++;
      }
      if (result.containsKey('grammarScore')) {
        testTypeCounts['Grammar'] = testTypeCounts['Grammar']! + 1;
        int score = int.parse(result['grammarScore']['integerValue']);
        totalPercentage += (score / ScoreCalculator.MAX_GRAMMAR_SCORE) * 100;
        totalTests++;
      }
    }

    double averagePercentage = totalTests > 0 ? totalPercentage / totalTests : 0;

    return {
      'totalStudents': uniqueStudents.length,
      'totalTests': totalTests,
      'averageScore': averagePercentage,
      'testTypeCounts': testTypeCounts,
      'recentTests': allResults.take(10).toList(),
    };
  } catch (e) {
    print('Error fetching dashboard stats: $e');
    rethrow;
  }
}

  Future<List<Map<String, dynamic>>> searchStudentResults(String query) async {
    try {
      final queryUrl = Uri.parse('$_baseUrl:runQuery?key=$apiKey');
      final queryBody = {
        'structuredQuery': {
          'from': [{'collectionId': 'testResults'}],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'searchName'},
              'op': 'GREATER_THAN_OR_EQUAL',
              'value': {'stringValue': query.toLowerCase()}
            }
          },
          'orderBy': [
            {
              'field': {'fieldPath': 'searchName'},
              'direction': 'ASCENDING'
            }
          ],
          'limit': 20
        }
      };

      final response = await http.post(
        queryUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(queryBody),
      );

      if (response.statusCode != 200) {
        print('Search failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to search student results');
      }

      final List<dynamic> queryResults = json.decode(response.body);
      final List<Map<String, dynamic>> results = [];

      for (var queryResult in queryResults) {
        if (queryResult.containsKey('document')) {
          final document = queryResult['document'];
          if (document.containsKey('fields')) {
            final fields = document['fields'];
            final searchName = fields['searchName']['stringValue'].toLowerCase();
            // Only include results that start with the search query
            if (searchName.startsWith(query.toLowerCase())) {
              results.add(Map<String, dynamic>.from(fields));
            }
          }
        }
      }

      return results;
    } catch (e) {
      print('Error searching student results: $e');
      if (e is http.ClientException) {
        print('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchBySchoolCode(String code) async {
    try {
      final queryUrl = Uri.parse('$_baseUrl:runQuery?key=$apiKey');
      final queryBody = {
        'structuredQuery': {
          'from': [{'collectionId': 'testResults'}],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'schoolCode'},
              'op': 'EQUAL',
              'value': {'stringValue': code}
            }
          }
        }
      };

      final response = await http.post(
        queryUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(queryBody),
      );

      if (response.statusCode != 200) {
        print('Search failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to search by school code');
      }

      final List<dynamic> queryResults = json.decode(response.body);
      final List<Map<String, dynamic>> results = [];

      for (var queryResult in queryResults) {
        if (queryResult.containsKey('document')) {
          final document = queryResult['document'];
          if (document.containsKey('fields')) {
            final fields = document['fields'];
            // Only add results that have all required fields
            if (_hasRequiredFields(fields)) {
              results.add(Map<String, dynamic>.from(fields));
            }
          }
        }
      }

      // Sort results by timestamp in descending order (newest first)
      results.sort((a, b) {
        try {
          final aTime = DateTime.parse(a['timestamp']['timestampValue']);
          final bTime = DateTime.parse(b['timestamp']['timestampValue']);
          return bTime.compareTo(aTime);
        } catch (e) {
          print('Error sorting results: $e');
          return 0;
        }
      });

      return results;
    } catch (e) {
      print('Error searching by school code: $e');
      if (e is http.ClientException) {
        print('Network error: ${e.message}');
      }
      rethrow;
    }
  }

  // Helper method to validate required fields
  bool _hasRequiredFields(Map<String, dynamic> fields) {
    final requiredFields = [
      'firstName',
      'lastName',
      'email',
      'phone',
      'timestamp',
      'listeningScore',
      'readingScore',
      'grammarScore'
    ];

    return requiredFields.every((field) => 
      fields.containsKey(field) && 
      fields[field] != null &&
      fields[field].containsKey('stringValue') || 
      fields[field].containsKey('integerValue') ||
      fields[field].containsKey('timestampValue')
    );
  }

  bool isValidSchoolCode(String code) {
    return code.length >= 4 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(code);
  }
}
