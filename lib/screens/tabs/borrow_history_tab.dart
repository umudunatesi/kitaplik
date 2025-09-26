import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BorrowHistoryTab extends StatelessWidget {
  final String studentId;
  const BorrowHistoryTab({required this.studentId, super.key});

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
        if (docs.isEmpty) return const Center(child: Text('Henüz ödünç geçmişi yok'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final bookTitle = data['bookTitle'] ?? '';
            final borrowDateTs = data['borrowDate'] as Timestamp?;
            final returnDateTs = data['returnDate'] as Timestamp?;
            final isReturned = data['isReturned'] ?? false;

            final borrowDate = borrowDateTs != null ? DateFormat('dd/MM/yyyy').format(borrowDateTs.toDate()) : '-';
            final returnDate = returnDateTs != null ? DateFormat('dd/MM/yyyy').format(returnDateTs.toDate()) : '-';

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.book, size: 36, color: Colors.indigo),
                title: Text(bookTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Alış: $borrowDate  •  İade: $returnDate'),
                trailing: Chip(
                  label: Text(isReturned ? 'İade edildi' : 'Ödünçte'),
                  backgroundColor: isReturned ? Colors.green[100] : Colors.orange[100],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
