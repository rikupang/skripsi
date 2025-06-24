import 'package:flutter/material.dart';
import '../service/addRating.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../service/cbfRecom.dart';
import '../service/showComments.dart';
import 'content_based_filtering_screen.dart';

class DetailScreen extends StatefulWidget {
  final String name;
  final String location;
  final String? address;
  final String? placeId;
  final String category;
  final String price;
  final String facility;
  final String day;
  final String time;
  final String description;
  final double rating;
  final String imagePath;
  final String? desa; // Added desa parameter
  final String? kecamatan; // Added kecamatan parameter

  const DetailScreen({
    super.key,
    required this.name,
    required this.location,
    this.address,
    this.placeId,
    required this.category,
    required this.price,
    required this.facility,
    required this.day,
    required this.time,
    required this.description,
    required this.rating,
    required this.imagePath,
    this.desa, // Optional desa parameter
    this.kecamatan, // Optional kecamatan parameter
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  Set<String> likedPlaces = {};
  TextEditingController searchController = TextEditingController();
  String selectedCategory = "Semua";
  bool _isLoading = true;
  bool _isLoadingRecommendation = false;
  String _error = '';

  List<Map<String, dynamic>> loadedComments = [];
  bool isLoadingComments = false;
  double currentRating = 0;
  bool isLiked = true;
  int likeCount = 5000;
  List<String> comments = ['Keren banget!', 'Wajib dikunjungi', 'View-nya mantap'];

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentRating = widget.rating;
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

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        double tempRating = currentRating;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Beri Rating",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() => tempRating = index + 1.0);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      final email = user?.email ?? 'anonymous@email.com';
                      final success = await postComment(
                        placeId: widget.placeId!,
                        email: email,
                        rating: tempRating,
                      );

                      if (success) {
                        setState(() => currentRating = tempRating);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal mengirim rating')),
                        );
                      }
                    },
                    child: const Text("Submit"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'anonymous@email.com';
    await postComment(
      placeId: widget.location,
      email: email,
      like: isLiked,
    );
  }

  void _showComments() async {
    setState(() => isLoadingComments = true);
    final data = await fetchComments(widget.location);
    setState(() {
      loadedComments = data;
      isLoadingComments = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.remove, size: 30, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text("Komentar",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: isLoadingComments
                        ? const Center(child: CircularProgressIndicator())
                        : loadedComments.isEmpty
                        ? const Text("Belum ada komentar.")
                        : ListView.builder(
                      controller: scrollController,
                      itemCount: loadedComments.length,
                      itemBuilder: (context, index) {
                        final comment = loadedComments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: comment['photoURL'] != ''
                                ? NetworkImage(comment['photoURL'])
                                : null,
                            child: comment['photoURL'] == ''
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(comment['comment'] ?? '-'),
                          subtitle: Text(comment['email'] ?? ''),
                          trailing: Text(
                            comment['date'] != null
                                ? DateTime.parse(comment['date'])
                                .toLocal()
                                .toString()
                                .substring(0, 16)
                                : '',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Tambahkan komentar...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.teal),
                        onPressed: () async {
                          if (_commentController.text.isNotEmpty) {
                            final user = FirebaseAuth.instance.currentUser;
                            final email = user?.email ?? 'anonymous@email.com';

                            final success = await postComment(
                              placeId: widget.location,
                              email: email,
                              comment: _commentController.text,
                            );

                            if (success) {
                              _commentController.clear();
                              Navigator.pop(context);
                              _showComments();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal mengirim komentar')),
                              );
                            }
                          }
                        },
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          child: Image.network(
                            widget.imagePath,
                            width: double.infinity,
                            height: 320,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/defaultBG.png',
                              height: 320,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: const Icon(Icons.more_vert, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(widget.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          GestureDetector(
                            onTap: _showRatingModal,
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                                const SizedBox(width: 4),
                                Text(widget.rating.toString(),
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Row(
                                  children: List.generate(5, (index) {
                                    if (widget.rating >= index + 1) {
                                      return const Icon(Icons.star, color: Colors.amber, size: 16);
                                    } else if (widget.rating > index && widget.rating < index + 1) {
                                      return const Icon(Icons.star_half, color: Colors.amber, size: 16);
                                    } else {
                                      return const Icon(Icons.star_border, color: Colors.amber, size: 16);
                                    }
                                  }),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Modified location and address display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.teal, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Only show address if it's not null and not empty
                                if (widget.address != null && widget.address!.isNotEmpty) ...[
                                  Text(
                                    widget.location,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  widget.address!,
                                  style: TextStyle(
                                    color: widget.address != null && widget.address!.isNotEmpty
                                        ? Colors.grey
                                        : Colors.black87,
                                    fontSize: widget.address != null && widget.address!.isNotEmpty
                                        ? 13
                                        : 14,
                                    fontWeight: widget.address != null && widget.address!.isNotEmpty
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Information section with consistent alignment
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Informasi Detail",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            buildInfoRow("Kategori", widget.category),
                            buildInfoRow("Tiket Masuk", widget.price),
                            buildInfoRow("Aktivitas", widget.facility),
                            buildInfoRow("Hari Operasional", widget.day),
                            buildInfoRow("Jam Operasional", widget.time),
                            // Add desa and kecamatan if available
                            if (widget.desa != null && widget.desa!.isNotEmpty)
                              buildInfoRow("Desa", widget.desa!),
                            if (widget.kecamatan != null && widget.kecamatan!.isNotEmpty)
                              buildInfoRow("Kecamatan", widget.kecamatan!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Deskripsi",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.description,
                              style: const TextStyle(
                                color: Colors.black87,
                                height: 1.6,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed bottom buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Recommendation button
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingRecommendation
                            ? null
                            : () => _getRecommendation(widget.name),
                        icon: _isLoadingRecommendation
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.recommend, size: 16),
                        label: Text(
                          _isLoadingRecommendation ? 'Loading...' : 'Lihat Rekomendasi',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Action buttons container
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Comment button
                        GestureDetector(
                          onTap: _showComments,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.comment_outlined,
                              color: Colors.teal,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Like button with counter
                        GestureDetector(
                          onTap: toggleLike,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isLiked
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    key: ValueKey(isLiked),
                                    color: isLiked ? Colors.red : Colors.teal,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 2),

                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Fixed width for consistent alignment
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}