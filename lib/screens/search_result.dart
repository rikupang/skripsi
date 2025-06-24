import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../service/addRating.dart';
import 'components/card.dart';
import 'detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final String query;

  const SearchResultScreen({super.key, required this.results, required this.query});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> with TickerProviderStateMixin {
  final Set<String> likedPlaces = {};
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    likedPlaces.addAll(widget.results.map((e) => e['title'].toString()));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutCubic,
    ));

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final results = widget.results;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
          child: Column(
            children: [
              // Custom Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button and title row
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Color(0xFF0A2A36),
                                  size: 20,
                                ),
                                onPressed: () => Navigator.pop(context),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Hasil Pencarian",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0A2A36),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${results.length} tempat ditemukan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Query display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2A36).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0A2A36).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A2A36).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: const Color(0xFF0A2A36),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.query,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF0A2A36),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: results.isEmpty
                    ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2A36).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            Icons.search_off,
                            size: 80,
                            color: const Color(0xFF0A2A36).withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tidak ada hasil ditemukan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0A2A36).withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba gunakan kata kunci yang berbeda untuk menemukan tempat yang Anda cari',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2/3.1, // Adjusted for better proportions
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      final name = place['title'] ?? 'Tanpa Nama';
                      final category = place['categories'] ?? 'Kategori tidak tersedia';
                      final rating = double.tryParse(place['totalScore']?.toString() ?? place['rating']?.toString() ?? '0') ?? 0.0;
                      final price = place['price'].toString();
                      final image = (place['imageUrl'] == null || place['imageUrl'] == '' || place['imageUrl'] == '-')
                          ? 'assets/defaultBG.png'
                          : place['imageUrl'];

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 200 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(
                                  name: name,
                                  location: place['placeId'] ?? 'Unknown',
                                  address: place['kecamatan'] ?? 'Unknown',
                                  category: category,
                                  price: price,
                                  facility: place['activity'] ?? '',
                                  day: place['day'] ?? '',
                                  time: place['time'] ?? '',
                                  description: place['description'] ?? '',
                                  rating: rating,
                                  imagePath: image,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  var begin = const Offset(1.0, 0.0);
                                  var end = Offset.zero;
                                  var curve = Curves.ease;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
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

                              final placeId = place['placeId'];
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
                                    likedPlaces.remove(name);
                                  }
                                });
                                return true;
                              }

                              return false;
                            },
                          ),
                        ),
                      );
                    },
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