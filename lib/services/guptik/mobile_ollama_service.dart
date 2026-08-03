import 'dart:convert';
import 'package:http/http.dart' as http;

class MobileOllamaService {
  final String tunnelUrl;

  MobileOllamaService({required this.tunnelUrl});

  /// 🚀 Fetch active AI settings synced from desktop
  Future<Map<String, dynamic>> fetchDesktopAiConfig() async {
    try {
      final response = await http.get(Uri.parse('$tunnelUrl/api/ai-config'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Could not sync config from desktop: $e");
    }
    return {};
  }

  /// 🚀 Push mobile AI settings back to desktop (Two-Way Sync)
  Future<bool> updateDesktopAiConfig({
    required String provider,
    required String model,
    required String apiKey,
    required String endpointUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$tunnelUrl/api/ai-config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'endpoint_url': endpointUrl,
          'model_name': model,
          'api_key': apiKey,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Could not update desktop config: $e");
      return false;
    }
  }

  /// 🚀 DYNAMICALLY fetch list of available models based on selected provider
  Future<List<String>> getInstalledModels(String provider, {String apiKey = ''}) async {
    List<String> defaultModels = [];
    
    switch (provider) {
      case 'OpenRouter':
        defaultModels = ['meta-llama/llama-3-8b-instruct', 'google/gemini-flash-1.5', 'anthropic/claude-3.5-sonnet', 'deepseek/deepseek-chat'];
        break;
      case 'OpenAI':
        defaultModels = ['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'];
        break;
      case 'Anthropic':
        defaultModels = ['claude-3-5-sonnet-20241022', 'claude-3-haiku-20240307'];
        break;
      case 'Gemini':
        defaultModels = ['gemini-1.5-flash', 'gemini-1.5-pro'];
        break;
      case 'DeepSeek':
        defaultModels = ['deepseek-chat', 'deepseek-coder'];
        break;
      default:
        defaultModels = ['meta-llama/llama-3-8b-instruct'];
    }

    if (provider == 'OpenRouter') {
      try {
        final response = await http.get(
          Uri.parse('https://openrouter.ai/api/v1/models'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['data'] != null && data['data'] is List) {
            List<String> liveModels = [];
            for (var model in data['data']) {
              if (model['id'] != null) {
                liveModels.add(model['id'].toString());
              }
            }
            if (liveModels.isNotEmpty) {
              return liveModels;
            }
          }
        }
      } catch (e) {
        print("Failed to fetch live OpenRouter models: $e");
      }
    }

    return defaultModels;
  }

  String _getDefaultEndpoint(String provider) {
    switch (provider) {
      case 'OpenAI':
        return 'https://api.openai.com/v1/chat/completions';
      case 'DeepSeek':
        return 'https://api.deepseek.com/chat/completions';
      case 'Anthropic':
        return 'https://api.anthropic.com/v1/messages';
      case 'Gemini':
        return 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';
      case 'OpenRouter':
      default:
        return 'https://openrouter.ai/api/v1/chat/completions';
    }
  }

  /// 🚀 Stream chat response supporting multi-provider configuration
  Stream<String> generateChatStream({
    required String provider,
    required String model,
    required List<Map<String, String>> history,
    String apiKey = '',
    String endpointUrl = '',
  }) async* {
    // 1. Sanitize API Key (strip 'bearer', spaces, newlines)
    String cleanKey = apiKey.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '').trim();
    if (cleanKey.toLowerCase().startsWith('bearer')) {
      cleanKey = cleanKey.substring(6).trim();
    }

    if (cleanKey.isEmpty && provider != 'Ollama') {
      yield "\n[Error]: $provider API Key is missing. Tap Settings (⚙️) to enter your API Key.";
      return;
    }

    // 2. Resolve URL & force HTTPS for cloud endpoints
    String url = endpointUrl.trim().isNotEmpty ? endpointUrl.trim() : _getDefaultEndpoint(provider);
    if (url.startsWith("http://") && (url.contains("openrouter") || url.contains("openai") || url.contains("anthropic") || url.contains("deepseek"))) {
      url = url.replaceFirst("http://", "https://");
    }

    final body = jsonEncode({
      "model": model,
      "messages": history,
      "stream": true,
    });

    try {
      final request = http.Request('POST', Uri.parse(url));
      request.body = body;

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (provider == 'OpenRouter') {
        headers['HTTP-Referer'] = 'https://guptik.com';
        headers['X-Title'] = 'Guptik Mobile';
      }

      if (cleanKey.isNotEmpty) {
        if (provider == 'Anthropic') {
          headers['x-api-key'] = cleanKey;
          headers['anthropic-version'] = '2023-06-01';
        } else {
          headers['Authorization'] = 'Bearer $cleanKey';
        }
      }

      request.headers.addAll(headers);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        yield "\n[API Error ${streamedResponse.statusCode}]: $errorBody";
        return;
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (var line in stream) {
        try {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith(':')) continue; // Skip comments & keep-alive lines

          String payload = trimmed;
          if (payload.startsWith('data: ')) {
            payload = payload.substring(6).trim();
          } else {
            continue; // Ignore non-SSE lines
          }

          if (payload == '[DONE]') break;

          final data = jsonDecode(payload);

          if (data['choices'] != null && data['choices'].isNotEmpty) {
            final delta = data['choices'][0]['delta'];
            if (delta != null && delta['content'] != null) {
              yield delta['content'];
            }
          } else if (data['message'] != null && data['message']['content'] != null) {
            yield data['message']['content'];
          }
        } catch (_) {
          // Ignore bad chunk parses
        }
      }
    } catch (e) {
      yield "\n[Error connecting to AI Provider: $e]";
    }
  }
}