import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> registerUser({
  required String email,
  required String password,
  required String username,
  required String fullName,
  required String age,
  required String gender,
  required String phone,
  required String address,
  File? profilePicture,
}) async {
  final uri = Uri.parse('http://10.0.2.2:3000/api/auth/register'); // Ganti dengan URL server kamu
  final apiKey = dotenv.env['API_KEY'] ?? '';


  var request = http.MultipartRequest('POST', uri);

  // Tambahkan header Authorization dengan API key
  request.headers['x-api-key'] = apiKey;

  // Tambahkan field-form
  request.fields['email'] = email;
  request.fields['password'] = password;
  request.fields['username'] = username;
  request.fields['fullName'] = fullName;
  request.fields['age'] = age;
  request.fields['gender'] = gender;
  request.fields['phone'] = phone;
  request.fields['address'] = address;

  // Tambahkan file jika tersedia
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

    if (response.statusCode == 201) {
      final data = jsonDecode(respStr);
      print('Register sukses: ${data['uid']}');
    } else {
      print('Gagal: ${response.statusCode}, body: $respStr');
    }
  } catch (e) {
    print('Error saat mengirim data: $e');
  }
}
