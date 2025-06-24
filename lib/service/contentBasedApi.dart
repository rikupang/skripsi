import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, dynamic>?> getRecommendationCBF(String email) async {
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final uri = Uri.parse('http://10.0.2.2:3000/api/wisata/recommendCBFAndroid');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      // Menambahkan print untuk response body dengan format yang lebih rapi
      var decodedResponse = json.decode(response.body) as Map<String, dynamic>;
      print("Response Body: ${const JsonEncoder.withIndent('  ').convert(decodedResponse)}"); // Format output JSON
      return decodedResponse;
    } else {
      print('Gagal mendapatkan rekomendasi: ${response.statusCode}, ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error saat mengambil rekomendasi: $e');
    return null;
  }
}

