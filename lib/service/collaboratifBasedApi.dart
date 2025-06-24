import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<Map<String, dynamic>>> getRecommendationWisata(String email) async {
  final apiKey = dotenv.env['API_KEY'];
  final url = Uri.parse('http://10.0.2.2:3000/api/wisata/recommendationsCollaborative/$email');

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey ?? '', // Sertakan API key di header
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      // Optional: print hasil yang sudah diformat rapi
      print("Response:");
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      print(encoder.convert(data));

      return data.cast<Map<String, dynamic>>();
    } else {
      print('Gagal mendapatkan rekomendasi. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Terjadi kesalahan: $e');
    return [];
  }
}
