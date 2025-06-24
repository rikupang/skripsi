import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<Map<String, dynamic>>> getWisataData() async {
  final apiKey = dotenv.env['API_KEY'] ?? ''; // API Key untuk otentikasi
  final uri = Uri.parse('http://10.0.2.2:3000/api/wisata/wisata'); // URL API sesuai dengan server lokal

  try {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey, // Menyertakan API Key jika diperlukan
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      print('Gagal mengambil data: ${response.statusCode}, ${response.body}');
      return [];
    }
  } catch (e) {
    print('Terjadi kesalahan saat mengambil data: $e');
    return [];
  }
}
