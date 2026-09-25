import 'package:flutter/material.dart';
import 'package:idrm_video_app/device_id_helper.dart';
import 'auth_service.dart';
import 'custom_appbar.dart';

class RequestAccessPage extends StatefulWidget {
  const RequestAccessPage({super.key});

  @override
  State<RequestAccessPage> createState() => _RequestAccessPageState();
}

class _RequestAccessPageState extends State<RequestAccessPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController courseCode = TextEditingController();
  final TextEditingController realName = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController userSerial = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceSerial();
  }

  Future<void> _loadDeviceSerial() async {
    final androidInfo = await DeviceIdHelper.getDeviceId();
    userSerial.text = androidInfo; // رقم مميز للجهاز
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final result = await AuthService.sendAccessRequest(
      courseCode: courseCode.text.trim(),
      realName: realName.text.trim(),
      mobile: mobile.text.trim(),
      userSerial: userSerial.text.trim(),
    );

    setState(() => isLoading = false);

    String msg;
    switch (result) {
      case "SUCCESS":
        msg = "تم إرسال الطلب بنجاح ✔";
        break;
      case "ALREADY_EXISTS":
        msg = "تم تسجيل البيانات من قبل";
        break;
      case "INVALID_COURSE":
        msg = "كود الكورس يجب أن يكون رقمًا صحيحًا";
        break;
      case "SERVER_ERROR":
        msg = "مشكلة فى السيرفر";
        break;
      default:
        msg = "حدث خطأ أثناء الإرسال";
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "طلب اشتراك للكورس",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                _buildField(
                  label: "Course Code",
                  controller: courseCode,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "أدخل كود الكورس";
                    }
                    if (int.tryParse(v) == null) {
                      return "كود الكورس يجب أن يكون رقمًا";
                    }
                    return null;
                  },
                ),
                _buildField(
                  label: "Student Name",
                  controller: realName,
                  validator: (v) {
                    if (v == null || v.trim().length <= 5) {
                      return "الاسم يجب أن يكون أكبر من 5 حروف";
                    }
                    return null;
                  },
                ),
                _buildField(
                  label: "Student Mobile",
                  controller: mobile,
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return "رقم الموبايل ١٠ أرقام على الأقل";
                    }
                    if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                      return "الموبايل أرقام فقط";
                    }
                    return null;
                  },
                ),
                _buildField(
                  label: "User Serial",
                  controller: userSerial,
                  readOnly: true,
                  validator: null,
                ),
                const SizedBox(height: 25),
                Center(
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _sendRequest,
                          child: const Text(
                            "Send Request",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            validator: validator,
            readOnly: readOnly,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
