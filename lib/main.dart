import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'auth_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool allowed = await AuthService.checkVersion();

  if (!allowed) {
    runApp(const BlockedApp()); // تطبيق بسيط يقول النسخة قديمة
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDRM Player',
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}



class BlockedApp extends StatelessWidget {
  const BlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                "❌ لا يمكن فتح هذا الإصدار\nالرجاء تحديث التطبيق",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
