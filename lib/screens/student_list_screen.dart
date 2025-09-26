import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchText = '';

  Future<void> _deleteDoc(BuildContext context, DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: const Text('Bu öğrenciyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hayır')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Evet')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silindi')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
    }
  }

  String _ratingNote(double rating) {
    if (rating == 1) return 'Kitabı anlamamış';
    if (rating == 2) return 'Az anlamış';
    if (rating == 3) return 'Tekrar okusa daha iyi olur';
    if (rating == 4) return 'İyi anlamış';
    if (rating == 5) return 'Mükemmel okumuş';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final studentsStream = FirebaseFirestore.instance
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // arka plan açık mor-pembe pastel
      body: Column(
        children: [
          // Üst panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCE93D8), Color(0xFFF3E5F5)], // mor pastel tonları
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Öğrenci Listeleme",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF512DA8)), // koyu mor
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF512DA8)),
                    ),
                    IconButton(
                      onPressed: () {}, // çıkış
                      icon: const Icon(Icons.logout, color: Color(0xFF512DA8)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Öğrenci ara...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() {
                _searchText = val.toLowerCase();
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Öğrenci listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: studentsStream,
              builder: (ctx, snap) {
                if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snap.data!.docs;

                // Arama filtrelemesi
                if (_searchText.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
                    return name.contains(_searchText);
                  }).toList();
                }

                if (docs.isEmpty) return const Center(child: Text('Kayıtlı öğrenci yok'));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text('Toplam öğrenci: ${docs.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (c, i) {
                          final d = docs[i];
                          final data = d.data() as Map<String, dynamic>;
                          final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                          final subtitle = 'Sınıf: ${data['class'] ?? ''} • No: ${data['schoolNumber'] ?? ''}';

                          return Card(
                            color: const Color(0xFFE1BEE7), // mor-pembe pastel öğrenci kartı
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ExpansionTile(
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: Color(0xFF512DA8))),
                              subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF512DA8))),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFF512DA8)), // koyu mor
                                onPressed: () => _deleteDoc(context, d),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance.collection('books').get(),
                                    builder: (ctx2, bookSnap) {
                                      if (!bookSnap.hasData) return const CircularProgressIndicator();
                                      final bookDocs = bookSnap.data!.docs;

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                          childAspectRatio: 0.7,
                                        ),
                                        itemCount: bookDocs.length,
                                        itemBuilder: (ctx3, j) {
                                          final bookData = bookDocs[j].data() as Map<String, dynamic>;
                                          final bookId = bookDocs[j].id;

                                          return Card(
                                            color: const Color(0xFFC8E6C9), // pastel yeşil
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 1.5,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: 60,
                                                    child: Text(bookData['title'] ?? '',
                                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                  Text('Yazar: ${bookData['author'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                                  const SizedBox(height: 4),
                                                  StreamBuilder<QuerySnapshot>(
                                                    stream: FirebaseFirestore.instance
                                                        .collection('reviews')
                                                        .where('studentId', isEqualTo: d.id)
                                                        .where('bookId', isEqualTo: bookId)
                                                        .snapshots(),
                                                    builder: (ctx4, reviewSnap) {
                                                      double rating = 0;
                                                      if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
                                                        final rev = reviewSnap.data!.docs.first.data() as Map<String, dynamic>;
                                                        rating = (rev['rating'] ?? 0).toDouble();
                                                      }
                                                      return RatingBar.builder(
                                                        initialRating: rating,
                                                        minRating: 1,
                                                        direction: Axis.horizontal,
                                                        allowHalfRating: false,
                                                        itemCount: 5,
                                                        itemSize: 20,
                                                        itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                                        onRatingUpdate: (r) async {
                                                          final reviewQuery = await FirebaseFirestore.instance
                                                              .collection('reviews')
                                                              .where('studentId', isEqualTo: d.id)
                                                              .where('bookId', isEqualTo: bookId)
                                                              .get();

                                                          if (reviewQuery.docs.isEmpty) {
                                                            await FirebaseFirestore.instance.collection('reviews').add({
                                                              'studentId': d.id,
                                                              'bookId': bookId,
                                                              'bookTitle': bookData['title'],
                                                              'author': bookData['author'],
                                                              'rating': r,
                                                              'note': _ratingNote(r),
                                                              'isLoaned': false,
                                                              'createdAt': FieldValue.serverTimestamp(),
                                                            });
                                                          } else {
                                                            await FirebaseFirestore.instance
                                                                .collection('reviews')
                                                                .doc(reviewQuery.docs.first.id)
                                                                .update({
                                                              'rating': r,
                                                              'note': _ratingNote(r),
                                                              'createdAt': FieldValue.serverTimestamp(),
                                                            });
                                                          }
                                                        },
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(_ratingNote(0), style: const TextStyle(fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
