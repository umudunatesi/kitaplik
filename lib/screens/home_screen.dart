import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'library_report_screen.dart';
import 'admin_send_message_screen.dart';

class HomeScreen extends StatelessWidget {
  final String adminName;

  const HomeScreen({super.key, this.adminName = "Admin"});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb;

    // 2 satır için crossAxisCount = 4 (8 buton → 2 satır)
    const crossAxisCount = 4;

    // childAspectRatio: ekran genişliği / satır başına buton sayısı ve yükseklik ile hesap
    final itemHeight = (size.height - 180) / 2; // üst panel ve padding çıkarıldı
    final itemWidth = (size.width - 16 * (crossAxisCount + 1)) / crossAxisCount;
    final childAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      body: Column(
        children: [
          // Üst panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(height: 8),
                    Text(
                      "Admin Paneli",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Cumhuriyet Kitaplık",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Hoşgeldiniz, $adminName",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  CustomButton(
                    title: 'Öğrenci Kayıt',
                    icon: Icons.person_add,
                    color: Colors.teal,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/student_register'),
                  ),
                  CustomButton(
                    title: 'Öğrenci Listeleme',
                    icon: Icons.people,
                    color: Colors.deepPurple,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/student_list'),
                  ),
                  CustomButton(
                    title: 'Kitap Kayıt',
                    icon: Icons.book,
                    color: Colors.orange,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/book_register'),
                  ),
                  CustomButton(
                    title: 'Kitap Listeleme',
                    icon: Icons.menu_book,
                    color: Colors.indigo,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/book_list'),
                  ),
                  CustomButton(
                    title: 'Kitap Ödünç/Teslim',
                    icon: Icons.swap_horiz,
                    color: Colors.green,
                    onPressed: () => Navigator.pushNamed(context, '/loan'),
                  ),
                  CustomButton(
                    title: 'Kütüphane Raporu',
                    icon: Icons.bar_chart,
                    color: Colors.redAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LibraryReportScreen()),
                      );
                    },
                  ),
                  CustomButton(
                    title: 'Veliye Mesaj Gönder',
                    icon: Icons.message,
                    color: Colors.blueGrey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AdminSendMessageScreen()),
                      );
                    },
                  ),
                  CustomButton(
                    title: 'Ayarlar',
                    icon: Icons.settings,
                    color: Colors.cyan,
                    onPressed: () {},
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
