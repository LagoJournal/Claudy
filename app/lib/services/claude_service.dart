import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const _storage  = FlutterSecureStorage();
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model    = 'claude-haiku-4-5-20251001';
  static const _system   =
    'You are Claudy, a home assistant. Give concise, direct responses — '
    '1-3 sentences max. No markdown.';

  /// Streams response text chunks for the given conversation history.
  Stream<String> sendMessage(List<Map<String, String>> history) async* {
    final raw = await _storage.read(key: 'anthropic_api_key');
    final apiKey = raw?.trim().replaceAll(RegExp(r'[\r\n\t]'), '');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key configured');
    }

    final request = http.Request('POST', Uri.parse(_endpoint));
    request.headers.addAll({
      'x-api-key':           apiKey,
      'anthropic-version':   '2023-06-01',
      'content-type':        'application/json',
      'accept':              'text/event-stream',
    });
    request.body = jsonEncode({
      'model':      _model,
      'max_tokens': 1024,
      'stream':     true,
      'system':     _system,
      'messages':   history,
    });

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception(
          'API error ${streamedResponse.statusCode}: $body');
      }

      // Buffer incomplete SSE lines across chunks
      final lineBuffer = StringBuffer();

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        lineBuffer.write(chunk);
        final raw   = lineBuffer.toString();
        final lines = raw.split('\n');
        lineBuffer.clear();
        // The last element may be an incomplete line — keep it in the buffer
        lineBuffer.write(lines.removeLast());

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          try {
            final json  = jsonDecode(data) as Map<String, dynamic>;
            final type  = json['type'] as String?;
            if (type == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>?;
              final text  = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) yield text;
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
