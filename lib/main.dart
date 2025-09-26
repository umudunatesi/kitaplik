import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure ile oluşturulacak
import 'screens/welcome_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/parent_login_screen.dart';
import 'screens/student_register_screen.dart';
import 'screens/student_list_screen.dart';
import 'screens/book_register_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/loan_screen.dart';
import 'screens/student_dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize güvenli kontrol
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
    } catch (e, st) {
      debugPrint('Firebase initialization error: $e');
      debugPrintStack(stackTrace: st);
    }
  } else {
    debugPrint('Firebase already initialized, skipping.');
  }

  // FCM token alma
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();
  debugPrint('FCM Token: $token');

  // Foreground mesaj dinleme
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title} - ${message.notification?.body}');
    // İsteğe göre SnackBar veya dialog gösterilebilir
  });

  // Kullanıcı bildirime tıkladığında app açılışı
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification clicked: ${message.notification?.title}');
    // Örneğin mesaj detay ekranına yönlendirme yapılabilir
  });

  runApp(const OtokutuphaneApp());
}

class OtokutuphaneApp extends StatelessWidget {
  const OtokutuphaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otokutuphane',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const WelcomeScreen(),
        '/admin_login': (ctx) => const AdminLoginScreen(),
        '/parent_login': (ctx) => const ParentLoginScreen(),
        '/student_register': (ctx) => const StudentRegisterScreen(),
        '/student_list': (ctx) => const StudentListScreen(),
        '/book_register': (ctx) => const BookRegisterScreen(),
        '/book_list': (ctx) => const BookListScreen(),
        '/loan': (ctx) => const LoanScreen(),
        // StudentDashboard dinamik olduğundan burada route değil pushReplacement ile açılıyor
      },
    );
  }
}
