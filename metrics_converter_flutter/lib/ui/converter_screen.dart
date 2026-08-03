import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/conversion_history.dart';
import '../services/conversion_service.dart';
import '../services/storage_service.dart';

class Converter extends StatefulWidget {
  final bool isDarkMode;
  final Function toggleTheme;
  // DI (Dependency Injection) для легкого тестування
  final ConversionService conversionService;
  final StorageService storageService;

  Converter({
    super.key, 
    required this.isDarkMode, 
    required this.toggleTheme,
    ConversionService? conversionService,
    StorageService? storageService,
  })  : conversionService = conversionService ?? ConversionService(),
        storageService = storageService ?? StorageService();

  @override
  _ConverterState createState() => _ConverterState();
}

class _ConverterState extends State<Converter> with SingleTickerProviderStateMixin {
  late String _selectedConversion;
  String _output = '';
  AnimationController? _controller;
  Animation<double>? _animation;

  // Контролер для поля вводу (краще для продуктивності)
  final TextEditingController _inputController = TextEditingController();

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ConversionHistory> _history = [];
  bool _isLoading = true; // Стан завантаження для AnimatedList

  @override
  void initState() {
    super.initState();
    _selectedConversion = widget.conversionService.getConversionTypes().first;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await widget.storageService.loadHistory();
      
      if (!mounted) return;

      setState(() {
        _history = history;
        _isLoading = false; // Дані завантажено, можна малювати список
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addToHistory(String conversionType, double inputValue, double outputValue) {
    final historyItem = ConversionHistory(conversionType, inputValue, outputValue);
    _history.insert(0, historyItem);
    _listKey.currentState?.insertItem(0);
    widget.storageService.saveHistory(_history);
  }

  void _convert() {
    // Приховуємо клавіатуру для кращого UX
    FocusScope.of(context).unfocus();

    final inputText = _inputController.text;
    if (inputText.trim().isEmpty) return;

    final normalizedInput = inputText.replaceAll(',', '.');
    final double? value = double.tryParse(normalizedInput);

    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, введіть коректне число')),
      );
      return;
    }

    setState(() {
      double result = widget.conversionService.convert(_selectedConversion, value);
      
      // Форматування: видаляємо зайві нулі (напр. 5.00 -> 5)
      _output = _formatResult(result);
      
      _addToHistory(_selectedConversion, value, result);
      _controller?.forward(from: 0);
    });
  }

  String _formatResult(double value) {
    String formatted = value.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    return formatted;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Конвертор одиниць',
                style: GoogleFonts.comingSoon(),
              ),
            ),
            IconButton(
              icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
              onPressed: () {
                widget.toggleTheme();
              },
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Оберіть тип конвертації:',
              style: GoogleFonts.montserratAlternates(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedConversion,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedConversion = newValue!;
                  _output = '';
                });
              },
              isExpanded: true,
              items: widget.conversionService.getConversionTypes().map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.montserratAlternates()),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Введіть значення:',
              style: GoogleFonts.montserratAlternates(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'Значення',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Видалено onChanged, оскільки стан екрану не потребує оновлення на кожен символ
            ),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                  parent: _controller!,
                  curve: Curves.easeInOut,
                ),
              ),
              child: ElevatedButton(
                onPressed: _convert,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: GoogleFonts.montserratAlternates(fontSize: 18),
                ),
                child: const Text('Конвертувати'),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _animation!,
              child: _output.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Результат:',
                          style: GoogleFonts.montserratAlternates(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller!,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _output,
                              style: GoogleFonts.montserratAlternates(fontSize: 24),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Text(
              'Історія конверсій:',
              style: GoogleFonts.montserratAlternates(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Показуємо лоадер, поки історія читається з SharedPreferences
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : AnimatedList(
                  key: _listKey,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  initialItemCount: _history.length,
                  itemBuilder: (context, index, animation) {
                    final historyItem = _history[index];
                    return _buildHistoryItem(historyItem, animation);
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ConversionHistory item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(
          '${_formatResult(item.inputValue)} ${item.conversionType} = ${_formatResult(item.outputValue)}', 
          style: GoogleFonts.montserratAlternates(),
        ),
      ),
    );
  }
}
