import 'package:flutter/material.dart';

class CurrentPage extends ChangeNotifier {
  int pageIndex = 0;
  int get getIndex => pageIndex;

  void setPage(int pageNum) {
    pageIndex = pageNum;
    notifyListeners();
  }
}