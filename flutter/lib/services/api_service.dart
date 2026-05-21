import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../models/analysis_result.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _base = AppConfig.apiBaseUrl;

  Future<VpiResult> submitVpi(List<String> answers) async {
    final response = await http
        .post(
          Uri.parse('$_base/api/vpi'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'answers': answers}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return VpiResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('VPI submission failed: ${response.statusCode}');
  }

  Future<AnalysisResult> analyzeVoice({
    required File audioFile,
    required String gunaBaseline,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/analyze-voice'),
    );
    request.fields['guna_baseline'] = gunaBaseline;
    request.files.add(
      await http.MultipartFile.fromPath('audio_file', audioFile.path),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Voice analysis failed: ${response.statusCode}\n${response.body}');
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/healthz'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getModelStatus() async {
    final response = await http
        .get(Uri.parse('$_base/api/model/status'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch model status: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> retrainModel({int maxActors = 6}) async {
    final response = await http
        .post(
          Uri.parse('$_base/api/model/train-ravdess'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'max_actors': maxActors}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to initiate model training: ${response.statusCode}\n${response.body}');
  }
}
