import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mypedal_flutter/constants.dart';
import 'package:mypedal_flutter/services/pedal_network.dart';
import 'package:mypedal_flutter/theme/app_theme.dart';

/// The full-screen pedal button: press-and-hold to sustain, with scale and
/// glow animations plus haptic feedback.
class PedalButton extends StatefulWidget {
  const PedalButton({super.key, required this.network});

  final PedalNetwork network;

  @override
  State<PedalButton> createState() => _PedalButtonState();
}

class _PedalButtonState extends State<PedalButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  /// Tracks which pointers are currently touching the pedal.
  /// Ensures we send exactly one "d" on first touch and one "u" when
  /// all fingers lift — even if multiple fingers are placed on the screen.
  final Set<int> _activePointers = <int>{};

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuad,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent details) {
    if (!widget.network.isConnected) return;

    final bool wasIdle = _activePointers.isEmpty;
    _activePointers.add(details.pointer);

    if (!wasIdle) return; // Another finger is already down — ignore.

    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _animationController.forward();
    widget.network.sendAction(NetworkConfig.commandDown);
  }

  void _onPointerUp(PointerUpEvent details) {
    _activePointers.remove(details.pointer);
    if (_activePointers.isNotEmpty || !_isPressed) return; // Still held by other fingers.

    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.network.sendAction(NetworkConfig.commandUp);
  }

  void _onPointerCancel(PointerCancelEvent details) {
    _activePointers.remove(details.pointer);
    if (_activePointers.isNotEmpty || !_isPressed) return;

    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.network.sendAction(NetworkConfig.commandUp);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = widget.network.isSearching;

    return Positioned.fill(
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPressed
                      ? [
                          AppColors.pedalPressedTop,
                          AppColors.pedalPressedBottom,
                        ]
                      : [AppColors.pedalTop, AppColors.pedalBottom],
                ),
              ),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: _glowAnimation.value * 0.5 + 0.05,
                        ),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: _glowAnimation.value * 0.2,
                          ),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Visual "pedal" grooves.
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            8,
                            (index) => Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isSearching)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.searching,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
