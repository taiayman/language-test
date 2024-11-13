import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/test_result.dart';

class TestResultsService {
  final String projectId;
  
  TestResultsService(this.projectId);

  Future<List<TestResult>> getTestResultsByName(String firstName, String lastName, String testType) async {
    try {
      final url = Uri.parse(
        'https://testapp-a0f67-default-rtdb.firebaseio.com/test_results.json'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch results: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data == null) {
        return [];
      }

      final results = <TestResult>[];
      
      if (data is Map) {
        data.forEach((userId, userResults) {
          if (userResults is Map) {
            userResults.forEach((resultId, value) {
              if (value is Map &&
                  value['testType'] == testType &&
                  value['firstName'] == firstName &&
                  value['lastName'] == lastName) {
                try {
                  results.add(TestResult(
                    userId: userId,
                    firstName: value['firstName'],
                    lastName: value['lastName'],
                    testType: value['testType'],
                    score: int.parse(value['score'].toString()),
                    totalQuestions: int.parse(value['totalQuestions'].toString()),
                    timestamp: DateTime.parse(value['timestamp']),
                  ));
                } catch (e) {
                  print('Error parsing result: $e');
                }
              }
            });
          }
        });
      }

      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return results;
    } catch (e) {
      print('Error fetching test results: $e');
      rethrow;
    }
  }

  Future<void> saveTestResult(TestResult result) async {
    try {
      final url = Uri.parse('https://$projectId-default-rtdb.firebaseio.com/test_results/${result.userId}.json');
      final response = await http.patch(url, body: json.encode(result.toJson()));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to save test result');
      }
    } catch (e) {
      print('Error saving test result: $e');
      rethrow;
    }
  }
}
