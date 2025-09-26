import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedBookId;
  String? _selectedBookTitle;
  bool _loading = false;

  Future<void> _lend() async {
    if (_selectedStudentId == null || _selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci ve kitap seçmelisiniz')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final loansRef = FirebaseFirestore.instance.collection('loans');

      await loansRef.add({
        'studentId': _selectedStudentId,
        'studentName': _selectedStudentName,
        'bookId': _selectedBookId,
        'bookTitle': _selectedBookTitle,
        'borrowDate': FieldValue.serverTimestamp(),
        'returnDate': null,
        'isReturned': false,
      });

      // Kitabı ödünçli olarak işaretle
      if (_selectedBookId != null && _selectedBookId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(_selectedBookId)
            .update({'isLoaned': true});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kitap ödünç verildi')),
      );

      setState(() {
        _selectedBookId = null;
        _selectedBookTitle = null;
        _selectedStudentId = null;
        _selectedStudentName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _returnLoan(DocumentSnapshot loanDoc) async {
    try {
      final loanData = loanDoc.data() as Map<String, dynamic>;
      final bookId = loanData['bookId'] as String?;

      await loanDoc.reference.update({
        'isReturned': true,
        'returnDate': FieldValue.serverTimestamp(),
      });

      if (bookId != null && bookId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(bookId)
            .update({'isLoaned': false});
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('İade alındı')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('İade hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsStream = FirebaseFirestore.instance
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final availableBooksStream = FirebaseFirestore.instance
        .collection('books')
        .where('isLoaned', isEqualTo: false)
        .snapshots();

    final loansStream = FirebaseFirestore.instance
        .collection('loans')
        .where('isReturned', isEqualTo: false)
        .orderBy('borrowDate', descending: true)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9), // pastel yeşil arka plan
        body: Column(
          children: [
            // Üst panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA5D6A7), Color(0xFFC8E6C9)],
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back, color: Colors.green, size: 28),
                  ),
                  const Text(
                    "Kitap Ödünç/Teslim",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.logout, color: Colors.green, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Bar
            Container(
              color: Colors.green[400],
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(icon: Icon(Icons.person_add), text: 'Ödünç Ver'),
                  Tab(icon: Icon(Icons.keyboard_return), text: 'İade Al'),
                ],
              ),
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  // Ödünç Ver
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: studentsStream,
                          builder: (ctx, snap) {
                            if (!snap.hasData)
                              return const CircularProgressIndicator();
                            final studentDocs = snap.data!.docs;
                            return DropdownButtonFormField<String>(
                              value: _selectedStudentId,
                              hint: const Text('Kayıtlı öğrenci seç'),
                              items: studentDocs.map((d) {
                                final dat = d.data() as Map<String, dynamic>;
                                final name =
                                    '${dat['firstName'] ?? ''} ${dat['lastName'] ?? ''}';
                                return DropdownMenuItem(
                                    value: d.id, child: Text(name));
                              }).toList(),
                              onChanged: (v) {
                                final doc =
                                    studentDocs.firstWhere((d) => d.id == v);
                                final dat = doc.data() as Map<String, dynamic>;
                                setState(() {
                                  _selectedStudentId = v;
                                  _selectedStudentName =
                                      '${dat['firstName'] ?? ''} ${dat['lastName'] ?? ''}';
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: availableBooksStream,
                          builder: (ctx, snap) {
                            if (!snap.hasData)
                              return const CircularProgressIndicator();
                            final bookDocs = snap.data!.docs;
                            return DropdownButtonFormField<String>(
                              value: _selectedBookId,
                              hint: const Text('Kitap seç'),
                              items: bookDocs.map((d) {
                                final dat = d.data() as Map<String, dynamic>;
                                return DropdownMenuItem(
                                    value: d.id, child: Text(dat['title'] ?? ''));
                              }).toList(),
                              onChanged: (v) {
                                final doc =
                                    bookDocs.firstWhere((d) => d.id == v);
                                final dat = doc.data() as Map<String, dynamic>;
                                setState(() {
                                  _selectedBookId = v;
                                  _selectedBookTitle = dat['title'] ?? '';
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          onPressed: _loading ? null : _lend,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Kitabı Ödünç Ver',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // İade Al
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: loansStream,
                      builder: (ctx, snap) {
                        if (snap.hasError)
                          return Center(child: Text('Hata: ${snap.error}'));
                        if (!snap.hasData)
                          return const Center(child: CircularProgressIndicator());
                        final docs = snap.data!.docs;
                        if (docs.isEmpty)
                          return const Center(child: Text('Geri alınacak kitap yok'));

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final studentName = data['studentName'] ?? '';
                            final bookTitle = data['bookTitle'] ?? '';
                            final borrowDate = data['borrowDate'] != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format((data['borrowDate'] as Timestamp).toDate())
                                : '';

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.green[100],
                              child: ListTile(
                                title: Text(bookTitle,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Öğrenci: $studentName\nAlış: $borrowDate'),
                                trailing: ElevatedButton.icon(
                                  onPressed: () => _returnLoan(doc),
                                  icon: const Icon(Icons.keyboard_return,
                                      color: Colors.white),
                                  label: const Text('İade Al',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12))),
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
            ),
          ],
        ),
      ),
    );
  }
}
