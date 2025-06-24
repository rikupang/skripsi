import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<Map<String, dynamic>?> dataDetailWisata(String uid) async {

  final apiKey = dotenv.env['API_KEY'] ?? '';

  final uri = Uri.parse('http://10.0.2.2:3000/api/wisata/wisata/$uid');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      print('Gagal ambil data: ${response.statusCode}, ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error saat ambil profil: $e');
    return null;
  }
}
