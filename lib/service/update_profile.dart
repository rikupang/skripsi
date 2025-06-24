import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> updateUserProfile({
  required String uid,
  required String username,
  required String fullName,
  required String age,
  required String gender,
  required String phone,
  required String address,
  File? profilePicture,
}) async {
  final uri = Uri.parse('http://10.0.2.2:3000/api/auth/users/$uid/upload'); // Ganti jika pakai IP lain
  final apiKey = dotenv.env['API_KEY'] ?? '';

  var request = http.MultipartRequest('PUT', uri);

  // Tambahkan header API key
  request.headers['x-api-key'] = apiKey;

  // Tambahkan field profil
  request.fields['username'] = username;
  request.fields['fullName'] = fullName;
  request.fields['age'] = age;
  request.fields['gender'] = gender;
  request.fields['phone'] = phone;
  request.fields['address'] = address;

  // Tambahkan gambar jika ada
  if (profilePicture != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePicture',
        profilePicture.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );
  }

  try {
    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);
      print('Update sukses: ${data['message']}');
    } else {
      print('Gagal update: ${response.statusCode}, body: $respStr');
    }
  } catch (e) {
    print('Error saat update profil: $e');
  }
}
