import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<bool> postComment({
  required String placeId,
  required String email,
  String? comment,
  double? rating,
  bool? like,
}) async {
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final uri = Uri.parse('http://10.0.2.2:3000/api/wisata/wisata/$placeId/comment');

  // Bangun request body secara dinamis
  final Map<String, dynamic> body = {
    'email': email,
    if (comment != null) 'comment': comment,
    if (rating != null) 'rating': rating,
    if (like != null) 'like': like,
  };

  try {
    print('Mengirim komentar untuk placeId: $placeId');
    print('Body request: $body');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: json.encode(body),
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Komentar/Rating/Like berhasil dikirim');
      return true;
    } else {
      print('Gagal kirim komentar: ${response.statusCode}, ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error saat kirim komentar: $e');
    return false;
  }
}
