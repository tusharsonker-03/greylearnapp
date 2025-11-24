import 'package:academy_app/models/all_category.dart';
import 'package:academy_app/models/config_data.dart';
import 'package:academy_app/models/sub_category.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'dart:convert';
import '../api/api_client.dart';
import '../models/category.dart';
import '../constants.dart';

class Config with ChangeNotifier {
  ConfigData configData = ConfigData();

  ConfigData get configItems {
    return configData;
  }

  Future<void> fetchConfigData() async {
    var url = '$BASE_URL_CONFIG/api/config.json';  // static config.json sirf ek baar load karne ke liye
    try {
      final response = await ApiClient().get(url);
      final extractedData = json.decode(response.body);

      if (extractedData == null) return;

      configData = ConfigData.fromJson(extractedData);

      /// ✅ Ab dynamicapiurl ko base URL bana lo
      if (configData.dynamicapiurl != null && configData.dynamicapiurl!.isNotEmpty) {
        debugPrint("✅ Dynamic API URL loaded: ${configData.dynamicapiurl}");
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

// Future<void> fetchConfigData() async {
  //   var url = '$BASE_URL_CONFIG/api/config.json';
  //   try {
  //     final response = await ApiClient().get(url);
  //     final extractedData = json.decode(response.body);
  //     // ignore: unnecessary_null_comparison
  //     if (extractedData == null) {
  //       return;
  //     }
  //     configData = ConfigData.fromJson(extractedData);
  //     notifyListeners();
  //   } catch (error) {
  //     rethrow;
  //   }
  // }

}
