
/// Centralized configuration for the MyPedal UDP protocol.
///
/// Keep these values in sync with the Python server running on the PC.
class NetworkConfig {
  NetworkConfig._();

  /// UDP port the phone listens on for server discovery broadcasts.
  static const int discoveryPort = 8003;

  /// UDP port the PC server receives pedal commands on.
  static const int commandPort = 8002;

  /// Message the PC server broadcasts to announce itself.
  static const String discoveryMessage = 'PEDAL_SERVER_HERE';

  /// Payload sent while the pedal is held down.
  static const String commandDown = 'd';

  /// Payload sent when the pedal is released.
  static const String commandUp = 'u';
}
