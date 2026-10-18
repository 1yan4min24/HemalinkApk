import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal (di perangkat). Ganti dengan API/Firebase bila sudah ada backend.
class StorageService {
  StorageService(this._prefs);
  final SharedPreferences _prefs;

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
