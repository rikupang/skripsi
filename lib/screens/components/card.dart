import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class heightCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final double rating;
  final String price;
  final String image;
  final bool isLiked;
  final Future<bool> Function() onLikeToggle;

  const heightCard({
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
  State<heightCard> createState() => _heightCardState();
}

class _heightCardState extends State<heightCard> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isProcessing ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: "image",
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Image.network(
                  widget.image,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF007A8C),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ticket Price",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.price == "0"
                            ? "Free Entry"
                            : "Rp ${widget.price}K",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF336749),
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
                            ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : Icon(
                          widget.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                          widget.isLiked ? Colors.red : Colors.black45,
                          size: 22,
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
