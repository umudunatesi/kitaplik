import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Öğrenci ekle
  Future<void> addStudent({
    required String firstName,
    required String lastName,
    required String tc,
    required String studentClass,
    required String schoolNumber,
  }) async {
    await _db.collection("students").add({
      "firstName": firstName,
      "lastName": lastName,
      "tc": tc,
      "class": studentClass,
      "schoolNumber": schoolNumber,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Ödünç kitap ekle
  Future<void> addLoan({
    required String studentId,
    required String bookTitle,
    required DateTime borrowDate,
    DateTime? returnDate,
  }) async {
    await _db.collection("loans").add({
      "studentId": studentId,
      "bookTitle": bookTitle,
      "borrowDate": borrowDate,
      "returnDate": returnDate,
    });
  }

  /// Kitap değerlendirmesi ekle
  Future<void> addReview({
    required String studentId,
    required String bookTitle,
    required int rating,
    required String comment,
  }) async {
    await _db.collection("reviews").add({
      "studentId": studentId,
      "bookTitle": bookTitle,
      "rating": rating,
      "comment": comment,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Mesaj ekle
  Future<void> addMessage({
    required String studentId,
    required String title,
    required String content,
  }) async {
    await _db.collection("messages").add({
      "studentId": studentId,
      "title": title,
      "content": content,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }
}
