import 'package:flutter/material.dart';

class ActiveHike extends ChangeNotifier {
  int activeHikeId = -1;
  int get getActiveHikeId => activeHikeId;

  void activateHike(int id) {
    activeHikeId = id;
    notifyListeners();
  }

  void deactivateHike() {
    activeHikeId = -1;
    notifyListeners();
  }

  bool isHikeActive(int id) {
    if (activeHikeId == id) {
      return true;
    }
    else {
      return false;
    }
  }
}