import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';

enum ConnectionChange { wentOffline, backOnline }

class ConnectionEvent {
  const ConnectionEvent.wentOffline()
    : change = ConnectionChange.wentOffline,
      sent = 0,
      rejected = 0,
      serverUnreachable = false;

  const ConnectionEvent.backOnline({
    required this.sent,
    required this.rejected,
    required this.serverUnreachable,
  }) : change = ConnectionChange.backOnline;

  final ConnectionChange change;
  final int sent;
  final int rejected;
  final bool serverUnreachable;
}

class ConnectionMonitor {
  ConnectionMonitor({
    required Future<SyncResult> Function() syncNow,
    Stream<List<ConnectivityResult>>? changes,
    Future<List<ConnectivityResult>> Function()? currentStatus,
    this.retryDelay = const Duration(seconds: 5),
    this.maxRetries = 3,
  }) : _syncNow = syncNow,
       _changes = changes,
       _currentStatus = currentStatus;

  final Future<SyncResult> Function() _syncNow;
  final Stream<List<ConnectivityResult>>? _changes;
  final Future<List<ConnectivityResult>> Function()? _currentStatus;

  final Duration retryDelay;
  final int maxRetries;

  final _events = StreamController<ConnectionEvent>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;
  int _generation = 0;

  Stream<ConnectionEvent> get events => _events.stream;
  bool get isOffline => !_online;

  Future<void> start() async {
    if (_subscription != null) return;

    final current = _currentStatus ?? () => Connectivity().checkConnectivity();
    _online = _hasConnection(await current());

    _subscription = (_changes ?? Connectivity().onConnectivityChanged).listen(
      _onChange,
    );
  }

  void _onChange(List<ConnectivityResult> results) {
    final online = _hasConnection(results);
    if (online == _online) return;

    _online = online;
    final generation = ++_generation;

    if (!online) {
      _emit(const ConnectionEvent.wentOffline());
      return;
    }
    unawaited(_handleBackOnline(generation));
  }

  Future<void> _handleBackOnline(int generation) async {
    var sent = 0;
    var attempt = 0;

    while (true) {
      final result = await _syncNow();
      if (generation != _generation) return;

      sent += result.sent;
      final rejected = result.offline
          ? (result.failed > 0 ? result.failed - 1 : 0)
          : result.failed;

      if (!result.offline || attempt >= maxRetries) {
        _emit(
          ConnectionEvent.backOnline(
            sent: sent,
            rejected: rejected,
            serverUnreachable: result.offline,
          ),
        );
        return;
      }

      attempt++;
      await Future<void>.delayed(retryDelay);
      if (generation != _generation) return;
    }
  }

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  void _emit(ConnectionEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _events.close();
  }
}
