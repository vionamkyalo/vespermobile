import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    UserProfile? user = UserProfile.placeholder,
    int waitingCount = 3,
    String? lastTry = '04:34',
  }) : _user = user,
       _waitingCount = waitingCount,
       _lastTry = lastTry;

  UserProfile? _user;
  int _waitingCount;
  String? _lastTry;

  UserProfile? get user => _user;
  int get waitingCount => _waitingCount;

  String get waitingSummary {
    if (_waitingCount == 0) return 'Nothing waiting';
    final lastTry = _lastTry;
    return lastTry == null
        ? '$_waitingCount waiting'
        : '$_waitingCount waiting, Last try $lastTry';
  }

  void setUser(UserProfile? user) {
    _user = user;
    notifyListeners();
  }

  void setWaiting({required int count, String? lastTry}) {
    _waitingCount = count;
    _lastTry = lastTry;
    notifyListeners();
  }

  Future<void> signOut() async {}
  void manageLocation() {}
  void openWaitingReports() {}
}
