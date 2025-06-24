import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>?> getRecommendationCBFInput(String query) async {
  final uri = Uri.parse('http://10.0.2.2:5001/recommendCBFwithInput');

  try {
    print("🌐 Sending request to API with query: '$query'");

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'query': query}),
    );

    print("📡 API Response status: ${response.statusCode}");
    print("📄 Raw response body: ${response.body}");

    if (response.statusCode == 200) {
      // Bersihkan response body dari nilai NaN sebelum parsing
      String cleanedBody = _cleanJsonResponse(response.body);
      print("🧹 Cleaned response body: $cleanedBody");

      try {
        final decoded = json.decode(cleanedBody);
        print("🔄 Decoded data type: ${decoded.runtimeType}");
        print("🔄 Decoded data: $decoded");

        // Jika respons langsung berupa List
        if (decoded is List) {
          print("✅ Response is direct List with ${decoded.length} items");
          return _processRecommendationList(decoded);
        }

        // Jika respons berupa Map yang punya key "recommendations" (sesuai log Anda)
        if (decoded is Map && decoded['recommendations'] is List) {
          print("✅ Found 'recommendations' key with ${decoded['recommendations'].length} items");
          return _processRecommendationList(decoded['recommendations'] as List);
        }

        // Jika respons berupa Map yang punya key "results"
        if (decoded is Map && decoded['results'] is List) {
          print("✅ Found 'results' key with ${decoded['results'].length} items");
          return _processRecommendationList(decoded['results'] as List);
        }

        // Jika respons berupa Map yang punya key "data"
        if (decoded is Map && decoded['data'] is List) {
          print("✅ Found 'data' key with ${decoded['data'].length} items");
          return _processRecommendationList(decoded['data'] as List);
        }

        // Debug: Print semua keys yang tersedia jika berbentuk Map
        if (decoded is Map) {
          print("🔍 Available keys in response: ${decoded.keys.toList()}");

          // Coba ambil key pertama yang berupa List
          for (String key in decoded.keys) {
            if (decoded[key] is List) {
              print("✅ Found List in key '$key' with ${decoded[key].length} items");
              return _processRecommendationList(decoded[key] as List);
            }
          }
        }

        print("❌ Struktur data tidak dikenali: $decoded");
        return null;
      } catch (jsonError) {
        print('💥 Error parsing JSON: $jsonError');
        print('📄 Response body: ${response.body}');
        return null;
      }
    } else {
      print('❌ Gagal mendapatkan rekomendasi: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('💥 Terjadi kesalahan saat mengambil rekomendasi: $e');
    return null;
  }
}

// Fungsi untuk membersihkan response JSON dari nilai NaN, undefined, dll
String _cleanJsonResponse(String jsonString) {
  // Replace NaN dengan null
  String cleaned = jsonString.replaceAll(': NaN', ': null');
  cleaned = cleaned.replaceAll(':NaN', ':null');
  cleaned = cleaned.replaceAll('NaN,', 'null,');
  cleaned = cleaned.replaceAll('NaN}', 'null}');
  cleaned = cleaned.replaceAll('NaN]', 'null]');

  // Replace undefined dengan null jika ada
  cleaned = cleaned.replaceAll(': undefined', ': null');
  cleaned = cleaned.replaceAll(':undefined', ':null');

  // Replace Infinity dengan null jika ada
  cleaned = cleaned.replaceAll(': Infinity', ': null');
  cleaned = cleaned.replaceAll(': -Infinity', ': null');
  cleaned = cleaned.replaceAll(':Infinity', ':null');
  cleaned = cleaned.replaceAll(':-Infinity', ':null');

  return cleaned;
}

// Fungsi untuk memproses dan membersihkan data rekomendasi
List<Map<String, dynamic>> _processRecommendationList(List rawList) {
  print("🔧 Processing ${rawList.length} raw items");

  final processed = rawList.map((item) {
    if (item is Map<String, dynamic>) {
      return _cleanRecommendationItem(item);
    } else if (item is Map) {
      // Convert Map to Map<String, dynamic>
      return _cleanRecommendationItem(Map<String, dynamic>.from(item));
    }
    print("⚠️ Skipping non-map item: $item");
    return <String, dynamic>{};
  }).where((item) => item.isNotEmpty).toList();

  print("✅ Successfully processed ${processed.length} items");
  return processed;
}

// Fungsi untuk membersihkan item rekomendasi individual
Map<String, dynamic> _cleanRecommendationItem(Map<String, dynamic> item) {
  Map<String, dynamic> cleanedItem = {};

  item.forEach((key, value) {
    // Handle null values
    if (value == null) {
      cleanedItem[key] = null;
    }
    // Handle string values
    else if (value is String) {
      // Handle string yang mungkin berisi "NaN", "null", etc.
      if (value.toLowerCase() == 'nan' ||
          value.toLowerCase() == 'null' ||
          value.toLowerCase() == 'undefined' ||
          value.trim().isEmpty) {
        cleanedItem[key] = '';  // Changed to empty string instead of null
      } else {
        cleanedItem[key] = value;
      }
    }
    // Handle numeric values
    else if (value is num) {
      // Check if number is finite
      if (value.isFinite) {
        cleanedItem[key] = value;
      } else {
        cleanedItem[key] = 0;  // Changed to 0 instead of null for numeric fields
      }
    }
    // Handle other types
    else {
      cleanedItem[key] = value;
    }
  });

  return cleanedItem;
}