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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:anytime/ui/library/common.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../bloc/podcast/episode_bloc.dart';

/// This class is the root class for rendering the Discover tab.
///
/// This UI can optionally show a list of genres provided by iTunes/PodcastIndex.
///
///


Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.smithandtech.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
}
class Livemusic extends StatefulWidget {
  const Livemusic({super.key});

  @override
  State<StatefulWidget> createState() => _LivemusicState();
}

final staticAnchorKey = GlobalKey();

class _LivemusicState extends State<Livemusic> with WidgetsBindingObserver {
  late final WebViewController controller;

  late AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = AudioPlayer();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();

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

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
          print('A stream error occurred: $e');
        });
    // Try to load audio from a source and catch any errors.
    try {
      await _player.setAudioSource(AudioSource.uri(
          Uri.parse("https://mopod-2.s3.us-east-2.amazonaws.com/Smooth+Operator.mp3")));
    } catch (e) {
      print("Error loading audio source: $e");
    }
    _player.play();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    _player.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
              (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      //  _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<EpisodeBloc>(context);
        return SliverFillRemaining(
          hasScrollBody: false,
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StreamBuilder<IcyMetadata?>(
                  stream: _player.icyMetadataStream,
                  builder: (context, snapshot) {
                    final metadata = snapshot.data;
                    final title = metadata?.info?.title ?? '';
                    final url = metadata?.info?.url;
                    return Column(
                      children: [
                        if (url != null) Image.network(url),
                        CachedNetworkImage(
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 140.0,
                          imageUrl: "https://mopod-2.s3.us-east-2.amazonaws.com/413OXatc0UL._UXNaN_FMjpg_QL85_.jpg",
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(0),
                          child: Text(title,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ],
                    );
                  },
                ),
                // Display play/pause button and volume/speed sliders.
                ControlButtons(_player),
                Padding(
                  padding: EdgeInsets.all(0),
                  child: Container(
                    padding: EdgeInsets.all(0),
                    width: double.infinity,
                    height: 760,
                    child: WebViewWidget(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        );
      }
}

/// Displays the play/pause button and volume/speed sliders.
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                color: Colors.blue,
                icon: const Icon(Icons.play_arrow),
                iconSize: 44.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                color: Colors.blue,
                icon: const Icon(Icons.pause),
                iconSize: 44.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                color: Colors.blue,
                icon: const Icon(Icons.replay),
                iconSize: 44.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
      ],
    );
  }
}