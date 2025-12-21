import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LessonVideoScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const LessonVideoScreen({super.key, required this.lesson});

  @override
  State<LessonVideoScreen> createState() => _LessonVideoScreenState();
}

class _LessonVideoScreenState extends State<LessonVideoScreen> {
  VideoPlayerController? _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final videoUrl = widget.lesson['videoUrl'];

    if (videoUrl == null || videoUrl.toString().isEmpty) {
      _isError = true;
      return;
    }

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    )
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller!.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _isError = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson['titre'] ?? 'Vidéo'),
      ),
      body: Center(
        child: _isError
            ? const Text(
                '❌ Impossible de lire la vidéo',
                style: TextStyle(color: Colors.red),
              )
            : _controller == null || !_controller!.value.isInitialized
                ? const CircularProgressIndicator()
                : AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
      ),

      // ▶️ PLAY / PAUSE
      floatingActionButton: _controller != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
