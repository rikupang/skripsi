import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit
import '../service/addRating.dart';
import '../service/get_favorite_wisata.dart';
import 'components/card.dart';
import 'detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> favoritePlaces = [];
  bool isLoading = true;
  final Set<String> likedPlaces = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final data = await fetchFavoritePlaces(user.email!);

        setState(() {
          favoritePlaces = data;
          likedPlaces.addAll(data.map((e) => e['title'].toString()));
          isLoading = false;
        });

        // Kirim status like:true untuk semua destinasi yang dimuat
        for (var place in data) {
          final placeId = place['_id'];
          await postComment(
            placeId: placeId,
            email: user.email!,
            like: true,
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching favorites: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isLoading = true;
    });
    await _loadFavorites();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
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
                      Text("Yours Favorite",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2A36))),
                      Text("Tourist Attractions",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A2A36))),
                      SizedBox(height: 4),
                      Text("This Is Bali, No Bali No Party",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  Icon(Icons.thumb_up_alt_outlined,
                      size: 36, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 20),

              const Text("Kategori",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ["Pantai", "Gunung", "Air Terjun", "Bukit"]
                    .map((e) => FilterChip(
                  label: Text(e),
                  onSelected: (_) {},
                  selected: false,
                  backgroundColor: Colors.teal.shade700,
                  labelStyle:
                  const TextStyle(color: Colors.white),
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: isLoading
                    ? Center(
                  child: SpinKitFoldingCube(
                    color: Colors.teal,
                    size: 50.0,
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: Colors.teal,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2/3,
                    children: favoritePlaces.map((place) {
                      final name = place['title'] ?? 'Nama tidak tersedia';
                      final category = place['categories'] ?? 'Kategori tidak tersedia';
                      final rating = double.tryParse(place['totalScore'].toString()) ?? 0.0;
                      final price = place['price'].toString();
                      final image = (place['imageUrl'] == null || place['imageUrl'] == '' || place['imageUrl'] == '-')
                          ? 'assets/defaultBG.png'
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
                                imagePath: place['imageUrl'] ?? 'assets/defaultBG.png',
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
                                  favoritePlaces.removeWhere((p) => p['title'] == name);
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}