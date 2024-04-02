// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// This class is the root class for rendering the Discover tab.
///
/// This UI can optionally show a list of genres provided by iTunes/PodcastIndex.
///
///
class Livevideo extends StatefulWidget {
  const Livevideo({super.key});

  @override
  State<StatefulWidget> createState() => _LivevideoState();
}

class _LivevideoState extends State<Livevideo> {
  late final WebViewController controller;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _controller = VideoPlayerController.networkUrl(Uri.parse(
        'https://live.mowetent.com/hls/stream.m3u8'))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
     _controller.play();
    // #docregion webview_controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://cloud.smithandtech.com/index.php/call/nkb8epbw'));
    // #enddocregion webview_controller

  }



  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    WakelockPlus.disable();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      _controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    // final bloc = Provider.of<EpisodeBloc>(context);
    return SliverToBoxAdapter(
      // hasScrollBody: false,
      child: SizedBox(
        height: 950,
        width: double.maxFinite,
        child: Scaffold(
          body: Column(

            children: [
              Center(
                // width: double.maxFinite,
                child: _controller.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
                    : Container()
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue, // foreground
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(0),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 600,
                  child: WebViewWidget(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
