import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewsTab extends StatelessWidget {
  final String studentId;
  const ReviewsTab({required this.studentId, super.key});

  String _ratingNote(int rating) {
    switch (rating) {
      case 1: return 'Kitabı anlamamış';
      case 2: return 'Kitabı az anlamış';
      case 3: return 'Tekrar okusa daha iyi olur';
      case 4: return 'İyi anlamış';
      case 5: return 'Mükemmel okumuş';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansStream = FirebaseFirestore.instance
      .collection('loans')
      .where('studentId', isEqualTo: studentId)
      .orderBy('borrowDate', descending: true)
      .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: loansStream,
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Henüz değerlendirme yok'));

        return Padding(
          padding: const EdgeInsets.all(12),
          child: ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final bookTitle = data['bookTitle'] ?? '';
              final rating = (data['rating'] ?? 0).toDouble();
              final note = data['note'] ?? '';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bookTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBar.builder(
                            initialRating: rating,
                            minRating: 1,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 26,
                            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: (r) async {
                              final rInt = r.toInt();
                              final noteText = _ratingNote(rInt);
                              await doc.reference.update({'rating': rInt, 'note': noteText});
                              // optional: show snack
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Değerlendirme kaydedildi')));
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(note, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Alış tarihi: ${data['borrowDate'] != null ? (data['borrowDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : '-'}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            }
          ),
        );
      },
    );
  }
}
