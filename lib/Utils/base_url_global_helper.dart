import '../models/config_data.dart';
//


class ApiBase {
  static String get baseUrl {
    // Agar config se mila hai toh wahi use hoga
    if (_config != null && _config!.dynamicapiurl != null && _config!.dynamicapiurl!.isNotEmpty) {
      return _config!.dynamicapiurl!;
    }
    // fallback to staging/uat url
    return 'https://learn.greylearn.com';
  }

  static ConfigData? _config;

  static void setConfig(ConfigData config) {
    _config = config;
  }
}


//
// class ApiBase {
//   static ConfigData? _config;
//
//   static Future<String> get baseUrl async {
//     if (_config != null && _config!.dynamicapiurl?.isNotEmpty == true) {
//       return _config!.dynamicapiurl!;
//     }
//     // Agar config null hai toh wait karo ya dobara fetch karo
//     _config = await fetchConfig();
//     return _config!.dynamicapiurl ?? 'https://learn.greylearn.com';
//   }
//
//   static void setConfig(ConfigData config) {
//     _config = config;
//   }
// }
//
