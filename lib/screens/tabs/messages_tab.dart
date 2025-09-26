import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessagesTab extends StatefulWidget {
  final String studentId;
  const MessagesTab({required this.studentId, super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'studentId': widget.studentId,
        'sender': 'parent',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderme hatası: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('studentId', isEqualTo: widget.studentId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesStream,
            builder: (ctx, snap) {
              if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('Henüz mesaj yok'));

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  final sender = d['sender'] ?? '';
                  final text = d['text'] ?? '';
                  final ts = d['timestamp'] as Timestamp?;
                  final time = ts != null ? DateFormat('dd/MM HH:mm').format(ts.toDate()) : '';
                  final isParent = sender == 'parent';

                  return Align(
                    alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isParent ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text),
                          const SizedBox(height: 6),
                          Text(time, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // input row
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yaz...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sending ? null : _sendMessage,
                  child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
