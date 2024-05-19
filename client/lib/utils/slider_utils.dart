import 'package:intl/intl.dart';

String formatLabel(String label, double value, List<String> labels) {
  String formattedValue = value.toStringAsFixed(0);
  RegExp unitRegex = RegExp(r'\((.*?)\)');
  var unitMatch = unitRegex.firstMatch(label);
  if (unitMatch != null) {
    formattedValue += ' ${unitMatch.group(1)}';
  }
  if (label.contains('Salary')) {
    final numberFormat = NumberFormat('#,##0.00');
    formattedValue = '\$${numberFormat.format(value)}';
  }
  if (label.contains('Percent')) {
    formattedValue += '%';
  }
  if (labels.length == 5 && labels.every((element) => element.isNotEmpty)) {
    formattedValue = labels[value.toInt()];
  }
  return formattedValue;
}

double decodeFromI16(
    int value, double realMin, double realMax, int min, int max) {
  return (value - min) * (realMax - realMin) / (max - min) + realMin;
}
