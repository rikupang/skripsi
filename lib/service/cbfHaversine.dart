import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, dynamic>?> getRecommendationCBFHaversine(String title) async {
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final uri = Uri.parse('http://10.0.2.2:5000/recommendCBFHaversine');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      print("🔥 Rekomendasi Diterima:\n${const JsonEncoder.withIndent('  ').convert(decoded)}");
      return decoded;
    } else {
      print('⚠️ Gagal: ${response.statusCode} => ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Error saat request: $e');
    return null;
  }
}
