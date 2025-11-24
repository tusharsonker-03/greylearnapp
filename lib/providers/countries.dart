import 'dart:convert';
import 'dart:io';
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

class Countries with ChangeNotifier {

  List<Country> countryList = [];
  List<Country> stateList = [];
  List<Country> cityList = [];

  Future<void> fetchCountryList() async {
    var authToken = await SharedPreferenceHelper().getAuthToken();
    var url = '$BASE_URL/api/countries';
    try {
      final response = await ApiClient().get(url);
      final extractedData = json.decode(response.body) as List;
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      countryList = buildCourseList(extractedData);
      // print(_items);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchStateList(String id) async {
    var authToken = await SharedPreferenceHelper().getAuthToken();
    var url = '$BASE_URL/api/states?country_id=$id';
    try {
      final response = await ApiClient().get(url);
      final extractedData = json.decode(response.body) as List;
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      stateList = buildCourseList(extractedData);
      // print(stateList);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> fetchCityList(String id) async {
    var authToken = await SharedPreferenceHelper().getAuthToken();
    var url = '$BASE_URL/api/cities?state_id=$id';
    try {
      final response = await ApiClient().get(url);
      final extractedData = json.decode(response.body) as List;
      // ignore: unnecessary_null_comparison
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      cityList = buildCourseList(extractedData);
      // print(cityList);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  List<Country> buildCourseList(List extractedData) {
    final List<Country> loadedCountryList = [];
    loadedCountryList.add(Country(id: '0',name: 'Select'));
    for (var countryData in extractedData) {
      loadedCountryList.add(Country(
        id: countryData['id'],
        sortname: countryData['sortname'],
        name: countryData['name'],
        phonecode: countryData['phonecode'],
        isdeleted: countryData['is_deleted'],
        status: countryData['status'],
        createdon: countryData['created_on'],
        updatedon: countryData['updated_on'],
        createdby: countryData['created_by'],
        updatedby: countryData['updated_by'],
      ));
      // print(countryData['id']);
      // print(countryData['name']);
    }
    return loadedCountryList;
  }
}
