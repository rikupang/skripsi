import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../service/addRating.dart';
import '../service/cbfRecom.dart';
// Import API class Anda
import 'content_based_filtering_screen.dart';
import 'detail_screen.dart';


class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  DataScreenState createState() => DataScreenState();
}

class DataScreenState extends State<DataScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  Set<String> likedPlaces = {};
  TextEditingController searchController = TextEditingController();
  String selectedCategory = "Semua";
  bool _isLoading = true;
  bool _isLoadingRecommendation = false;
  String _error = '';

  List<String> categories = ["Semua", "landmark", "hutan", "air terjun", "danau", "taman", "petualangan", "pantai", "gunung",'bukit','religi'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final String jsonString = await rootBundle.loadString('assets/data.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _allData = jsonData.cast<Map<String, dynamic>>();
        _filteredData = _allData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getRecommendation(String title) async {
    setState(() {
      _isLoadingRecommendation = true;
    });

    try {
      final result = await getRecommendationByTitle(title);

      if (result != null) {
        // Navigasi ke ContentBasedFilteringScreen dengan hasil rekomendasi
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentBasedFilteringScreen(
                recommendations: List<Map<String, dynamic>>.from(result['recommendations'] ?? []),
              ),
            ),
          );
        }
      } else {
        // Tampilkan error jika gagal mendapat rekomendasi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan rekomendasi. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecommendation = false;
        });
      }
    }
  }

  void filterData() {
    setState(() {
      _filteredData = _allData.where((item) {
        final matchesSearch = searchController.text.isEmpty ||
            (item['title'] ?? '').toLowerCase().contains(searchController.text.toLowerCase()) ||
            (item['description'] ?? '').toLowerCase().contains(searchController.text.toLowerCase()) ||
            (item['city'] ?? '').toLowerCase().contains(searchController.text.toLowerCase()) ||
            (item['desa'] ?? '').toLowerCase().contains(searchController.text.toLowerCase()) ||
            (item['kecamatan'] ?? '').toLowerCase().contains(searchController.text.toLowerCase()) ||
            (item['activity'] ?? '').toLowerCase().contains(searchController.text.toLowerCase());

        final matchesCategory = selectedCategory == "Semua" ||
            (item['categories'] ?? '').toLowerCase().contains(selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "All Data Overview",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitPulse(
                  color: Colors.teal,
                  size: 50.0,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading data...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : _error.isNotEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
              : Column(
            children: [
              // Search dan Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: searchController,
                      onChanged: (value) => filterData(),
                      decoration: InputDecoration(
                        hintText: "Cari data...",
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCategory == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = category;
                                });
                                filterData();
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Colors.teal.shade100,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.teal.shade700 : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Results Count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Ditemukan ${_filteredData.length} data",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),

              // Data List
              Expanded(
                child: _filteredData.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tidak ada data ditemukan",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Coba ubah kata kunci pencarian",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredData.length,
                  itemBuilder: (context, index) {
                    final item = _filteredData[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: buildVerticalCard(
                        context,
                        item['title'] ?? 'Nama tidak tersedia',
                        item['categories'] ?? 'Kategori tidak tersedia',
                        (item['totalScore'] as num?)?.toDouble() ?? 0.0,
                        (item['price'] ?? 0).toString(),
                        item['imageUrl'] ?? 'assets/defaultBG.png',
                        item['placeId']?.toString() ?? '',
                        item['description'] ?? 'Deskripsi tidak tersedia',
                        item['activity'] ?? '',
                        item['desa'] ?? '',
                        item['kecamatan'] ?? '',
                        item['city'] ?? 'Kota tidak tersedia',
                        item['city'] ?? '',
                        item['address'] ?? '',
                        0.0, // similarityScore - not used in original data
                        item['day'] == 1.0 ? 'Buka Setiap Hari' : 'Tidak Buka Setiap Hari',
                        item['time'] == 1.0 ? 'Buka 24 Jam' : 'Tidak 24 Jam',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Loading overlay untuk rekomendasi
          if (_isLoadingRecommendation)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitPulse(
                      color: Colors.white,
                      size: 50.0,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Mengambil rekomendasi...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildVerticalCard(
      BuildContext context,
      String name,
      String category,
      double rating,
      String price,
      String imagePath,
      String placeId,
      String description,
      String activity,
      String desa,
      String kecamatan,
      String kota,
      String location,
      String address,
      double similarityScore,
      String day,
      String time, {
        bool isHot = false,
      }) {
    final isLiked = likedPlaces.contains(placeId);



    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              placeId: placeId,
              name: name,
              location: location,  // Kombinasi desa dan kecamatan
              address: address,    // Alamat lengkap: desa, kecamatan, kota
              category: category,
              price: price,
              facility: activity,
              day: day,
              time: time,
              description: description,
              rating: rating,
              imagePath: imagePath,
              desa: desa,           // Data desa terpisah
              kecamatan: kecamatan, // Data kecamatan terpisah
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: "image_$placeId",
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Image.network(
                  imagePath,
                  height: 130,
                  width: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        height: 130,
                        width: 130,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 130,
                      width: 130,
                      color: Colors.grey[200],
                      child: const Center(
                        child: SpinKitPulse(
                          color: Colors.teal,
                          size: 30.0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF007A8C),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      category,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    if (rating > 0) ...[
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (desa.isNotEmpty || kota.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              desa.isNotEmpty ? '$desa, $kota' : kota,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      "Ticket Price",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      price == "0" ? "Free Entry" : "Rp ${price}K",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF336749),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tombol Lihat Rekomendasi
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingRecommendation
                            ? null
                            : () => _getRecommendation(name),
                        icon: const Icon(Icons.recommend, size: 16),
                        label: const Text(
                          'Lihat Rekomendasi',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                  onTap: () async {
                    final currentLiked = likedPlaces.contains(placeId);

                    setState(() {
                      if (currentLiked) {
                        likedPlaces.remove(placeId);
                      } else {
                        likedPlaces.add(placeId);
                      }
                    });

                    final email = FirebaseAuth.instance.currentUser?.email ?? '';
                    if (email.isNotEmpty) {
                      final success = await postComment(
                        placeId: placeId,
                        email: email,
                        like: !currentLiked,
                      );
                      if (success) {
                        print("Like berhasil dikirim ke server.");
                      } else {
                        print("Gagal mengirim like ke server.");
                        print('Place ID: $placeId');
                      }
                    }
                  },
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}