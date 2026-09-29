import 'package:flutter/material.dart';
import 'package:idrm_video_app/my_courses_page.dart';
import 'video_player_page.dart';
import 'request_access_page.dart';
import 'custom_appbar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  final String appVersion = "9.0.0"; // رقم الإصدار

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== اللوجو فوق =======
              SizedBox(
                width: 140,
                height: 140,
                child: Image.asset("assets/logo2.png", fit: BoxFit.contain),
              ),

              const SizedBox(height: 10),

              // ===== رقم الإصدار =======
              Text(
                "Version $appVersion",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 40),
              // ===== زر تشغيل الفيديو =====
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecureVideoPage()),
                  );
                },
                child: const Text(
                  "Play Video",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),

              const SizedBox(height: 18),

              // ===== زر كورساتي =====
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCoursesPage()),
                  );
                },
               child: const Text(
              "My Courses",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
              ),

              const SizedBox(height: 14),

              // ===== زر طلب صلاحية =====
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequestAccessPage(),
                    ),
                  );
                },
                child: const Text(
                  "Send Course Request",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
