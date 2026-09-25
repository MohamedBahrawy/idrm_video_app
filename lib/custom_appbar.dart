import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      elevation: 2,
      centerTitle: true,

      // العنوان + اللوجو
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // اللوجو
          Image.asset("assets/logo2.png", height: 32, width: 32),

          const SizedBox(width: 10),

          // النص
          const Text(
            "IDRM Player",
            style: TextStyle(
              color: Colors.white, // الكتابة بالابيض
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),

      // علشان يمنع تحريك العنوان لليمين مع زر الرجوع
      automaticallyImplyLeading: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
