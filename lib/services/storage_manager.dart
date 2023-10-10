import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  static void saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is List<String>) {
      prefs.setStringList(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    } else if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else {
      print("Invalid Type");
    }
  }

  static void removeData(String key) async{
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  static Future<dynamic> readDataList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    dynamic obj = prefs.get(key);
    if (obj == null && (key == "userId" || key == "sessionId")){
      obj = UniqueKey().toString().replaceAll(RegExp(r'\#|\[|\]'), '');
      saveData(key, obj);
    }
    return obj;
  }
}