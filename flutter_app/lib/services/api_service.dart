import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // ── Upload PDF (web-compatible, uses bytes) ───────────────────────────────
  static Future<UploadResult> uploadPdfBytes(
    Uint8List bytes,
    String filename, {
    String collection = 'default',
  }) async {
    final uri = Uri.parse('$baseUrl/upload?collection_name=$collection');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType('application', 'pdf'),
    ));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);
    if (response.statusCode == 200) {
      return UploadResult(
        filename: data['filename'],
        chunksStored: data['chunks_stored'],
        success: true,
      );
    }
    throw Exception(data['detail'] ?? 'Upload failed');
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  static Future<ChatResult> chat(String question, {String collection = 'default'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'collection_name': collection}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return ChatResult.fromJson(data);
    throw Exception(data['detail'] ?? 'Chat failed');
  }

  // ── Quiz ──────────────────────────────────────────────────────────────────
  static Future<QuizResult> generateQuiz(
    String topic, {
    int numQuestions = 5,
    String type = 'mcq',
    String collection = 'default',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quiz'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': topic,
        'num_questions': numQuestions,
        'question_type': type,
        'collection_name': collection,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return QuizResult.fromJson(data);
    throw Exception(data['detail'] ?? 'Quiz generation failed');
  }

  // ── Flashcards ────────────────────────────────────────────────────────────
  static Future<FlashcardResult> generateFlashcards(
    String topic, {
    int numCards = 10,
    String collection = 'default',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/flashcards'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': topic,
        'num_cards': numCards,
        'collection_name': collection,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return FlashcardResult.fromJson(data);
    throw Exception(data['detail'] ?? 'Flashcard generation failed');
  }

  // ── Health ────────────────────────────────────────────────────────────────
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
