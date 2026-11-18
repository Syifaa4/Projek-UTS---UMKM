import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  bool _besar = false;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get besar => _besar;
  double get skalaTeks => _besar ? 1.2 : 1.0;

  Future<void> muat() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getBool('gelap') ?? false) ? ThemeMode.dark : ThemeMode.light;
    _besar = prefs.getBool('besar') ?? false;
    notifyListeners();
  }

  Future<void> setGelap(bool v) async {
    _mode = v ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gelap', v);
  }

  Future<void> setBesar(bool v) async {
    _besar = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('besar', v);
  }
}