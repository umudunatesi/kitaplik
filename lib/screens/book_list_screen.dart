import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});

  Future<void> _deleteDoc(BuildContext context, DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: const Text('Bu kitabı silmek istediğinize emin misiniz?'),
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

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // pastel açık mavi arka plan
      body: Column(
        children: [
          // Üst panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF90CAF9)], // pastel koyu mavi tonları
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Geri tuşu
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text(
                  "Kitap Listeleme",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                // Çıkış tuşu
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Kitap listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (ctx, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Kayıtlı kitap yok'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    final subtitle = data['author'] ?? '';
                    final isLoaned = data['isLoaned'] ?? false;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: const Color(0xFFBBDEFB), // pastel mavi card
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLoaned)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Ödünç',
                                    style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.deepPurple),
                              onPressed: () => _deleteDoc(context, d),
                            ),
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
  }
}
