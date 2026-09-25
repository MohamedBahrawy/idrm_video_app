// lib/aes_decrypt_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

class AesDecryptResult {
  final String courseId;
  final File outputFile;

  AesDecryptResult({required this.courseId, required this.outputFile});
}

class AesDecryptService {
  // نفس الـ KEY و IV بتوع VB
  static final Uint8List _key = Uint8List.fromList(
    utf8.encode("0123456789ABCDEF0123456789ABCDEF"),
  ); // 32
  static final Uint8List _iv = Uint8List.fromList(
    utf8.encode("ABCDEF0123456789"),
  ); // 16

  static CBCBlockCipher _createAesCbc() {
    final cbc = CBCBlockCipher(AESEngine());
    final params = ParametersWithIV<KeyParameter>(KeyParameter(_key), _iv);
    cbc.init(false, params); // false = decrypt
    return cbc;
  }

  /// فك ملف AES على أجزاء وكتابة الناتج فى TEMP
  /// أول 8 بايت بعد فك التشفير = courseId (نص)
  static Future<AesDecryptResult> decryptFileToTemp(
    File inputFile, {
    void Function(double progress)? onProgress, // 👈 جديد
  }) async {
    if (!await inputFile.exists()) {
      throw Exception("ملف التشفير غير موجود");
    }

    final cbc = _createAesCbc();
    final blockSize = cbc.blockSize; // 16 بايت فى AES

    // حجم الملف بالكامل عشان نطلع نسبة
    final totalSize = await inputFile.length();
    int readSoFar = 0;

    // تجهيز ملف إخراج داخل TEMP
    final tempDir = await getTemporaryDirectory();
    final outPath = "${tempDir.path}/temp_video_aes.mp4";
    final outFile = File(outPath);
    if (await outFile.exists()) {
      await outFile.delete();
    }
    final outRaf = await outFile.open(mode: FileMode.write);

    bool headerRead = false;
    final headerBuffer = BytesBuilder();
    String courseId = "";

    Future<void> handleDecrypted(Uint8List decrypted) async {
      if (decrypted.isEmpty) return;

      if (!headerRead) {
        headerBuffer.add(decrypted);
        if (headerBuffer.length >= 8) {
          final all = headerBuffer.toBytes();

          final headerBytes = all.sublist(0, 8);
          courseId = utf8.decode(headerBytes);
          headerRead = true;

          if (all.length > 8) {
            await outRaf.writeFrom(all, 8);
          }

          headerBuffer.clear();
        }
      } else {
        await outRaf.writeFrom(decrypted);
      }
    }

    Uint8List buffer = Uint8List(0);

    // نقرأ الملف على أجزاء (stream)
    await for (final chunk in inputFile.openRead()) {
      // نعدّ البايتات المقروءة لحد دلوقتى
      readSoFar += chunk.length;
      if (onProgress != null && totalSize > 0) {
        final prog = readSoFar / totalSize;
        onProgress(prog.clamp(0.0, 1.0));
      }

      // نجمع القديم مع الجديد
      final combined = Uint8List(buffer.length + chunk.length);
      combined.setRange(0, buffer.length, buffer);
      combined.setRange(buffer.length, combined.length, chunk);
      buffer = combined;

      int processLen = 0;
      if (buffer.length > blockSize) {
        processLen = buffer.length - blockSize;
        processLen -= processLen % blockSize;
      }

      if (processLen > 0) {
        final decryptedBuilder = BytesBuilder();
        for (int offset = 0; offset < processLen; offset += blockSize) {
          final outBlock = Uint8List(blockSize);
          cbc.processBlock(buffer, offset, outBlock, 0);
          decryptedBuilder.add(outBlock);
        }

        await handleDecrypted(decryptedBuilder.toBytes());

        buffer = buffer.sublist(processLen);
      }
    }

    if (buffer.isEmpty || buffer.length % blockSize != 0) {
      await outRaf.close();
      throw Exception("طول البيانات غير متوافق مع بلوكات AES.");
    }

    final finalDecryptedBuilder = BytesBuilder();
    for (int offset = 0; offset < buffer.length; offset += blockSize) {
      final outBlock = Uint8List(blockSize);
      cbc.processBlock(buffer, offset, outBlock, 0);
      finalDecryptedBuilder.add(outBlock);
    }

    Uint8List allFinalDecrypted = finalDecryptedBuilder.toBytes();
    if (allFinalDecrypted.isEmpty) {
      await outRaf.close();
      throw Exception("لا توجد بيانات مفكوكة بعد فك التشفير النهائي.");
    }

    int padLen = allFinalDecrypted.last;
    if (padLen > 0 && padLen <= blockSize) {
      bool validPadding = true;
      for (
        int i = allFinalDecrypted.length - padLen;
        i < allFinalDecrypted.length;
        i++
      ) {
        if (allFinalDecrypted[i] != padLen) {
          validPadding = false;
          break;
        }
      }
      if (validPadding) {
        allFinalDecrypted = allFinalDecrypted.sublist(
          0,
          allFinalDecrypted.length - padLen,
        );
      }
    }

    await handleDecrypted(allFinalDecrypted);
    await outRaf.close();

    if (!headerRead) {
      throw Exception("لم يتم العثور على ترويسة بطول 8 بايت بعد فك التشفير");
    }

    // لو فى النهاية مااتكلمناش عن 100%، نضمن آخر تحديث:
    if (onProgress != null && totalSize > 0) {
      onProgress(1.0);
    }

    return AesDecryptResult(courseId: courseId, outputFile: outFile);
  }
}
