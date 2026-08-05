import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/conversion_history.dart';
import '../providers/converter_provider.dart';
import '../providers/theme_provider.dart';

class Converter extends StatefulWidget {
  const Converter({super.key});

  @override
  State<Converter> createState() => _ConverterState();
}

class _ConverterState extends State<Converter> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  final TextEditingController _inputController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );
  }

  void _handleConvert() {
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

    final provider = context.read<ConverterProvider>();
    final oldLength = provider.history.length;

    provider.convert(value);

    // Анімація додавання нового елемента в історію
    if (provider.history.length > oldLength) {
      _listKey.currentState?.insertItem(0);
    }
    _controller?.forward(from: 0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final converterProvider = context.watch<ConverterProvider>();

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
              icon: Icon(themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
              onPressed: () => themeProvider.toggleTheme(),
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
              value: converterProvider.selectedConversion,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  context.read<ConverterProvider>().setSelectedConversion(newValue);
                }
              },
              isExpanded: true,
              items: converterProvider.conversionTypes.map<DropdownMenuItem<String>>((String value) {
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
                onPressed: _handleConvert,
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
              child: converterProvider.output.isNotEmpty
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
                              converterProvider.output,
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
            converterProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedList(
                    key: _listKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    initialItemCount: converterProvider.history.length,
                    itemBuilder: (context, index, animation) {
                      final historyItem = converterProvider.history[index];
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
          '${_formatResultForUi(item.inputValue)} ${item.conversionType} = ${_formatResultForUi(item.outputValue)}',
          style: GoogleFonts.montserratAlternates(),
        ),
      ),
    );
  }

  String _formatResultForUi(double value) {
    String formatted = value.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    }
    return formatted;
  }
}
