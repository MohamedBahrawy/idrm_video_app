import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:video_player/video_player.dart';

import 'auth_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final File videoFile;
  final String courseId;

  const VideoPlayerPage({
    super.key,
    required this.videoFile,
    required this.courseId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;

  bool _showControls = true;
  bool _isScrubbing = false;
  Duration _current = Duration.zero;
  Duration _total = Duration.zero;

  // ✅ Android Audio Capture channel
  static const MethodChannel _audioChannel = MethodChannel('audio_capture');

  Future<void> _disableAudioCapture() async {
    try {
      await _audioChannel.invokeMethod('disableAudioCapture');
    } catch (_) {}
  }

  Future<void> _enableAudioCaptureBack() async {
    try {
      await _audioChannel.invokeMethod('enableAudioCapture');
    } catch (_) {}
  }

  // ===== Overlay بيانات الطالب =====
  String? _contactRaw; // "Name|Mobile"
  bool _showContact = false;

  Timer? _periodicTimer;
  Timer? _hideTimer;

  final _rand = Random();

  // أماكن جاهزة للتنقل
  final List<Alignment> _positions = const [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ];

  Alignment _currentPos = Alignment.topRight; // البداية

  @override
  void initState() {
    super.initState();

    // حماية التسجيل/السكرين شوت
    ScreenProtector.preventScreenshotOn();
    ScreenProtector.protectDataLeakageOn();
    _disableAudioCapture();

    // Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VideoPlayerController.file(widget.videoFile)
      ..addListener(() {
        if (_isScrubbing) return;
        if (!mounted) return;

        setState(() {
          _current = _controller.value.position;
          _total = _controller.value.duration;
        });
      })
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _total = _controller.value.duration);
        _controller.play();
      });

    _startContactOverlayLoop();
  }

  Future<void> _startContactOverlayLoop() async {
    // أول مرة
    await _refreshContact();
    _showContactForSeconds(5);

    // كل 20 ثانية
    _periodicTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await _refreshContact();
      _showContactForSeconds(5);
    });
  }

  Future<void> _refreshContact() async {
    try {
      final deviceSerial = await AuthService.getDeviceSerial();
      final raw = await AuthService.getContactByCourse(
        deviceSerial: deviceSerial,
        courseId: widget.courseId,
      );

      if (!mounted) return;
      setState(() => _contactRaw = raw);
    } catch (_) {}
  }

  void _showContactForSeconds(int seconds) {
    _hideTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _showContact = true;
      // ✅ غيّر المكان مرة واحدة عند الظهور فقط
      _currentPos = _positions[_rand.nextInt(_positions.length)];
    });

    _hideTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      setState(() => _showContact = false);
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _hideTimer?.cancel();

    _controller.dispose();
    _enableAudioCaptureBack();

    ScreenProtector.preventScreenshotOff();
    ScreenProtector.protectDataLeakageOff();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    final contactText = (_contactRaw == null || _contactRaw!.trim().isEmpty)
        ? ""
        : _contactRaw!.trim();

    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),

                  // ✅ Overlay الاسم|الموبايل (يتنقل كل ظهور)
                  if (_showContact && contactText.isNotEmpty)
                    Align(
                      alignment: _currentPos,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            contactText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ✅ الكنترولز
                  if (_showControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        color: Colors.black54,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Slider(
                              value: _current.inSeconds.toDouble(),
                              min: 0,
                              max: (_total.inSeconds == 0)
                                  ? 1
                                  : _total.inSeconds.toDouble(),
                              activeColor: Colors.red,
                              inactiveColor: Colors.white30,
                              onChangeStart: (_) =>
                                  setState(() => _isScrubbing = true),
                              onChanged: (value) => setState(() {
                                _current = Duration(seconds: value.toInt());
                              }),
                              onChangeEnd: (value) {
                                _controller.seekTo(
                                  Duration(seconds: value.toInt()),
                                );
                                setState(() => _isScrubbing = false);
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTime(_current),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  formatTime(_total),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 40,
                                  color: Colors.white,
                                  icon: const Icon(Icons.replay_10),
                                  onPressed: () {
                                    final pos =
                                        _controller.value.position -
                                        const Duration(seconds: 10);
                                    _controller.seekTo(
                                      pos < Duration.zero ? Duration.zero : pos,
                                    );
                                  },
                                ),
                                IconButton(
                                  iconSize: 55,
                                  color: Colors.white,
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying
                                          ? _controller.pause()
                                          : _controller.play();
                                    });
                                  },
                                ),
                                IconButton(
                                  iconSize: 40,
                                  color: Colors.white,
                                  icon: const Icon(Icons.forward_10),
                                  onPressed: () {
                                    final pos =
                                        _controller.value.position +
                                        const Duration(seconds: 10);
                                    _controller.seekTo(pos);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
