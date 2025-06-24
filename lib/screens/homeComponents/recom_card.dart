import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../detail_screen.dart';


class HorizontalCard extends StatelessWidget {
  final String name, category, price, imagePath, placeId, description, activity, desa, kecamatan, kota, day, time;
  final double rating, similarityScore;
  final bool isLiked;
  final VoidCallback onLikeTap;

  const HorizontalCard({
    super.key,
    required this.name,
    required this.category,
    required this.price,
    required this.imagePath,
    required this.placeId,
    required this.description,
    required this.activity,
    required this.desa,
    required this.kecamatan,
    required this.kota,
    required this.rating,
    required this.similarityScore,
    required this.day,
    required this.time,
    required this.isLiked,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imagePath,
                height: 100,
                width: 160,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                      Text(rating.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    "Ticket Price",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    price,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                description,
                style: const TextStyle(fontSize: 12),
                maxLines: 2, // Allow for two lines of description before truncation
                overflow: TextOverflow.ellipsis, // Truncate with ellipsis if text overflows
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: onLikeTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class VerticalCard extends StatelessWidget {
  final String name, category, price, imagePath, placeId, description, activity, desa, kecamatan, kota, day, time;
  final double rating, similarityScore;
  final bool isLiked;
  final VoidCallback onLikeTap;

  const VerticalCard({
    super.key,
    required this.name,
    required this.category,
    required this.price,
    required this.imagePath,
    required this.placeId,
    required this.description,
    required this.activity,
    required this.desa,
    required this.kecamatan,
    required this.kota,
    required this.rating,
    required this.similarityScore,
    required this.day,
    required this.time,
    required this.isLiked,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagePath,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(category, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toString(), style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Rp. $price", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
              onPressed: onLikeTap,
            ),
          ],
        ),
      ),
    );
  }
}

