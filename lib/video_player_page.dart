import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:idrm_video_app/aes_decrypt_service.dart';
import 'package:idrm_video_app/auth_service.dart';
import 'package:idrm_video_app/manual_crypto_service.dart';

import 'custom_appbar.dart';
import 'pdf_viewer_page.dart';
import 'video_player_screen.dart';

class SecureVideoPage extends StatefulWidget {
  const SecureVideoPage({super.key});

  @override
  State<SecureVideoPage> createState() => _SecureVideoPageState();
}

class _SecureVideoPageState extends State<SecureVideoPage> {
  String? status = "اختر فيديو مشفر للبدء";

  Future<void> pickAndDecrypt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);

    final fullPath = file.path;
    final fileName = fullPath.split(Platform.pathSeparator).last;

    String nameWithoutExt = fileName;
    String ext = "";
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1) {
      nameWithoutExt = fileName.substring(0, dotIndex);
      ext = fileName.substring(dotIndex + 1).toLowerCase();
    }

    final bool isPdf = ext == 'pdf';
    final bool isAesFile =
        !isPdf && nameWithoutExt.toLowerCase().endsWith('_e');

    setState(() => status = "📥 جاري قراءة الملف...");

    final String deviceSerial = await AuthService.getDeviceSerial();

    String courseId = "";
    File? outputFile;

    try {
      if (isPdf) {
        setState(() => status = "🔐 جاري فك التشفير (PDF )... 0٪");

        final manualResult = await decryptManualFromFile(
          file.path,
          onProgress: (progress) {
            final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
            setState(() {
              status = "🔐 جاري فك التشفير (PDF )... $percent٪";
            });
          },
        );

        courseId = manualResult.courseId;
        outputFile = manualResult.outputFile;
      } else if (isAesFile) {
        setState(() => status = "🔐 جاري فك التشفير (AS)... 0٪");

        final aesResult = await AesDecryptService.decryptFileToTemp(
          file,
          onProgress: (progress) {
            final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
            setState(() {
              status = "🔐 جاري فك التشفير (AS)... $percent٪";
            });
          },
        );

        courseId = aesResult.courseId;
        outputFile = aesResult.outputFile;
      } else {
        setState(() => status = "🔐 جاري فك التشفير (HD)... 0٪");

        final manualResult = await decryptManualFromFile(
          file.path,
          onProgress: (progress) {
            final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
            setState(() {
              status = "🔐 جاري فك التشفير (HD)... $percent٪";
            });
          },
        );

        courseId = manualResult.courseId;
        outputFile = manualResult.outputFile;
      }
    } catch (e) {
      setState(() {
        status = "❌ حدث خطأ أثناء فك التشفير: $e";
      });
      return;
    }

    if (!await outputFile.exists()) {
      setState(() {
        status = "❌ لم يتم إنشاء ملف بعد فك التشفير";
      });
      return;
    }

    // ✅ التحقق من صلاحية الموبايل لنفس الـ courseId
    final resultCheck = await AuthService.checkMobileAccess(
      deviceSerial: deviceSerial,
      courseId: courseId,
    );

    bool allowed = resultCheck.allowed;
    String reason = resultCheck.reason;

    if (!allowed) {
      switch (reason) {
        case "UserNotAllowed":
          status = "❌ لا يوجد اشتراك لهذا الكورس على جهازك";
          break;
        case "UserExpired":
          status = "❌ انتهت صلاحية اشتراكك في هذا الكورس";
          break;
        case "TeacherMobileNotPurchased":
          status = "❌ المحاضر غير مشترك في نسخة الموبايل";
          break;
        case "TeacherMobileExpired":
          status = "❌ اشتراك المحاضر في نسخة الموبايل منتهي";
          break;
        case "CourseNotFound":
          status = "❌ الكورس غير موجود";
          break;
        case "UserNotFound":
          status = "❌ لم يتم التفعيل بعد";
          break;
        default:
          status = "❌ لا يمكن فتح هذا الملف – خطأ غير معروف ($reason)";
      }

      setState(() {});
      return;
    }

    setState(() => status = "✔ لديك صلاحية — جاري فتح الملف...");

    if (!mounted) return;

    if (isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerPage(pdfFile: outputFile!)),
      );
    } else {
      // ✅ هنا التعديل المهم: نبعت courseId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VideoPlayerPage(videoFile: outputFile!, courseId: courseId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_open_rounded,
              size: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              "تشغيل فيديو مشفر",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              shadowColor: Colors.black26,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  status ?? "",
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.video_file_rounded,
                size: 26,
                color: Colors.white,
              ),
              label: const Text(
                "اختر الفيديو المشفر",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              onPressed: pickAndDecrypt,
            ),
          ],
        ),
      ),
    );
  }
}
