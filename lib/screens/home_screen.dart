import 'package:flutter/material.dart';
import 'package:skripsi/screens/search_result.dart';
import '../service/addRating.dart';
import '../service/cbfWithInput.dart';
import '../service/collaboratifBasedApi.dart';
import '../service/contentBasedApi.dart';
import '../service/get_user_profile.dart';
import 'detail_screen.dart';
import 'content_based_filtering_screen.dart';
import 'collaborative_filtering_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? userData;
  List<dynamic> cbfRecommendations = [];
  List<dynamic> collabRecommendations = [];
  final Set<String> likedPlaces = {}; // Menyimpan tempat yang sudah di-like
  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isSearching = false;
  bool isLoading = true;
  bool hasLoadedOnce = false; // Flag untuk mencegah loading berulang
  final Color lightTealColor = const Color(0xFFE0F2F1);

  // Scroll controller untuk refresh
  final ScrollController _scrollController = ScrollController();
  // Tambahkan variabel ini di dalam class _HomeScreenState
  List<Map<String, dynamic>> allPlacesData = [];

  @override
  bool get wantKeepAlive => true; // Menjaga state tetap hidup

  @override
  void initState() {
    super.initState();
    // Load data hanya sekali saat inisialisasi
    if (!hasLoadedOnce) {
      loadAllData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }



  // Method untuk load semua data sekaligus
  Future<void> loadAllData() async {
    if (hasLoadedOnce && mounted) {
      // Jika sudah pernah load dan hanya refresh, tidak perlu loading indicator
      try {
        await Future.wait([
          fetchCBFData(),
          fetchCollabData(),
          _loadProfileData()
        ]);
      } catch (e) {
        print("Error saat memuat data: $e");
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Load kedua data secara parallel untuk efisiensi
      await Future.wait([
        fetchCBFData(),
        fetchCollabData(),
        _loadProfileData()
      ]);
      hasLoadedOnce = true; // Tandai bahwa data sudah pernah dimuat
    } catch (e) {
      print("Error saat memuat data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults.clear();
    });

    try {
      print("🔍 Mencari dengan query: '$query'");

      final results = await getRecommendationCBFInput(query);

      // Debug: Print raw results
      print("📦 Raw results: $results");
      print("📊 Results type: ${results.runtimeType}");
      print("📏 Results length: ${results?.length ?? 0}");

      if (results != null && results.isNotEmpty) {
        print("✅ Results found, processing...");

        final cleanedResults = results.map((e) {
          print("🧹 Processing item: $e");
          final cleanedMap = Map<String, dynamic>.from(e);
          cleanedMap.forEach((key, value) {
            if (value == null || value.toString().toLowerCase() == 'nan') {
              cleanedMap[key] = ''; // atau null jika ingin kosong
            }
          });
          print("✨ Cleaned item: $cleanedMap");
          return cleanedMap;
        }).toList();

        print("🎯 Final cleaned results: $cleanedResults");

        setState(() {
          searchResults = cleanedResults;
          isSearching = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultScreen(
              results: searchResults.cast<Map<String, dynamic>>(),
              query: query,
            ),
          ),
        );
      } else {
        print("❌ No results found or results is null/empty");
        print("   - results == null: ${results == null}");
        print("   - results.isEmpty: ${results?.isEmpty ?? 'N/A'}");

        setState(() {
          isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Tidak ada hasil ditemukan."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print("💥 Error occurred: $e");
      print("📍 Stack trace: $stackTrace");

      setState(() {
        isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saat mencari: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchCBFData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print("User belum login atau email tidak tersedia.");
      return;
    }

    final email = user.email!;
    final recommendations = await getRecommendationCBF(email);

    if (recommendations != null &&
        recommendations['recommendations'] != null &&
        recommendations['recommendations'] is List) {
      if (mounted) {
        setState(() {
          cbfRecommendations =
              (recommendations['recommendations'] as List).cast<Map<String, dynamic>>();

          // Populate likedPlaces set based on API data
          for (var place in cbfRecommendations) {
            if (place['like'] == true) {
              likedPlaces.add(place['id']);
            }
          }
        });
      }
    } else {
      print("Gagal mendapatkan data atau data kosong.");
    }
  }

  Future<void> fetchCollabData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print("User belum login atau email tidak tersedia.");
      return;
    }

    final email = user.email!;
    final recommendations = await getRecommendationWisata(email);

    if (recommendations.isNotEmpty) {
      if (mounted) {
        setState(() {
          collabRecommendations = recommendations;
        });
      }
    } else {
      print("Gagal mendapatkan data atau data kosong.");
    }
  }

  Future<void> _loadProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    try {
      final profile = await fetchUserProfile(uid);
      if (mounted) {
        setState(() {
          userData = profile;
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Diperlukan untuk AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.notifications, color: Colors.teal),
          onPressed: () {},
        ),
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Colors.teal),
            SizedBox(width: 5),
            Text("Bali, Indonesia", style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.teal,
            backgroundImage: userData?['profilePictureUrl'] != null
                ? NetworkImage(userData!['profilePictureUrl'])
                : null,
            child: userData?['profilePictureUrl'] == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header dan Search - Fixed di atas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("liburan santuy di bali",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          performSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: "Cari Objek Wisata",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: isSearching
                              ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                              ),
                            ),
                          )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Kategori",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: ["Pantai", "Gunung", "Air Terjun", "Bukit"]
                        .map((e) => FilterChip(
                      label: Text(e),
                      onSelected: (_) {},
                      selected: false,
                      backgroundColor: Colors.teal.shade600,
                      labelStyle: const TextStyle(color: Colors.white),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Content area - Scrollable
            Expanded(
              child: isLoading
                  ? Center(
                child: LoadingAnimation(),
              )
                  : RefreshIndicator(
                onRefresh: loadAllData,
                color: Colors.teal,
                backgroundColor: Colors.white,
                strokeWidth: 3,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cbfRecommendations.isNotEmpty)
                        buildHorizontalSection("Content Based", cbfRecommendations.map<Widget>((place) {
                          return buildHorizontalCard(
                            context,
                            place['title'] ?? 'Nama tidak tersedia',
                            place['categories'] ?? 'Kategori tidak tersedia',
                            (place['rating'] as num?)?.toDouble() ?? 0.0,
                            (place['price'] ?? 'Harga tidak tersedia').toString(),
                            place['imageUrl'] ?? 'assets/defaultBG.png',
                            place['id'],
                            place['description'] ?? 'Deskripsi tidak tersedia',
                            place['activity'] ?? 'Aktivitas tidak tersedia',
                            place['desa'] ?? 'Desa tidak tersedia',
                            place['kecamatan'] ?? 'Kecamatan tidak tersedia',
                            place['city'] ?? 'Kota tidak tersedia',
                            (place['Skor Similaritas'] as num?)?.toDouble() ?? 0.0,
                            likedPlaces.contains(place['id']),
                            place['day'] ?? '0',
                            place['time'] ?? '0',
                          );
                        }).toList()),

                      if (cbfRecommendations.isNotEmpty && collabRecommendations.isNotEmpty)
                        const SizedBox(height: 30),

                      if (collabRecommendations.isNotEmpty)
                        buildVerticalSection("Collaborative Filtering", collabRecommendations.map<Widget>((data) {
                          return buildVerticalCard(
                            context,
                            data['title'] ?? 'Nama tidak tersedia',
                            data['categories'] ?? 'Kategori tidak tersedia',
                            (data['totalScore'] as num?)?.toDouble() ?? 0.0,
                            (data['price'] ?? 'Harga tidak tersedia').toString(),
                            data['imageUrl'] ?? 'assets/defaultBG.png',
                            data['placeId'],
                            data['description'] ?? 'Deskripsi tidak tersedia',
                            data['activity'] ?? 'Aktivitas tidak tersedia',
                            data['desa'] ?? 'Desa tidak tersedia',
                            data['kecamatan'] ?? 'Kecamatan tidak tersedia',
                            data['city'] ?? 'Kota tidak tersedia',
                            (data['totalScore'] as num?)?.toDouble() ?? 0.0,
                            (data['Open Everyday'] ?? '0').toString(),
                            (data['Open 24 Hours'] ?? '0').toString(),
                          );
                        }).toList()),

                      // Tambahan jika tidak ada data
                      if (cbfRecommendations.isEmpty && collabRecommendations.isEmpty && !isLoading)
                        Container(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.travel_explore,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Belum ada rekomendasi tersedia",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tarik ke bawah untuk menyegarkan",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildVerticalSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CollaborativeFilteringScreen(
                      recommendations: List<Map<String, dynamic>>.from(collabRecommendations),
                    ),
                  ),
                );
              },
              child: Text(
                "See All",
                style: TextStyle(color: Colors.teal[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: cards
              .map((card) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: card,
          ))
              .toList(),
        ),
      ],
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
              name: name,
              location: placeId,
              address: kecamatan,
              category: category,
              price: price,
              facility: activity,
              day: day,
              time: time,
              description: description,
              rating: rating,
              imagePath: imagePath,
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
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/defaultBG.png',
                    height: 30,
                    width: 130,
                    fit: BoxFit.cover,
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
                    const SizedBox(height: 16),
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

  Widget buildHorizontalSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContentBasedFilteringScreen(
                      recommendations: List<Map<String, dynamic>>.from(cbfRecommendations))),
                );
              },
              child: Text(
                "See All",
                style: TextStyle(color: Colors.teal[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 270,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: cards
                .map((card) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: card,
            ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget buildHorizontalCard(
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
      double similarityScore,
      bool isLiked,
      String day,
      String time, {
        bool isHot = false,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              name: name,
              location: placeId,
              address: kecamatan,
              category: category,
              price: price,
              facility: activity,
              day: day,
              time: time,
              description: description,
              rating: rating,
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: "image_$placeId",
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Image.network(
                  imagePath,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/defaultBG.png',
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 130,
                      width: double.infinity,
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF007A8C),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    category,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Ticket Price",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price == "0" ? "Free Entry" : "Rp ${price}K",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF336749),
                        ),
                      ),
                      InkWell(
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget animasi loading elegan
class LoadingAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitFoldingCube(
          color: Colors.teal,
          size: 50.0,
        ),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: const Text(
            "Menyiapkan rekomendasi untukmu...",
            style: TextStyle(
              color: Colors.teal,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}