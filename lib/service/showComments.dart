import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<Map<String, dynamic>>> fetchComments(String placeId) async {
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final uri = Uri.parse('http://10.0.2.2:3000/api/wisata/wisata/$placeId/komentar');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded['comments'] is List) {
        final List<Map<String, dynamic>> flattened = [];

        for (var userComment in decoded['comments']) {
          final email = userComment['email'] ?? 'unknown';
          final username = userComment['username'] ?? 'anonymous';
          final photoURL = userComment['photoURL'] ?? '';

          for (var c in userComment['comments']) {
            final dateSeconds = c['date']['_seconds'];
            final dateTime = DateTime.fromMillisecondsSinceEpoch(dateSeconds * 1000);

            flattened.add({
              'email': email,
              'username': username,
              'photoURL': photoURL,
              'comment': c['comment'],
              'date': dateTime.toIso8601String(),
            });
          }
        }

        // Urutkan komentar berdasarkan tanggal (terbaru di atas)
        flattened.sort((a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

        return flattened;
      }
    } else {
      print('Gagal fetch komentar: ${response.body}');
    }
  } catch (e) {
    print('Error fetch komentar: $e');
  }

  return [];
}
