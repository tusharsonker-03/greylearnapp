import 'package:flutter/foundation.dart';

class NotificationCounter with ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void updateCount(int count) {
    _count = count;
    notifyListeners(); // Notifies listeners of changes
  }
  void increment() {
    print(_count.toString());
    _count++;
    notifyListeners(); // Notifies listeners of changes
    print(_count.toString());
  }
}
