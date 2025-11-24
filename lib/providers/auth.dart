import 'dart:convert';
import 'dart:io';
import 'package:academy_app/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../main.dart';
import '../models/common_functions.dart';
import '../models/country.dart';
import '../models/user_profile_update_request.dart';
import 'shared_pref_helper.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class Auth with ChangeNotifier {
  String? _token;
  String? _userId;
  final User _user =
  User(userId: '',
    firstName: '',
    lastName: '',
    email: '',
    role: '',
    validity: '',
    deviceVerification: '',);

  String? get token {
    if (_token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    if (_userId != null) {
      return _userId;
    }
    return null;
  }

  User get user {
    return _user;
  }

  // 👇 ADD: call this right after DV success
  void setTokenAfterVerify(String token) {
    _token = token;
    _user.token = token;
    _user.validity = '1';           // keep consistent until you change model
    // _user.deviceVerification = 'verified';
    notifyListeners();
  }

  // 👇 ADD: on app start, pull token from prefs
  Future<void> hydrateFromPrefs() async {
    final t = await SharedPreferenceHelper().getAuthToken();
    if (t != null && t.isNotEmpty) {
      _token = t;
      _user.token = t;
      _user.validity = '1';
      // _user.deviceVerification = 'verified';
      notifyListeners();
    }
  }


  Future<void> login(String email, String password) async {
    var url = '$BASE_URL/api/login?email=$email&password=$password';
    try {
      final response = await ApiClient().get(url);
      print("🔹 Status Code: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        if (responseData['validity'] == 0) {
          // _user.validity = responseData['validity'];
          // _user.deviceVerification = responseData['device_verification'];
          // // throw const HttpException('Wrong credentials');
          // ✅ ONLY CHANGE: treat "needed-verification" as non-error
          final rawDv = (responseData['device_verification'] ?? '').toString();
          final dv = rawDv
              .trim()
              .toLowerCase()
              .replaceAll('_', '-')
              .replaceAll(' ', '-')
              .replaceAll('--', '-');
          final needsVerification =
              (dv.contains('need') && dv.contains('verif')) ||
                  (dv.contains('required') && dv.contains('verif')) ||
                  dv == 'need-verification' ||
                  dv == 'needed-verification' ||
                  dv == 'verification-needed' ||
                  dv == 'verification-required';
          if (needsVerification) {
            // Populate minimal fields so UI can navigate, but DON'T error/throw
            _user.userId = responseData['user_id'];
            _user.firstName = responseData['first_name'];
            _user.lastName = responseData['last_name'];
            _user.email = responseData['email'];
            _user.role = responseData['role'];
            _user.validity = responseData['validity']; // 0
            _user.deviceVerification = responseData['device_verification'];

            notifyListeners();
            return; // ⬅️ stop here; let UI route to OTP screen
          }

          // (Existing behavior for other validity==0 cases)
          _user.validity = responseData['validity'];
          _user.deviceVerification = responseData['device_verification'];
          // throw const HttpException('Wrong credentials'); // (kept commented)
        } else {
          _user.userId = responseData['user_id'];
          _user.firstName = responseData['first_name'];
          _user.lastName = responseData['last_name'];
          _user.email = responseData['email'];
          _user.role = responseData['role'];
          _user.validity = responseData['validity'];
          _user.deviceVerification = responseData['device_verification'];
          // _user.token = responseData['token'];

          // _token = responseData['token'];
          _userId = responseData['user_id'];

          final prefs = await SharedPreferences.getInstance();
          final userData = json.encode({
            'token': _token,
            'user_id': _userId,
            'user': jsonEncode(_user),
          });
          prefs.setString('userData', userData);



        }
      } else {
        _user.validity = responseData['validity'];
        _user.deviceVerification = responseData['device_verification'];
        // throw const HttpException('Auth Failed');
      }

      // _token = responseData['token'];
      // _userId = responseData['user_id'];

      // final loadedUser = User(
      //   userId: responseData['user_id'],
      //   firstName: responseData['first_name'],
      //   lastName: responseData['last_name'],
      //   email: responseData['email'],
      //   role: responseData['role'],
      //   deviceVerification: responseData['device_verification'],
      // );

      // _user = loadedUser;

      notifyListeners();

      // print(userData);
    } catch (error) {
      rethrow;
    }
  }


  // Future<void> login(String email, String password) async {
  //   var url = '$BASE_URL/api/login?email=$email&password=$password';

  //   try {
  //     final response = await ApiClient().get(url);
  //     final responseData = json.decode(response.body);

  //     // print(responseData['validity']);
  //     if (responseData['validity'] == 0) {
  //       throw const HttpException('Auth Failed');
  //     }
  //     _token = responseData['token'];
  //     _userId = responseData['user_id'];

  //     final loadedUser = User(
  //       userId: responseData['user_id'],
  //       firstName: responseData['first_name'],
  //       lastName: responseData['last_name'],
  //       email: responseData['email'],
  //       role: responseData['role'],
  //     );

  //     _user = loadedUser;

  //     notifyListeners();
  //     await SharedPreferenceHelper().setAuthToken(token!);
  //     final prefs = await SharedPreferences.getInstance();
  //     final userData = json.encode({
  //       'token': _token,
  //       'user_id': _userId,
  //       'user': jsonEncode(_user),
  //     });
  //     prefs.setString('userData', userData);
  //     // print(userData);
  //   } catch (error) {
  //     rethrow;
  //   }
  // }

  Future<void> getUserInfo() async {
    // final prefs = await SharedPreferences.getInstance();

    // var userData = (prefs.getString('userData') ?? '');
    // var response = json.decode(userData);
    // final authToken = response['token'];
    // print(response['user']);
    final authToken = await SharedPreferenceHelper().getAuthToken();
    print('Direect authtoken: $authToken');
    var url = '$BASE_URL/api/userdata?auth_token=$authToken';
    try {
      if (authToken == null) {
        // throw const HttpException('No Auth User');
        // 🚪 User ko logout kar do (dusre device se login ki wajah se)
        await logoutUser(navigatorKey.currentContext!);
        return;
      }
      final response = await ApiClient().get(url);

      final responseData = json.decode(response.body);

      _user.firstName = responseData['first_name'];
      _user.lastName = responseData['last_name'];
      _user.email = responseData['email'];
      _user.image = responseData['image'];
      _user.facebook = responseData['facebook'];
      _user.twitter = responseData['twitter'];
      _user.linkedIn = responseData['linkedin'];
      _user.biography = responseData['biography'];
      _user.careerNavigatorTitle = responseData['career_navigator_title'];
      _user.careerNavigatorProgress = responseData['career_navigator_progress'];
      // print(_user.image);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
  Future<void> getUserProfileDetails() async {
    // final prefs = await SharedPreferences.getInstance();

    // var userData = (prefs.getString('userData') ?? '');
    // var response = json.decode(userData);
    // final authToken = response['token'];
    // print(response['user']);
    final authToken = await SharedPreferenceHelper().getAuthToken();
    var url = '$BASE_URL/api/userdata?auth_token=$authToken';
    try {
      if (authToken == null) {
        throw const HttpException('No Auth User');
      }
      final response = await ApiClient().get(url);

      final responseData = json.decode(response.body);

      _user.firstName = responseData['first_name'];
      _user.lastName = responseData['last_name'];
      _user.email = responseData['email'];
      _user.image = responseData['image'];
      _user.facebook = responseData['facebook'];
      _user.twitter = responseData['twitter'];
      _user.linkedIn = responseData['linkedin'];
      _user.biography = responseData['biography'];
      // print(_user.image);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> userImageUpload(File image) async {
    final token = await SharedPreferenceHelper().getAuthToken();
    var url = '$BASE_URL/api/upload_user_image';
    var uri = Uri.parse(url);
    var request = http.MultipartRequest('POST', uri);
    request.fields['auth_token'] = token!;

    request.files.add(http.MultipartFile(
        'file', image.readAsBytes().asStream(), image.lengthSync(),
        filename: basename(image.path)));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        response.stream.transform(utf8.decoder).listen((value) {
          final responseData = json.decode(value);
          if (responseData['status'] != 'success') {
            throw const HttpException('Upload Failed');
          }
          notifyListeners();
          // print(value);
        });
      }

      // final responseData = json.decode(response.body);
    } catch (error) {
      rethrow;
    }
  }

  // At a time one device login
  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // apni login route ka naam yahan lagao
          (route) => false,
    );
  }


  Future<void> logout() async {
    _token = null;
    dynamic data = await SharedPreferenceHelper().getConfigData();
    // _user = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    prefs.clear();
    SharedPreferenceHelper().setConfigData(json.encode(data));
  }

  Future<void> updateUserData(User user) async {
    final token = await SharedPreferenceHelper().getAuthToken();
    final url = '$BASE_URL/api/update_userdata';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'auth_token': token,
          'first_name': user.firstName,
          'last_name': user.lastName,
          'email': user.email,
          'biography': user.biography,
          'twitter_link': user.twitter,
          'facebook_link': user.facebook,
          'linkedin_link': user.linkedIn,
        },
      );

      final responseData = json.decode(response.body);
      if (responseData['status'] == 'failed') {
        throw const HttpException('Update Failed');
      }

      _user.firstName = responseData['first_name'];
      _user.lastName = responseData['last_name'];
      _user.email = responseData['email'];
      _user.image = responseData['image'];
      _user.twitter = responseData['twitter'];
      _user.linkedIn = responseData['linkedin'];
      _user.biography = responseData['biography'];
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> uploadUserProfileWithResume({
    required UserProfileUpdateRequest userMap,
    required File? resumeFile,
  }) async {
    final token = await SharedPreferenceHelper().getAuthToken();
    final url = '$BASE_URL/api/update_userdata';
    final uri = Uri.parse(url); //
    debugPrint('Request url--> ${url.toString()}');

    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(userMap.toFormData());
    debugPrint('Request --> ${request.fields.toString()}');

    // Add resume file if available
    // if (resumeFile != null) {
    //   request.files.add(
    //     await http.MultipartFile.fromPath(
    //       'resume', //  This must match your backend field name
    //       resumeFile.path,
    //     ),
    //   );
    // }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('response --> ${response.toString()}');
      final responseData = json.decode(response.body);
      debugPrint('response --> ${responseData.toString()}');

      if (response.statusCode == 200) {
        CommonFunctions.showSuccessToast(
            'Profile & resume uploaded successfully');
      } else {
        CommonFunctions.showWarningToast(
          'Failed to upload: ${response.statusCode}',
        );
      }
    } catch (e) {
      CommonFunctions.showWarningToast('Error: $e');
    }
  }

  Future<void> updateUserPassword(String currentPassword,
      String newPassword) async {
    final token = await SharedPreferenceHelper().getAuthToken();
    final url = '$BASE_URL/api/update_password';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'auth_token': token,
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': newPassword,
        },
      );

      final responseData = json.decode(response.body);
      if (responseData['status'] == 'failed') {
        throw const HttpException('Password update Failed');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateFCMData() async {
    final token = await SharedPreferenceHelper().getAuthToken();
    final fcmToken = await SharedPreferenceHelper().getFCMToken();
    final url = '$BASE_URL/api/update_fcm_token';
    debugPrint('Request url--> ${url.toString()}');
    debugPrint(token);
    debugPrint(fcmToken);
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'auth_token': token ?? "",
          'fcm_token': fcmToken ?? "",
        },
      );

      final responseData = json.decode(response.body);
      debugPrint('Response --> ${responseData.toString()}');
      if (responseData['status'] == 'failed') {
        throw const HttpException('Update Failed');
      }
    } catch (error) {
      rethrow;
    }
  }
//   Future<void> fetchCountryList() async {
//     var authToken = await SharedPreferenceHelper().getAuthToken();
//     var url = '$BASE_URL/api/countries';
//     try {
//       final response = await ApiClient().get(url);
//       final extractedData = json.decode(response.body) as List;
//       // ignore: unnecessary_null_comparison
//       if (extractedData == null) {
//         return;
//       }
//       // print(extractedData);
//       countryList = buildCourseList(extractedData);
//       // print(_items);
//       notifyListeners();
//     } catch (error) {
//       rethrow;
//     }
//   }
//
//   List<Country> buildCourseList(List extractedData) {
//     final List<Country> loadedCountryList = [];
//     for (var countryData in extractedData) {
//       loadedCountryList.add(Country(
//         id: countryData['id'],
//         sortname: countryData['sortname'],
//         name: countryData['name'],
//         phonecode: countryData['phonecode'],
//         isdeleted: countryData['is_deleted'],
//         status: countryData['status'],
//         createdon: countryData['created_on'],
//         updatedon: countryData['updated_on'],
//         createdby: countryData['created_by'],
//         updatedby: countryData['updated_by'],
//       ));
//       print(countryData['id']);
//       print(countryData['name']);
//     }
//     return loadedCountryList;
//   }
}
