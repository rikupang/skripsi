import 'package:flutter/material.dart';

class widthCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final double rating;
  final String price;
  final String image;
  final bool isLiked;
  final Future<bool> Function() onLikeToggle;

  const widthCard({
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
  State<widthCard> createState() => _widthCardState();
}

class _widthCardState extends State<widthCard> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isProcessing ? 0.5 : 1,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar di kiri
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                widget.image,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            // Konten di kanan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul dan icon like
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF007A8C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            setState(() {
                              isProcessing = true;
                            });
                            final result = await widget.onLikeToggle();
                            if (mounted) {
                              setState(() {
                                isProcessing = false;
                              });
                            }
                          },
                          child: isProcessing
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(
                            widget.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                            widget.isLiked ? Colors.red : Colors.black45,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Harga
                    Text(
                      "Ticket Price",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      widget.price == "0"
                          ? "Free Entry"
                          : "Rp ${widget.price}K",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF336749),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
