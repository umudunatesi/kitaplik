import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatelessWidget {
  final String studentId;

  const StudentDashboard({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            "Öğrenci Paneli",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white54, width: 1),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1,1))]
                ),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1,1))]
                ),
                tabs: const [
                  Tab(text: "📚 Ödünç"),
                  Tab(text: "⭐ Değerlendirmeler"),
                  Tab(text: "💬 Mesajlar"),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF3E5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: TabBarView(
            children: [
              _buildLoansTab(),
              _buildReviewsTab(),
              _buildMessagesTab(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Ödünç Geçmişi ---
  Widget _buildLoansTab() {
    final isWebDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('loans')
          .where('studentId', isEqualTo: studentId)
          .orderBy('borrowDate', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('📭 Ödünç geçmişi yok'));

        if (isWebDesktop) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _buildLoanCard(data);
            },
          );
        }

        // Android
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildLoanCard(data);
          },
        );
      },
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> data) {
    final bookTitle = data['bookTitle'] ?? '';
    final borrowDate = data['borrowDate'] != null
        ? (data['borrowDate'] as Timestamp).toDate()
        : null;
    final returnDate = data['returnDate'] != null
        ? (data['returnDate'] as Timestamp).toDate()
        : null;
    final isReturned = data['isReturned'] ?? false;

    return Card(
      elevation: 4,
      color: Colors.lightBlue[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.book, color: Colors.white),
        ),
        title: Text(bookTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.indigo)),
        subtitle: Text(
          "📅 Alış: ${borrowDate != null ? DateFormat('dd/MM/yyyy').format(borrowDate) : '-'}\n"
          "📅 İade: ${returnDate != null ? DateFormat('dd/MM/yyyy').format(returnDate) : (isReturned ? '-' : 'Henüz iade edilmedi')}",
        ),
      ),
    );
  }

  // --- Değerlendirmeler ---
 Widget _buildReviewsTab() {
  final isWebDesktop = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reviews')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (ctx, snap) {
      if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snap.data!.docs;
      if (docs.isEmpty) return const Center(child: Text('⭐ Değerlendirme yok'));

      int crossAxis = isWebDesktop ? 4 : 2;
      double aspectRatio = isWebDesktop ? 2.5 : 0.85; // Kart yüksekliğini kısalttık

      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxis,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemCount: docs.length,
        itemBuilder: (ctx, i) {
          final data = docs[i].data() as Map<String, dynamic>;
          return _buildReviewCard(data, isWebDesktop);
        },
      );
    },
  );
}

Widget _buildReviewCard(Map<String, dynamic> data, bool isWebDesktop) {
  final bookTitle = data['bookTitle'] ?? '';
  final author = data['author'] ?? '';
  final rating = data['rating'] ?? 0;
  final note = data['note'] ?? '';
  final isLoaned = data['isLoaned'] ?? false;

  return Card(
    elevation: 5,
    color: Colors.green[100],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bookTitle,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isWebDesktop ? 14 : 16)), // Web’de font biraz küçültüldü
          Text(author,
              style: TextStyle(color: Colors.grey, fontSize: isWebDesktop ? 12 : 14)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber[800],
                size: isWebDesktop ? 20 : 24,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              note,
              maxLines: isWebDesktop ? 2 : 5, // Web’de not daha kısa gösteriliyor
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Chip(
              label: Text(isLoaned ? 'Ödünçte' : 'Boşta'),
              backgroundColor: isLoaned ? Colors.red[100] : Colors.green[200],
              labelStyle: TextStyle(
                color: isLoaned ? Colors.red : Colors.green[800],
                fontWeight: FontWeight.bold,
                fontSize: isWebDesktop ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- Mesajlar ---
  Widget _buildMessagesTab(BuildContext context) {
    final isWebDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Tümünü Sil'),
                    content: const Text('Tüm mesajları silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final allMessages = await FirebaseFirestore.instance
                      .collection('messages')
                      .get();
                  for (var doc in allMessages.docs) {
                    await doc.reference.delete();
                  }
                }
              },
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Tümünü Sil', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());

              final allDocs = snap.data!.docs;
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final recipients = (data['recipients'] as List<dynamic>?) ?? ['all'];
                return recipients.contains('all') || recipients.contains(studentId);
              }).toList();

              if (docs.isEmpty) return const Center(child: Text('💬 Mesaj yok'));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final isRead = data['isRead'] == true;

                  Color cardColor;
                  if (isWebDesktop) {
                    cardColor = isRead ? Colors.blue[100]! : Colors.green[100]!;
                  } else {
                    cardColor = isRead ? Colors.grey[200]! : Colors.lightGreen[100]!;
                  }

                  return Card(
                    elevation: 6,
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(data['title'] ?? 'Başlıksız',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            data['body'] ?? '',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(
                                (data['timestamp'] as Timestamp).toDate()),
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
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
    );
  }
}
