// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:anytime/ui/anytime_podcast_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:anytime/ui/library/common.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      cacheEnabled: true,
      hardwareAcceleration: true,
      javaScriptEnabled: true,
      safeBrowsingEnabled: true,
      verticalScrollBarEnabled: true,
      verticalScrollbarThumbColor: theme.primaryColor,
      verticalScrollbarTrackColor: theme.primaryColor,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);


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

  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
          // print('A stream error occurred: $e');
        });
    // Try to load audio from a source and catch any errors.
    try {
      await _player.setAudioSource(AudioSource.uri(
          Uri.parse("https://radio.mowetent.com/live")));
    } catch (e) {
      // print("Error loading audio source: $e");
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
       _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
        return SliverToBoxAdapter(
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
                        // CachedNetworkImage(
                        //   fit: BoxFit.cover,
                        //   width: double.infinity,
                        //   height: 140.0,
                        //   imageUrl: "https://mopod-2.s3.us-east-2.amazonaws.com/413OXatc0UL._UXNaN_FMjpg_QL85_.jpg",
                        //   placeholder: (context, url) => const CircularProgressIndicator(),
                        //   errorWidget: (context, url, error) => const Icon(Icons.error),
                        // ),
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
                  padding: const EdgeInsets.all(0),
                  child: Container(
                    padding: const EdgeInsets.all(0),
                    width: double.infinity,
                    height: 760,
                    child: InAppWebView(
                      // webViewEnvironment: webViewEnvironment,
                      initialUrlRequest:
                      URLRequest(url: WebUri('https://cloud.smithandtech.com/index.php/call/nkb8epbw')),
                      initialUserScripts: UnmodifiableListView<UserScript>([]),
                      initialSettings: settings,

                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                            resources: request.resources,
                            action: PermissionResponseAction.GRANT);
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          if (await canLaunchUrl(uri)) {
                            // Launch the App
                            await launchUrl(
                              uri,
                            );
                            // and cancel the request
                            return NavigationActionPolicy.CANCEL;
                          }
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        // pullToRefreshController?.endRefreshing();
                        // setState(() {
                        //   this.url = url.toString();
                        //   urlController.text = this.url;
                        // });
                      },
                      onReceivedError: (controller, request, error) {
                        // pullToRefreshController?.endRefreshing();
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          // pullToRefreshController?.endRefreshing();
                        }
                        // setState(() {
                        //   this.progress = progress / 100;
                        //   urlController.text = this.url;
                        // });
                      },
                      // onUpdateVisitedHistory: (controller, url, isReload) {
                      //   setState(() {
                      //     this.url = url.toString();
                      //     urlController.text = this.url;
                      //   });
                      // },
                      onConsoleMessage: (controller, consoleMessage) {
                        print(consoleMessage);
                      },
                    ),
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

  const ControlButtons(this.player, {super.key});

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
                color: theme.primaryColor,
                icon: const Icon(Icons.play_arrow),
                iconSize: 44.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                color: theme.primaryColor,
                icon: const Icon(Icons.pause),
                iconSize: 44.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                color: theme.primaryColor,
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