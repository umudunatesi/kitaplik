import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookRegisterScreen extends StatefulWidget {
  const BookRegisterScreen({super.key});

  @override
  State<BookRegisterScreen> createState() => _BookRegisterScreenState();
}

class _BookRegisterScreenState extends State<BookRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('books').add({
        'title': _titleCtrl.text.trim(),
        'author': _authorCtrl.text.trim(),
        'isLoaned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Kitap kaydedildi')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // pastel turuncu arka plan
      body: Column(
        children: [
          // Üst panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCC80), Color(0xFFFFE0B2)], // pastel turuncu tonları
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16)),
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
                // Geri tuşu
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFE65100)),
                ),
                const Text(
                  "Kitap Kayıt",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100)), // koyu turuncu
                ),
                // Çıkış tuşu
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.logout, color: Color(0xFFE65100)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Form
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kitap Adı',
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _authorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Yazar Adı Soyadı',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA726), // turuncu
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Kitabı Kaydet',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
