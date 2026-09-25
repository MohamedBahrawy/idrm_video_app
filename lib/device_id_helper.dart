import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdHelper {
  static const _key = 'device_unique_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Uuid _uuid = Uuid();

  // دي الفانكشن اللي هتنده عليها من أي حتة
  static Future<String> getDeviceId() async {
    // 1) نحاول نقرأ ID قديم
    final existingId = await _storage.read(key: _key);

    if (existingId != null && existingId.isNotEmpty) {
      // لو موجود → نرجعه زي ما هو
      return existingId;
    }

    // 2) أول مرة → نولد UUID جديد
    final newId = _uuid.v4();

    // 3) نخزنه عشان يفضل ثابت بعد كده
    await _storage.write(key: _key, value: newId);

    return newId;
  }
}
