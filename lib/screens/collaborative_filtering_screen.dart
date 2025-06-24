import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skripsi/screens/components/card.dart';
import '../service/addRating.dart';
import 'detail_screen.dart'; // Pastikan file ini ada dan sesuai
import 'dart:async';
import 'dart:ui';

class CollaborativeFilteringScreen extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;

  const CollaborativeFilteringScreen({super.key, required this.recommendations});


  @override
  State<CollaborativeFilteringScreen> createState() => _CollaborativeFilteringScreenState();
}

class _CollaborativeFilteringScreenState
    extends State<CollaborativeFilteringScreen> {
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
                              "Collaborative",
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
                              "Recommendation based on user similarity",
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

