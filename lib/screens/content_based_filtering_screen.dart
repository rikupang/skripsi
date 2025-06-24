import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../service/addRating.dart';
import 'components/card.dart';
import 'detail_screen.dart'; // Pastikan file ini ada dan sesuai
import 'dart:async';
import 'dart:ui';

class ContentBasedFilteringScreen extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;

  const ContentBasedFilteringScreen({super.key, required this.recommendations});

  @override
  State<ContentBasedFilteringScreen> createState() =>
      _ContentBasedFilteringScreenState();
}

class _ContentBasedFilteringScreenState
    extends State<ContentBasedFilteringScreen> {
  final Set<String> likedPlaces = {};
  bool _showBackButton = false;
  Timer? _timer;


  void _onUserInteraction() {
    if (!_showBackButton) {
      setState(() {
        _showBackButton = true;
      });
    }

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showBackButton = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: GestureDetector(
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Content Based",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A2A36),
                              ),
                            ),
                            Text(
                              "Filtering",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A2A36),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Recommendation based on content",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.people_alt,
                          size: 45,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Kategori
                    const Text(
                      "Kategori",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: ["Pantai", "Gunung", "Air Terjun", "Bukit"]
                          .map((e) => FilterChip(
                        label: Text(e),
                        onSelected: (_) {},
                        selected: false,
                        backgroundColor: Colors.teal.shade700,
                        labelStyle: const TextStyle(color: Colors.white),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Grid of favorites
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 2/3,
                        children: widget.recommendations.map((place) {
                          final name = place['title'] ?? 'Nama tidak tersedia';
                          final category = place['categories'] ?? 'Kategori tidak tersedia';
                          final rating = double.tryParse(place['totalScore'].toString()) ?? 0.0;
                          final price = place['price'].toString(); // ← ini penting
                          final image = (place['imageUrl'] == null || place['imageUrl'] == '' || place['imageUrl'] == '-')
                              ? 'https://storage.googleapis.com/digitalart-35c0a.appspot.com/profile_pictures/53suvj9Q1kaWwMzn2J837CoCWG93_0d34a516-c7c0-4344-a6f9-1b306812f9dc'
                              : place['imageUrl'];


                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    name: name,
                                    location: place['id'] ?? 'Unknown',
                                    address: place['address'] ?? 'Unknown',
                                    category: place['categories'] ?? 'Uncategorized',
                                    price: place['price']?.toString() ?? 'Unknown',
                                    facility: place['activity'] ?? 'Unknown',
                                    day: place['Open Everyday'] == null
                                        ? 'Unknown'
                                        : (place['Open Everyday'] == 1 ? 'Buka Setiap Hari' : 'Tidak Buka Setiap Hari'),
                                    time: place['Open 24 Hours'] == null
                                        ? 'Unknown'
                                        : (place['Open 24 Hours'] == 1 ? 'Buka 24 Jam' : 'Tidak 24 Jam'),
                                    description: place['description'] ?? 'Unknown',
                                    rating: (place['totalScore'] ?? 0).toDouble(),
                                    imagePath: place['imageUrl'] ?? 'assets/palaung.png',
                                  ),
                                ),

                              );
                            },
                            child: heightCard(
                              title: name,
                              subtitle: category,
                              rating: rating,
                              price: price,
                              image: image,
                              isLiked: likedPlaces.contains(name),
                              onLikeToggle: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                final email = user?.email;
                                if (email == null) return false;

                                final placeId = place['id'];
                                final isCurrentlyLiked = likedPlaces.contains(name);
                                final newLikeStatus = !isCurrentlyLiked;

                                final success = await postComment(
                                  placeId: placeId,
                                  email: email,
                                  like: newLikeStatus,
                                );

                                if (success) {
                                  setState(() {
                                    if (newLikeStatus) {
                                      likedPlaces.add(name);
                                    } else {
                                      widget.recommendations.removeWhere((p) => p['title'] == name);
                                      likedPlaces.remove(name);
                                    }
                                  });
                                  return true;
                                }

                                return false;
                              },


                            ),
                          );

                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol kembali kiri bawah
            Positioned(
              bottom: 24,
              left: 24,
              child: AnimatedOpacity(
                opacity: _showBackButton ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double rating;
  final String price;
  final String image;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const FavoriteCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.price,
    required this.image,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              image,  // Pastikan ini adalah URL gambar yang valid
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Menangani error jika gambar gagal dimuat
                return const Icon(Icons.broken_image);  // Menampilkan icon jika gambar tidak ditemukan
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;  // Menampilkan gambar saat selesai dimuat
                return const Center(child: CircularProgressIndicator());  // Menampilkan indikator loading
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toString(),
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Ticket Price",
                    style: TextStyle(color: Colors.grey[600])),
                Text(price,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: onLikeToggle,
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
        ],
      ),
    );
  }
}
