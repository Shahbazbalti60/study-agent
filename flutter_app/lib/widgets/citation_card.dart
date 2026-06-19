import 'package:flutter/material.dart';
import '../models/models.dart';

class CitationCard extends StatelessWidget {
  final Citation citation;
  const CitationCard({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${citation.source} — Page ${citation.page}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            citation.snippet,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
