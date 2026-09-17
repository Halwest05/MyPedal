import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:mypedal_flutter/constants.dart';

/// Handles all UDP communication with the PC pedal server.
///
/// Exposes the connection state so the UI can react to discovery changes.
/// Also watches the app lifecycle: when the app returns from the background,
/// a stale connection is dropped and a fresh discovery cycle is started.
class PedalNetwork extends ChangeNotifier with WidgetsBindingObserver {
  PedalNetwork() {
    WidgetsBinding.instance.addObserver(this);
    initSockets();
  }

  RawDatagramSocket? _cmdSocket;
  RawDatagramSocket? _discoverySocket;

  String? _serverIp;
  bool _isSearching = true;

  /// The IP address of the discovered server, or null while searching.
  String? get serverIp => _serverIp;

  /// Whether the app is still looking for a server.
  bool get isSearching => _isSearching;

  /// Whether a server has been discovered.
  bool get isConnected => _serverIp != null;

  /// Opens the command socket (if not already open) and starts listening
  /// for the server discovery broadcast.
  Future<void> initSockets() async {
    // Defensive cleanup in case we are re-initializing after a reset.
    _discoverySocket?.close();
    _discoverySocket = null;

    try {
      _cmdSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (error) {
      debugPrint('PedalNetwork: failed to open command socket: $error');
    }

    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        NetworkConfig.discoveryPort,
      );
    } catch (error) {
      debugPrint('PedalNetwork: failed to open discovery socket: $error');
      return;
    }

    _discoverySocket!.listen(
      _onDiscoveryEvent,
      onError: (Object error) {
        debugPrint('PedalNetwork: discovery socket error: $error');
      },
    );
  }

  void _onDiscoveryEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    final Datagram? datagram = _discoverySocket?.receive();
    if (datagram == null) return;

    final String message = String.fromCharCodes(datagram.data);
    if (message != NetworkConfig.discoveryMessage || _serverIp != null) {
      return;
    }

    _serverIp = datagram.address.address;
    _isSearching = false;

    // Close the discovery listener to save battery now that we are connected.
    _discoverySocket?.close();
    _discoverySocket = null;

    debugPrint('PedalNetwork: connected to server at $_serverIp');
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  /// Drops the current connection and starts searching again.
  void resetConnection() {
    _serverIp = null;
    _isSearching = true;
    notifyListeners();

    debugPrint('PedalNetwork: connection reset, searching for server...');
    HapticFeedback.lightImpact();
    initSockets();
  }

  /// Sends a single-character pedal action ("d" or "u") to the server.
  void sendAction(String action) {
    final String? ip = _serverIp;
    final RawDatagramSocket? socket = _cmdSocket;
    if (ip == null || socket == null) return;

    try {
      socket.send(
        action.codeUnits,
        InternetAddress(ip),
        NetworkConfig.commandPort,
      );
    } catch (error) {
      debugPrint('PedalNetwork: failed to send "$action": $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // After returning from the background the old connection may be stale,
    // so start a fresh discovery cycle.
    if (state == AppLifecycleState.resumed && isConnected) {
      resetConnection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cmdSocket?.close();
    _discoverySocket?.close();
    super.dispose();
  }
}
