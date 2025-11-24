import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class FieldInputHelper {
  static TextInputType getKeyboardType(String label) {
    label = label.toLowerCase();
    if (label.contains('email')) {
      return TextInputType.emailAddress;
    } else if (label.contains('phone') || label.contains('mobile')) {
      return TextInputType.phone;
    } else if (label.contains('date of birth')) {
      return TextInputType.datetime;
    } else if (label.contains('pin code') || label.contains('zip')) {
      return TextInputType.number;
    } else if (label.contains('marks') || label.contains('percentage')) {
      return const TextInputType.numberWithOptions(decimal: true);
    } else if (label.contains('year') || label.contains('month')) {
      return TextInputType.number;
    } else {
      return TextInputType.text;
    }
  }

  static List<TextInputFormatter> getInputFormatters(String label) {
    label = label.toLowerCase();
    if (label.contains('pincode') || label.contains('zip')) {
      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)];
    } else if (label.contains('phone') || label.contains('mobile')) {
      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)];
    } else if (label.contains('marks') || label.contains('percentage')) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ];
    } else if (label.contains('year')) {
      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)];
    } else {
      return []; // no restrictions
    }
  }
}
