import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../models/chat_chunk_model.dart';
import '../models/message_model.dart';
import '../models/session_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final String _base = AppConstants.baseUrl;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<List<SessionModel>> getSessions() async {
    final res = await http.get(Uri.parse('$_base/sessions'), headers: _jsonHeaders);
    _checkStatus(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SessionModel> createSession({String title = 'New Chat'}) async {
    final res = await http.post(
      Uri.parse('$_base/sessions'),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title}),
    );
    _checkStatus(res);
    return SessionModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getSessionMessages(String sessionId) async {
    final res = await http.get(Uri.parse('$_base/sessions/$sessionId'), headers: _jsonHeaders);
    _checkStatus(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final messages = json['messages'] as List? ?? [];
    return messages.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> renameSession(String sessionId, String title) async {
    final res = await http.put(
      Uri.parse('$_base/sessions/$sessionId'),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title}),
    );
    _checkStatus(res);
  }

  Future<void> deleteSession(String sessionId) async {
    final res = await http.delete(Uri.parse('$_base/sessions/$sessionId'), headers: _jsonHeaders);
    if (res.statusCode != 204 && res.statusCode >= 400) {
      throw ApiException(res.statusCode, res.body);
    }
  }

  // ── Chat (SSE streaming) ─────────────────────────────────────────────────

  Stream<ChatChunk> streamChat({
    required String sessionId,
    required String message,
    required List<Map<String, String>> history,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$_base/chat'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });
      request.body = jsonEncode({
        'session_id': sessionId,
        'message': message,
        'history': history,
      });

      final streamedRes = await client.send(request);

      if (streamedRes.statusCode >= 400) {
        final body = await streamedRes.stream.bytesToString();
        throw ApiException(streamedRes.statusCode, body);
      }

      String buffer = '';
      await for (final bytes in streamedRes.stream) {
        buffer += utf8.decode(bytes);
        final lines = buffer.split('\n');
        // Last element may be incomplete; keep it in buffer
        buffer = lines.last;

        for (final line in lines.take(lines.length - 1)) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data: ')) {
            final jsonStr = trimmed.substring(6).trim();
            if (jsonStr.isNotEmpty) {
              try {
                final chunk = ChatChunk.fromJson(
                  jsonDecode(jsonStr) as Map<String, dynamic>,
                );
                yield chunk;
              } catch (_) {
                // Malformed chunk — skip
              }
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // ── Health ────────────────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
