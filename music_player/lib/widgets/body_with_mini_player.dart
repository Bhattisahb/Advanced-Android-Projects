import 'package:flutter/material.dart';

import 'mini_player_bar.dart';

/// Wraps screen content with the shared bottom mini player (Home/Library use
/// [AppShell]; pushed routes like playlist detail should use this).
class BodyWithMiniPlayer extends StatelessWidget {
  final Widget child;

  const BodyWithMiniPlayer({super.key, required this.child});

  static const double miniPlayerHeight = 66;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const MiniPlayerBar(),
      ],
    );
  }
}
