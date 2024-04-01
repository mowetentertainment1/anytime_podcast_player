// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:anytime/bloc/discovery/discovery_bloc.dart';
import 'package:anytime/bloc/discovery/discovery_state_event.dart';
import 'package:anytime/bloc/podcast/podcast_bloc.dart';
import 'package:anytime/bloc/settings/settings_bloc.dart';
import 'package:anytime/entities/app_settings.dart';
import 'package:anytime/entities/episode.dart';
import 'package:anytime/entities/podcast.dart';
import 'package:anytime/l10n/L.dart';
import 'package:anytime/state/bloc_state.dart';
import 'package:anytime/ui/library/discovery_results.dart';
import 'package:anytime/ui/podcast/podcast_episode_list.dart';
import 'package:anytime/ui/widgets/platform_progress_indicator.dart';
import 'package:anytime/ui/widgets/podcast_grid_tile.dart';
import 'package:anytime/ui/widgets/podcast_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:anytime/ui/library/common.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../bloc/podcast/episode_bloc.dart';

/// This class is the root class for rendering the Discover tab.
///
/// This UI can optionally show a list of genres provided by iTunes/PodcastIndex.
///
///

// Future<void> main() async {
//   await JustAudioBackground.init(
//     androidNotificationChannelId: 'com.smithandtech.bg_demo.channel.audio',
//     androidNotificationChannelName: 'Audio playback',
//     androidNotificationOngoing: true,
//   );
//   // runApp(const Livemusic());
// }
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
        'https://watch.owncast.online/hls/stream.m3u8'))
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
      ..loadRequest(Uri.parse('https://watch.owncast.online/embed/chat/readwrite'));
    // #enddocregion webview_controller

  }



  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    WakelockPlus.disable();
  }

  @override
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
    final bloc = Provider.of<EpisodeBloc>(context);
    return SliverToBoxAdapter(
      // hasScrollBody: false,
      child: Container(
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
                padding: EdgeInsets.all(0),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 655,
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
