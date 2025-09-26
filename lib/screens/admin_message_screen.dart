import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum SendType { all, byClass, byStudent }

class AdminMessageScreen extends StatefulWidget {
  const AdminMessageScreen({super.key});

  @override
  State<AdminMessageScreen> createState() => _AdminMessageScreenState();
}

class _AdminMessageScreenState extends State<AdminMessageScreen> {
  SendType _sendType = SendType.all;
  String? _selectedClass;
  String? _selectedStudentId;
  final TextEditingController _messageController = TextEditingController();
  bool _loading = false;

  Future<void> sendPushNotification(String token, String message) async {
    const serverKey = 'YOUR_SERVER_KEY_HERE'; // Firebase Console > Cloud Messaging > Server Key

    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': 'Yeni Mesaj',
            'body': message,
          },
          'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'}
        }),
      );
    } catch (e) {
      debugPrint('Push notification error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj giriniz')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      QuerySnapshot studentsSnap;

      if (_sendType == SendType.all) {
        studentsSnap = await FirebaseFirestore.instance.collection('students').get();
      } else if (_sendType == SendType.byClass && _selectedClass != null) {
        studentsSnap = await FirebaseFirestore.instance
            .collection('students')
            .where('class', isEqualTo: _selectedClass)
            .get();
      } else if (_sendType == SendType.byStudent && _selectedStudentId != null) {
        studentsSnap = await FirebaseFirestore.instance
            .collection('students')
            .where(FieldPath.documentId, isEqualTo: _selectedStudentId)
            .get();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Öğrenci veya sınıf seçiniz')),
        );
        setState(() => _loading = false);
        return;
      }

      for (var studentDoc in studentsSnap.docs) {
        final studentData = studentDoc.data() as Map<String, dynamic>;
        final fcmToken = studentData['fcmToken'];

        // Firestore'a kaydet
        await FirebaseFirestore.instance.collection('messages').add({
          'studentId': studentDoc.id,
          'text': messageText,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Push bildirim gönder
        if (fcmToken != null) {
          await sendPushNotification(fcmToken, messageText);
        }
      }

      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj gönderildi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesaj Gönder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Gönderim tipi seçimi
            ListTile(
              title: const Text('Tüm öğrencilere'),
              leading: Radio<SendType>(
                value: SendType.all,
                groupValue: _sendType,
                onChanged: (v) => setState(() => _sendType = v!),
              ),
            ),
            ListTile(
              title: const Text('Sınıfa göre'),
              leading: Radio<SendType>(
                value: SendType.byClass,
                groupValue: _sendType,
                onChanged: (v) => setState(() => _sendType = v!),
              ),
            ),
            if (_sendType == SendType.byClass)
              DropdownButtonFormField<String>(
                value: _selectedClass,
                hint: const Text('Sınıf seç'),
                items: ['9', '10', '11', '12', 'Mezun']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClass = v),
              ),
            ListTile(
              title: const Text('Tek öğrenci'),
              leading: Radio<SendType>(
                value: SendType.byStudent,
                groupValue: _sendType,
                onChanged: (v) => setState(() => _sendType = v!),
              ),
            ),
            if (_sendType == SendType.byStudent)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('students').snapshots(),
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
                        child: Text('${dat['firstName']} ${dat['lastName']}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedStudentId = v),
                  );
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Mesaj',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendMessage,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
