import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LibraryReportScreen extends StatefulWidget {
  const LibraryReportScreen({super.key});

  @override
  State<LibraryReportScreen> createState() => _LibraryReportScreenState();
}

class _LibraryReportScreenState extends State<LibraryReportScreen> {
  List<Map<String, dynamic>> _records = [];

  int _totalStudents = 0;
  int _totalReadBooks = 0;
  String _mostReadBook = "-";
  String _topReader = "-";

  bool get _isWebOrDesktop {
    if (kIsWeb) return true;
    return (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);
  }

  double get _scaleFactor => _isWebOrDesktop ? 0.7 : 1.0;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
    _fetchExtraStats();
  }

  Future<void> _fetchRecords() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("loans")
        .orderBy('borrowDate', descending: true)
        .get();

    List<Map<String, dynamic>> rawRecords = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "studentName": data['studentName'] ?? "",
        "bookTitle": data['bookTitle'] ?? "",
        "borrowDate": (data['borrowDate'] as Timestamp).toDate(),
        "returnDate": data['returnDate'] != null
            ? (data['returnDate'] as Timestamp).toDate()
            : null,
        "isReturned": data['isReturned'] ?? false,
      };
    }).toList();

    Map<String, Map<String, dynamic>> grouped = {};
    for (var r in rawRecords) {
      final key = "${r['studentName']}-${r['bookTitle']}";
      if (!grouped.containsKey(key)) {
        grouped[key] = r;
      } else {
        grouped[key]!['borrowDate'] =
            grouped[key]!['borrowDate'] ?? r['borrowDate'];
        grouped[key]!['returnDate'] =
            grouped[key]!['returnDate'] ?? r['returnDate'];
        grouped[key]!['isReturned'] =
            grouped[key]!['isReturned'] || r['isReturned'];
      }
    }

    setState(() {
      _records = grouped.values.toList();
    });
  }

  Future<void> _fetchExtraStats() async {
    final studentsSnap =
        await FirebaseFirestore.instance.collection("students").get();
    _totalStudents = studentsSnap.docs.length;

    final loansSnap =
        await FirebaseFirestore.instance.collection("loans").get();

    _totalReadBooks =
        loansSnap.docs.where((doc) => doc['isReturned'] == true).length;

    Map<String, int> bookCounts = {};
    Map<String, int> studentCounts = {};

    for (var doc in loansSnap.docs) {
      final data = doc.data();
      final book = data['bookTitle'] ?? "";
      final student = data['studentName'] ?? "";

      if (data['isReturned'] == true) {
        bookCounts[book] = (bookCounts[book] ?? 0) + 1;
        studentCounts[student] = (studentCounts[student] ?? 0) + 1;
      }
    }

    if (bookCounts.isNotEmpty) {
      _mostReadBook = bookCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    if (studentCounts.isNotEmpty) {
      _topReader = studentCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    setState(() {});
  }

  Map<String, int> _calculateStats() {
    int total = _records.length;
    int returned = _records.where((r) => r['isReturned']).length;
    int notReturned = total - returned;
    return {
      "total": total,
      "returned": returned,
      "notReturned": notReturned,
    };
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final stats = _calculateStats();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text("📚 Kütüphane Raporu",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text("Toplam ödünç verilen kitap: ${stats['total']}"),
          pw.Text("Teslim edilen kitap: ${stats['returned']}"),
          pw.Text("Teslim edilmeyen kitap: ${stats['notReturned']}"),
          pw.SizedBox(height: 20),
          pw.Text("Toplam öğrenci: $_totalStudents"),
          pw.Text("Toplam okunan kitap: $_totalReadBooks"),
          pw.Text("En fazla okunan kitap: $_mostReadBook"),
          pw.Text("En çok kitap okuyan öğrenci: $_topReader"),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ["Öğrenci", "Kitap", "Alış Tarihi", "İade Tarihi", "Durum"],
            data: _records.map((r) {
              final borrowDate =
                  DateFormat('dd/MM/yyyy').format(r['borrowDate']);
              final returnDate = r['returnDate'] != null
                  ? DateFormat('dd/MM/yyyy').format(r['returnDate'])
                  : "-";
              final status = r['isReturned']
                  ? "Ödünç Alındı → İade Edildi"
                  : "Devam Ediyor";
              return [
                r['studentName'],
                r['bookTitle'],
                borrowDate,
                returnDate,
                status
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ================= Excel oluşturma =================
  Future<void> _generateExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Kütüphane Raporu'];

    // Üst istatistikler
    sheet.appendRow(["Toplam Kayıt", _calculateStats()['total']]);
    sheet.appendRow(["Teslim Edilen Kitap", _calculateStats()['returned']]);
    sheet.appendRow(["Teslim Edilmeyen Kitap", _calculateStats()['notReturned']]);
    sheet.appendRow(["Toplam Öğrenci", _totalStudents]);
    sheet.appendRow(["Toplam Okunan Kitap", _totalReadBooks]);
    sheet.appendRow(["En Fazla Okunan Kitap", _mostReadBook]);
    sheet.appendRow(["En Çok Kitap Okuyan Öğrenci", _topReader]);
    sheet.appendRow([]);
    sheet.appendRow([
      "Öğrenci Adı",
      "Kitap Adı",
      "Alış Tarihi",
      "İade Tarihi",
      "Durum"
    ]);

    for (var r in _records) {
      final borrowDate = DateFormat('dd/MM/yyyy').format(r['borrowDate']);
      final returnDate = r['returnDate'] != null
          ? DateFormat('dd/MM/yyyy').format(r['returnDate'])
          : "-";
      final status = r['isReturned'] ? "İade Edildi" : "Devam Ediyor";

      sheet.appendRow([
        r['studentName'],
        r['bookTitle'],
        borrowDate,
        returnDate,
        status
      ]);
    }

    final fileBytes = excel.save();

    if (kIsWeb) {
      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "kutuphane_raporu.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/kutuphane_raporu.xlsx";
      final file = File(path);
      await file.writeAsBytes(fileBytes!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel dosyası kaydedildi: $path")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      appBar: AppBar(
        title: const Text("Kütüphane Raporu"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            onPressed: _generateExcel,
            icon: const Icon(Icons.file_download),
          ),
        ],
      ),
      body: Column(
        children: [
          // (Buradaki tasarım kodları birebir korunuyor)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCDD2), Color(0xFFFF8A80)],
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
            child: Center(
              child: Text(
                "Kütüphane Raporu",
                style: TextStyle(
                    fontSize: 26 * _scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard(Icons.library_books, "Toplam", stats['total']!,
                    Colors.red[300]!),
                _statCard(Icons.check_circle, "Teslim Edilen", stats['returned']!,
                    Colors.green[300]!),
                _statCard(Icons.error, "Teslim Edilmeyen", stats['notReturned']!,
                    Colors.orange[300]!),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _wideCard("Toplam Öğrenci", _totalStudents.toString(),
                    Colors.indigo),
                const SizedBox(height: 8),
                _wideCard("Toplam Okunan Kitap", _totalReadBooks.toString(),
                    Colors.teal),
                const SizedBox(height: 8),
                _wideCard("En Fazla Okunan Kitap", _mostReadBook, Colors.purple),
                const SizedBox(height: 8),
                _wideCard("En Çok Kitap Okuyan Öğrenci", _topReader,
                    Colors.deepOrange),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final r = _records[index];
                final borrowDate =
                    DateFormat('dd/MM/yyyy').format(r['borrowDate']);
                final returnDate = r['returnDate'] != null
                    ? DateFormat('dd/MM/yyyy').format(r['returnDate'])
                    : "Henüz İade Edilmedi";

                final hasBoth = r['isReturned'] && r['returnDate'] != null;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 6 * _scaleFactor),
                  child: Container(
                    decoration: hasBoth
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.redAccent, Colors.greenAccent],
                              stops: [0.5, 0.5],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : BoxDecoration(
                            color: r['isReturned']
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                    padding: EdgeInsets.all(12 * _scaleFactor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['bookTitle'],
                          style: TextStyle(
                              fontSize: 18 * _scaleFactor,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4 * _scaleFactor),
                        Text("Öğrenci: ${r['studentName']}",
                            style: TextStyle(fontSize: 14 * _scaleFactor)),
                        Text("Alış: $borrowDate",
                            style: TextStyle(fontSize: 14 * _scaleFactor)),
                        Text("İade: $returnDate",
                            style: TextStyle(fontSize: 14 * _scaleFactor)),
                        Text(
                          hasBoth
                              ? "Durum: Ödünç Alındı → İade Edildi"
                              : (r['isReturned']
                                  ? "Durum: İade Edildi"
                                  : "Durum: Devam Ediyor"),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * _scaleFactor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[400],
        onPressed: _generatePdf,
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, int value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        elevation: 3,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16 * _scaleFactor),
          child: Column(
            children: [
              Icon(icon, size: 36 * _scaleFactor, color: Colors.white),
              SizedBox(height: 8 * _scaleFactor),
              Text(
                label,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * _scaleFactor),
              ),
              SizedBox(height: 4 * _scaleFactor),
              Text(
                value.toString(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * _scaleFactor,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideCard(String title, String value, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12 * _scaleFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * _scaleFactor)),
            SizedBox(height: 4 * _scaleFactor),
            Text(value,
                style: TextStyle(color: Colors.white, fontSize: 14 * _scaleFactor)),
          ],
        ),
      ),
    );
  }
}
