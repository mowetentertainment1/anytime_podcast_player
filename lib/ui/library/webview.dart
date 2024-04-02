// Copyright 2020 Ben Hills and the project contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/material.dart';
import 'package:anytime/ui/library/common.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// This class is the root class for rendering the Discover tab.
///
/// This UI can optionally show a list of genres provided by iTunes/PodcastIndex.
///
///


class Webview extends StatefulWidget {
  const Webview({super.key});

  @override
  State<StatefulWidget> createState() => _WebviewState();
}

final staticAnchorKey = GlobalKey();

class _WebviewState extends State<Webview> with WidgetsBindingObserver {

  late final WebViewController controller;
  // late AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // _player = AudioPlayer();
    // ambiguate(WidgetsBinding.instance)!.addObserver(this);
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black,
    // ));
    // _init();

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
      ..loadRequest(Uri.parse('https://mowetent.com'));
    // #enddocregion webview_controller
  }


  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
  }

  @override
  Widget build(BuildContext context) {
    // final bloc = Provider.of<EpisodeBloc>(context);
        return SliverFillRemaining(
          hasScrollBody: true,
          child: WebViewWidget(controller: controller),
        );
      }
}

/// Displays the play/pause button and volume/speed sliders.
// class ControlButtons extends StatelessWidget {
//   final AudioPlayer player;
//
//   const ControlButtons(this.player, {Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         /// This StreamBuilder rebuilds whenever the player state changes, which
//         /// includes the playing/paused state and also the
//         /// loading/buffering/ready state. Depending on the state we show the
//         /// appropriate button or loading indicator.
//         StreamBuilder<PlayerState>(
//           stream: player.playerStateStream,
//           builder: (context, snapshot) {
//             final playerState = snapshot.data;
//             final processingState = playerState?.processingState;
//             final playing = playerState?.playing;
//             if (processingState == ProcessingState.loading ||
//                 processingState == ProcessingState.buffering) {
//               return Container(
//                 margin: const EdgeInsets.all(8.0),
//                 width: 64.0,
//                 height: 64.0,
//                 child: const CircularProgressIndicator(),
//               );
//             } else if (playing != true) {
//               return IconButton(
//                 icon: const Icon(Icons.play_arrow),
//                 iconSize: 64.0,
//                 onPressed: player.play,
//               );
//             } else if (processingState != ProcessingState.completed) {
//               return IconButton(
//                 icon: const Icon(Icons.pause),
//                 iconSize: 64.0,
//                 onPressed: player.pause,
//               );
//             } else {
//               return IconButton(
//                 icon: const Icon(Icons.replay),
//                 iconSize: 64.0,
//                 onPressed: () => player.seek(Duration.zero),
//               );
//             }
//           },
//         ),
//       ],
//     );
//   }
// }