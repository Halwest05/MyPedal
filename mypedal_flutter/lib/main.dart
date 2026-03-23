import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyPedalApp());
}

class MyPedalApp extends StatelessWidget {
  const MyPedalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pedal',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFCC),
          secondary: Color(0xFF00BFFF),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const PedalScreen(),
    );
  }
}

class PedalScreen extends StatefulWidget {
  const PedalScreen({Key? key}) : super(key: key);

  @override
  _PedalScreenState createState() => _PedalScreenState();
}

class _PedalScreenState extends State<PedalScreen>
    with SingleTickerProviderStateMixin {
  RawDatagramSocket? _cmdSocket;
  RawDatagramSocket? _discoverySocket;

  String? _serverIp;
  bool _isPressed = false;
  bool _isSearching = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initSockets();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
  }

  Future<void> _initSockets() async {
    try {
      // 1. Socket for sending pedal commands
      _cmdSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      // 2. Socket exclusively for listening to the PC's broadcast
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        8003,
      );

      _discoverySocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _discoverySocket!.receive();
          if (dg != null) {
            String message = String.fromCharCodes(dg.data);

            if (message == "PEDAL_SERVER_HERE" && _serverIp == null) {
              if (mounted) {
                setState(() {
                  _serverIp = dg.address.address;
                  _isSearching = false;
                });
              }
              HapticFeedback.heavyImpact();

              // Close the discovery listener to save battery now that we are connected
              _discoverySocket?.close();
              _discoverySocket = null;
            }
          }
        }
      });
    } catch (_) {
      // Silently ignore init errors
    }
  }

  void _resetConnection() {
    setState(() {
      _serverIp = null;
      _isSearching = true;
    });
    // Re-initialize sockets to start listening again
    _initSockets();
    HapticFeedback.lightImpact();
  }

  void _sendAction(String action) {
    if (_serverIp != null && _cmdSocket != null) {
      try {
        _cmdSocket!.send(action.codeUnits, InternetAddress(_serverIp!), 8002);
      } catch (_) {
        // Silently ignore send errors to keep UI smooth
      }
    }
  }

  void _onPointerDown(PointerDownEvent details) {
    if (_serverIp == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _animationController.forward();
    _sendAction("d");
  }

  void _onPointerUp(PointerUpEvent details) {
    if (_serverIp == null) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
    _sendAction("u");
  }

  void _onPointerCancel(PointerCancelEvent details) {
    if (_serverIp == null) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
    _sendAction("u");
  }

  @override
  void dispose() {
    _cmdSocket?.close();
    _discoverySocket?.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FULL SCREEN PEDAL BUTTON
          Positioned.fill(
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
                            ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
                            : [
                                const Color(0xFF2C2C2C),
                                const Color(0xFF121212),
                              ],
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
                              color: const Color(
                                0xFF00FFCC,
                              ).withOpacity(_glowAnimation.value * 0.5 + 0.05),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00FFCC,
                                ).withOpacity(_glowAnimation.value * 0.2),
                                blurRadius: 40,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Visual "Pedal" grooves
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  8,
                                  (index) => Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.02),
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_isSearching)
                                const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange,
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
          ),

          // STATUS OVERLAY
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isSearching
                        ? Colors.orange.withOpacity(0.5)
                        : const Color(0xFF00FFCC).withOpacity(0.5),
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
                        color: _isSearching
                            ? Colors.orange
                            : const Color(0xFF00FFCC),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSearching
                          ? 'SEARCHING FOR PC...'
                          : 'CONNECTED: $_serverIp',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Keep the ability to manually disconnect/reset by tapping the X
                    if (!_isSearching) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _resetConnection,
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
          ),

          // BOTTOM HINT
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isSearching
                    ? 'START THE PYTHON SERVER ON YOUR PC'
                    : 'HOLD SCREEN TO SUSTAIN',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
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
