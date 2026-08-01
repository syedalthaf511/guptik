import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that broadcasts switch commands to ESP devices via
/// Supabase Realtime websocket channel `realtime:switches-esp`.
///
/// Flow:  Flutter App → WebSocket Broadcast → Node.js Server → Supabase DB
///        ESP ← WebSocket Broadcast ← Node.js Server
class HcWebSocketService {
  static final HcWebSocketService _instance = HcWebSocketService._();
  factory HcWebSocketService() => _instance;
  HcWebSocketService._();

  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  bool _isSubscribed = false;

  /// Subscribe to the `realtime:switches-esp` broadcast channel.
  /// Call once at app startup (e.g. in main or HomeScreen init).
  Future<void> initialize() async {
    if (_isSubscribed) return;

    _channel = _client.channel('switches-esp');

    await _channel!.subscribe();
    _isSubscribed = true;
  }

  /// Send a remote command to toggle a switch on the ESP board.
  ///
  /// [boardId]  — the board's ID (e.g. "CL-202650S4-516300a5")
  /// [position] — switch position (1-4)
  /// [state]    — true = ON, false = OFF
  Future<void> toggleSwitch({
    required String boardId,
    required int position,
    required bool state,
  }) async {
    if (!_isSubscribed || _channel == null) {
      await initialize();
    }

    final switchKey = 'switch$position';
    await _channel!.sendBroadcastMessage(
      event: 'remote_command',
      payload: {'board_id': boardId, switchKey: state},
    );
  }

  /// Dispose the channel when no longer needed.
  void dispose() {
    _channel?.unsubscribe();
    _channel = null;
    _isSubscribed = false;
  }
}
