import 'package:flutter/material.dart';

import 'package:mypedal_flutter/services/pedal_network.dart';
import 'package:mypedal_flutter/theme/app_theme.dart';

/// Top status pill showing the connection state, with a button to manually
/// disconnect and start searching again.
class StatusOverlay extends StatelessWidget {
  const StatusOverlay({super.key, required this.network});

  final PedalNetwork network;

  @override
  Widget build(BuildContext context) {
    final bool isSearching = network.isSearching;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSearching
                  ? AppColors.searching.withValues(alpha: 0.5)
                  : AppColors.primary.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSearching ? AppColors.searching : AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isSearching
                    ? 'SEARCHING FOR PC...'
                    : 'CONNECTED: ${network.serverIp}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (!isSearching) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: network.resetConnection,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
