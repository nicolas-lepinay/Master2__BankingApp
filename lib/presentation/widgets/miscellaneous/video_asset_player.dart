import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoAssetPlayer extends StatefulWidget {
  final String videoPath;
  final Widget loadingWidget;

  const VideoAssetPlayer({
    super.key,
    required this.videoPath,
    required this.loadingWidget,
  });

  @override
  State<VideoAssetPlayer> createState() => _VideoAssetPlayerState();
}

class _VideoAssetPlayerState extends State<VideoAssetPlayer>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..setLooping(true)
      ..setVolume(0);
    _init = _controller.initialize().then((_) => _controller.play());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      _controller.pause();
    } else if (s == AppLifecycleState.resumed &&
        _controller.value.isInitialized) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: widget.loadingWidget,
          );
        }
        return AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        );
      },
    );
  }
}
