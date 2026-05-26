import 'package:flutter/foundation.dart';

class HostTabProvider extends ChangeNotifier {
  int _currentTab = 2; // Default to Home tab as in original code

  int get currentTab => _currentTab;

  void setTab(int index) {
    if (index == _currentTab) return;
    _currentTab = index;
    notifyListeners();
  }

  void resetToHome() => setTab(2);
}
