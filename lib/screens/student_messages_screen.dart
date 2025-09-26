import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentMessagesScreen extends StatelessWidget {
  final String studentId;
  const StudentMessagesScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: StreamBuilder<QuerySnapshot>(
        stream: messagesStream,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('Mesaj bulunmamaktadır'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Başlıksız';
              final body = data['body'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final timeString = timestamp != null
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month} '
                    '${timestamp.toDate().hour.toString().padLeft(2,'0')}:${timestamp.toDate().minute.toString().padLeft(2,'0')}'
                  : '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$body\n$timeString'),
                  isThreeLine: true,
                  leading: const Icon(Icons.message),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
