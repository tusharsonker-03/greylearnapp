import 'dart:convert';
import 'dart:io';
import 'package:academy_app/models/edit_profile_response.dart';
import 'package:academy_app/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../models/common_functions.dart';
import '../models/country.dart';
import '../models/user_profile_update_request.dart';
import 'shared_pref_helper.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class UserProfile with ChangeNotifier {

  EditProfileResponse editProfileResponse = EditProfileResponse();
  Future<void> getUserProfileDetails() async {

    final authToken = await SharedPreferenceHelper().getAuthToken();
    var url = '$BASE_URL/api/userdata?auth_token=$authToken';
    try {
      if (authToken == null) {
        throw const HttpException('No Auth User');
      }
      final response = await ApiClient().get(url);

      final responseData = json.decode(response.body);
      editProfileResponse = EditProfileResponse.fromJson(responseData);
      print(editProfileResponse);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

}
