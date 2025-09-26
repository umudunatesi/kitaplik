import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSendMessageScreen extends StatefulWidget {
  const AdminSendMessageScreen({super.key});

  @override
  State<AdminSendMessageScreen> createState() => _AdminSendMessageScreenState();
}

enum RecipientType { all, single }

class _AdminSendMessageScreenState extends State<AdminSendMessageScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  RecipientType _recipientType = RecipientType.all;
  String? _selectedStudentId;
  bool _loading = false;

  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('students').get();
    setState(() {
      students = snapshot.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    });
  }

  Future<void> _sendMessage() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Başlık ve mesaj giriniz')));
      return;
    }

    setState(() => _loading = true);
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    try {
      List<Map<String, dynamic>> targets = [];

      if (_recipientType == RecipientType.all) {
        targets = students;
      } else if (_recipientType == RecipientType.single && _selectedStudentId != null) {
        targets = students.where((s) => s['id'] == _selectedStudentId).toList();
      }

      for (var student in targets) {
        await FirebaseFirestore.instance.collection('messages').add({
          'studentId': student['id'],
          'title': title,
          'body': body,
          'timestamp': FieldValue.serverTimestamp(),
          'sender': 'admin',
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mesaj gönderildi')));
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _recipientType = RecipientType.all;
        _selectedStudentId = null;
      });
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
    const panelColor = Color(0xFFB2DFDB); // pastel su yeşili
    const fieldColor = Color(0xFFE0F2F1); // alanlar için daha açık uyumlu renk

    return Scaffold(
      backgroundColor: fieldColor,
      body: Column(
        children: [
          // Üst panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: BoxDecoration(
              color: panelColor,
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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.teal, size: 28),
                ),
                const Text(
                  "Mesaj Gönder",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.logout, color: Colors.teal, size: 28),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alıcı kartı
                  Card(
                    color: panelColor,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alıcılar',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ListTile(
                            title: const Text('Tüm Kullanıcılara'),
                            leading: Radio<RecipientType>(
                              value: RecipientType.all,
                              groupValue: _recipientType,
                              onChanged: (val) =>
                                  setState(() => _recipientType = val!),
                            ),
                          ),
                          ListTile(
                            title: const Text('Kayıtlı Öğrenci Seçimi'),
                            leading: Radio<RecipientType>(
                              value: RecipientType.single,
                              groupValue: _recipientType,
                              onChanged: (val) =>
                                  setState(() => _recipientType = val!),
                            ),
                          ),
                          // Dropdown kısmı
if (_recipientType == RecipientType.single)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: panelColor.withOpacity(0.7), // panel ile uyumlu pastel ton
      borderRadius: BorderRadius.circular(8),
    ),
    child: DropdownButton<String>(
      isExpanded: true,
      hint: Text(
        'Öğrenci seç',
        style: TextStyle(color: Colors.teal[800]), // uyumlu yazı rengi
      ),
      value: _selectedStudentId,
      items: students.map((s) {
        return DropdownMenuItem<String>(
          value: s['id'] as String,
          child: Text(
            '${s['firstName']} ${s['lastName']}',
            style: TextStyle(color: Colors.teal[900]), // uyumlu yazı rengi
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedStudentId = val),
      underline: const SizedBox(),
      dropdownColor: panelColor.withOpacity(0.9), // açılır menü rengi
    ),
  ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Başlık alanı
                  Container(
                    color: fieldColor,
                    child: TextField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Mesaj Başlığı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Mesaj alanı
                  Container(
                    color: fieldColor,
                    child: TextField(
                      controller: _bodyController,
                      maxLength: 500,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Mesaj İçeriği',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Gönder butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: panelColor, foregroundColor: Colors.teal),
                      onPressed: _loading ? null : _sendMessage,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Mesajı Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
