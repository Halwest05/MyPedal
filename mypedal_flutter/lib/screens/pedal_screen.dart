import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mypedal_flutter/services/pedal_network.dart';
import 'package:mypedal_flutter/widgets/pedal_button.dart';
import 'package:mypedal_flutter/widgets/status_overlay.dart';

/// The app's single screen: a full-screen pedal with status overlays.
class PedalScreen extends StatelessWidget {
  const PedalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PedalNetwork network = context.watch<PedalNetwork>();

    return Scaffold(
      body: Stack(
        children: [
          PedalButton(network: network),
          StatusOverlay(network: network),

          // Bottom hint.
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                network.isSearching
                    ? 'START THE PYTHON SERVER ON YOUR PC'
                    : 'HOLD SCREEN TO SUSTAIN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
