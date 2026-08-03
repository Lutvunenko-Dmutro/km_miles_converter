import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversion_history.dart';

class StorageService {
  static const String _historyKey = 'conversion_history';

  Future<void> saveHistory(List<ConversionHistory> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = jsonEncode(
        history.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_historyKey, encodedData);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<List<ConversionHistory>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedData = prefs.getString(_historyKey);
      
      if (encodedData != null) {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        return decodedData
            .map((item) => ConversionHistory.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
    return [];
  }
}
