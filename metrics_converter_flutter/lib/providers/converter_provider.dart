import 'package:flutter/material.dart';
import '../models/conversion_history.dart';
import '../services/conversion_service.dart';
import '../services/storage_service.dart';

class ConverterProvider extends ChangeNotifier {
  final ConversionService _conversionService;
  final StorageService _storageService;

  late String _selectedConversion;
  String _output = '';
  List<ConversionHistory> _history = [];
  bool _isLoading = true;

  ConverterProvider({
    ConversionService? conversionService,
    StorageService? storageService,
  })  : _conversionService = conversionService ?? ConversionService(),
        _storageService = storageService ?? StorageService() {
    _selectedConversion = _conversionService.getConversionTypes().first;
    _loadHistory();
  }

  String get selectedConversion => _selectedConversion;
  String get output => _output;
  List<ConversionHistory> get history => _history;
  bool get isLoading => _isLoading;

  List<String> get conversionTypes => _conversionService.getConversionTypes();

  void setSelectedConversion(String value) {
    _selectedConversion = value;
    _output = '';
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _storageService.loadHistory();
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void convert(double value) {
    double result = _conversionService.convert(_selectedConversion, value);
    _output = _formatResult(result);
    _addToHistory(_selectedConversion, value, result);
    notifyListeners();
  }

  void _addToHistory(String type, double input, double output) {
    final historyItem = ConversionHistory(type, input, output);
    _history.insert(0, historyItem);
    _storageService.saveHistory(_history);
    // UI can listen to changes and animate the list insertion
  }

  String _formatResult(double value) {
    String formatted = value.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    return formatted;
  }
}
