class ConversionService {
  static const Map<String, double> _conversionFactors = {
    'Кілометри в Мілі': 0.621371,
    'Мілі в Кілометри': 1 / 0.621371,
    'Дюйми в Сантиметри': 2.54,
    'Сантиметри в Дюйми': 1 / 2.54,
    'Акри в Гектари': 0.404686,
    'Гектари в Акри': 1 / 0.404686,
    'Кілограми в Фунти': 2.20462,
    'Фунти в Кілограми': 1 / 2.20462,
    'Літри в Галони': 0.264172,
    'Галони в Літри': 1 / 0.264172,
  };

  List<String> getConversionTypes() {
    return _conversionFactors.keys.toList();
  }

  double convert(String conversionType, double inputValue) {
    if (!_conversionFactors.containsKey(conversionType)) {
      throw ArgumentError('Invalid conversion type');
    }
    return inputValue * _conversionFactors[conversionType]!;
  }
}
