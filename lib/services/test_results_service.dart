import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/test_result.dart';

class TestResultsService {
  final String projectId;
  
  TestResultsService(this.projectId);

  Future<void> saveTestResult(TestResult result) async {
    try {
      final url = 'https://$projectId-default-rtdb.firebaseio.com/test_results.json';
      
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save test result');
      }
    } catch (e) {
      print('Error saving test result: $e');
      rethrow;
    }
  }
}