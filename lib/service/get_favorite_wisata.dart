import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<Map<String, dynamic>>> fetchFavoritePlaces(String email) async {
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final uri = Uri.parse('http://10.0.2.2:3000/api/wisata/user/$email/liked-wisata');

  try {
    print('Mengambil data liked wisata untuk email: $email');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // ✅ Cek jika decoded langsung berupa List
      if (decoded is List) {
        final result = decoded
            .where((item) => item is Map<String, dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .toList();

        print('DATA FAVORITES untuk $email: $result');
        return result;
      } else {
        print('Response tidak dalam format List.');
        return [];
      }
    } else {
      print('Gagal ambil data liked wisata untuk $email: ${response.statusCode}, ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error saat ambil liked wisata untuk $email: $e');
    return [];
  }
}

