// lib/manual_crypto_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

// ====== Helpers ======

String bytesToHex(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    buffer.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
  }
  return buffer.toString();
}

Uint8List hexToBytes(String hex) {
  final cleanHex = hex.replaceAll(RegExp(r'\s+'), '');
  final length = cleanHex.length;
  final result = Uint8List(length ~/ 2);

  for (int i = 0; i < length; i += 2) {
    result[i ~/ 2] = int.parse(cleanHex.substring(i, i + 2), radix: 16);
  }
  return result;
}

Uint8List replaceBytes(Uint8List src, String replace, String replaceWith) {
  String hex = bytesToHex(src);
  hex = hex.replaceAll(replace, replaceWith);
  return hexToBytes(hex);
}

Uint8List cutBytes(Uint8List src) {
  String hex = bytesToHex(src);
  if (hex.length <= 6) return Uint8List(0);
  hex = hex.substring(0, hex.length - 6);
  return hexToBytes(hex);
}

String getLastBytes6(Uint8List src) {
  String hex = bytesToHex(src);
  if (hex.length < 6) return hex;
  return hex.substring(hex.length - 6);
}

String getFirstBytes(Uint8List src) {
  String hex = bytesToHex(src);
  if (hex.length < 4) return hex;
  return hex.substring(0, 4);
}

// =========================
// التشفير اليدوي (Streaming + TEMP)
// =========================

class ManualDecryptResult {
  final String courseId;
  final File outputFile;

  ManualDecryptResult({required this.courseId, required this.outputFile});
}

Future<ManualDecryptResult> decryptManualFromFile(
  String encryptedPath, {
  void Function(double progress)? onProgress, // 👈 Progress
}) async {
  final inputFile = File(encryptedPath);
  final raf = await inputFile.open();

  final totalLength = await inputFile.length();
  if (totalLength < 2) {
    await raf.close();
    throw Exception("الملف صغير جدًا ولا يمكن فك تشفيره");
  }

  int readSoFar = 0;

  // 1) نقرأ أول 2 بايت فقط
  final firstTwo = await raf.read(2);
  readSoFar += firstTwo.length;
  if (onProgress != null) {
    onProgress((readSoFar / totalLength).clamp(0.0, 1.0));
  }

  final first4 = getFirstBytes(Uint8List.fromList(firstTwo));
  int offset = int.tryParse(first4) ?? 0;

  int headerLength = offset + 3;
  if (headerLength > totalLength - 2) {
    headerLength = totalLength.toInt() - 2;
  }

  // 2) نقرأ الهيدر فقط
  final headerBytes = await raf.read(headerLength);
  readSoFar += headerBytes.length;
  if (onProgress != null) {
    onProgress((readSoFar / totalLength).clamp(0.0, 1.0));
  }

  Uint8List bt2 = Uint8List.fromList(headerBytes);

  // 3) Replace
  bt2 = replaceBytes(bt2, "ABC", "A");

  // 4) آخر 6 حروف فيها titleId
  String titleCompany = getLastBytes6(bt2);
  int titleId = 0;
  if (titleCompany.length >= 6) {
    titleId = int.tryParse(titleCompany.substring(3, 6)) ?? 0;
  }

  // 5) نحذف آخر 6 حروف
  bt2 = cutBytes(bt2);

  // 6) حفظ الملف في TEMP
  final tempDir = await getTemporaryDirectory();
  final fileName = inputFile.path.split(Platform.pathSeparator).last;
  final outputPath = "${tempDir.path}/dec_$fileName";
  final outFile = File(outputPath);

  if (await outFile.exists()) await outFile.delete();
  final outRaf = await outFile.open(mode: FileMode.write);

  // نكتب الهيدر المعدل
  await outRaf.writeFrom(bt2);

  // 7) انسخ باقي الملف chunk-by-chunk مع Progress
  const int chunkSize = 1024 * 1024; // 1MB
  while (true) {
    final chunk = await raf.read(chunkSize);
    if (chunk.isEmpty) break;

    readSoFar += chunk.length;
    if (onProgress != null) {
      onProgress((readSoFar / totalLength).clamp(0.0, 1.0));
    }

    await outRaf.writeFrom(chunk);
  }

  await raf.close();
  await outRaf.close();

  // آخر دفعة (احتياطي)
  if (onProgress != null) onProgress(1.0);

  return ManualDecryptResult(
    courseId: titleId.toString(),
    outputFile: outFile,
  );
}
