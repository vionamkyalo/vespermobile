import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/sync_service.dart';
import '../../auth/viewmodel/sign_in_view_model.dart';
import '../models/user_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this._session,
    OfflineQueueRepository? queue,
    Stream<SyncEvent>? syncEvents,
  }) : _queue = queue ?? OfflineQueueRepository() {
    _session.addListener(_onSessionChanged);
    _syncSubscription = syncEvents?.listen((_) => refreshWaiting());
    unawaited(refreshWaiting());
  }

  final SignInViewModel _session;
  final OfflineQueueRepository _queue;
  StreamSubscription<SyncEvent>? _syncSubscription;

  int _waitingCount = 0;
  bool _disposed = false;

  UserProfile? get user {
    final signedIn = _session.user;
    return signedIn == null ? null : UserProfile.fromUser(signedIn);
  }

  int get waitingCount => _waitingCount;

  String get waitingSummary => switch (_waitingCount) {
    0 => 'Nothing waiting',
    1 => '1 report waiting',
    _ => '$_waitingCount reports waiting',
  };
  Future<void> refreshWaiting() async {
    try {
      final count = await _queue.waitingCount();
      if (_disposed || count == _waitingCount) return;
      _waitingCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Could not count waiting reports: $e');
    }
  }

  Future<void> signOut() => _session.logout();

  void manageLocation() => unawaited(_openLocationSettings());

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Could not open location settings: $e');
    }
  }

  void _onSessionChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    _syncSubscription?.cancel();
    super.dispose();
  }
}
