import 'package:flutter/material.dart';

class UserStateProvider with ChangeNotifier {
  bool loginState = false;

  void changeLogin(bool state) {
    loginState = state;
    notifyListeners();
  }
}