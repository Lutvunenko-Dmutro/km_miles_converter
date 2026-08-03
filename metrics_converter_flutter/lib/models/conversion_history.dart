class ConversionHistory {
  final String conversionType;
  final double inputValue;
  final double outputValue;

  const ConversionHistory(this.conversionType, this.inputValue, this.outputValue);

  Map<String, dynamic> toJson() {
    return {
      'conversionType': conversionType,
      'inputValue': inputValue,
      'outputValue': outputValue,
    };
  }

  factory ConversionHistory.fromJson(Map<String, dynamic> json) {
    return ConversionHistory(
      json['conversionType'],
      json['inputValue'],
      json['outputValue'],
    );
  }
}
