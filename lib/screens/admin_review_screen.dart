import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  String? _selectedStudentId;
  String? _selectedBookId;
  int _rating = 0;
  final TextEditingController _noteController = TextEditingController();

  Future<void> _submitReview() async {
    if (_selectedStudentId == null || _selectedBookId == null || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Öğrenci, kitap ve yıldız seçiniz')));
      return;
    }
    try {
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(_selectedStudentId).get();
      final bookDoc = await FirebaseFirestore.instance.collection('books').doc(_selectedBookId).get();

      await FirebaseFirestore.instance.collection('reviews').add({
        'studentId': _selectedStudentId,
        'bookId': _selectedBookId,
        'bookTitle': bookDoc['title'] ?? '',
        'author': bookDoc['author'] ?? '',
        'rating': _rating,
        'note': _noteController.text.trim(),
        'isLoaned': bookDoc['isLoaned'] ?? false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirme kaydedildi')));

      setState(() {
        _rating = 0;
        _noteController.clear();
        _selectedStudentId = null;
        _selectedBookId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsStream = FirebaseFirestore.instance.collection('students').snapshots();
    final booksStream = FirebaseFirestore.instance.collection('books').snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Değerlendirme')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: studentsStream,
              builder: (ctx, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final studentDocs = snap.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  hint: const Text('Öğrenci seç'),
                  items: studentDocs.map((d) {
                    final dat = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                        value: d.id,
                        child: Text('${dat['firstName']} ${dat['lastName']}'));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: booksStream,
              builder: (ctx, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                final bookDocs = snap.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBookId,
                  hint: const Text('Kitap seç'),
                  items: bookDocs.map((d) {
                    final dat = d.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: d.id, child: Text(dat['title'] ?? ''));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedBookId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submitReview, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
