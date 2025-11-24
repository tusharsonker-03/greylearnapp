import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/course_detail_landing_models.dart';
import '../providers/shared_pref_helper.dart';
import '../constants.dart';

class LandingVM extends ChangeNotifier {
  bool showAllReviews = false;
  int? _openCurriculumIndex; // null = sab closed

  // API state
  bool loading = false;
  String? error;
  CourseLandingData? data;

  // ✅ ek index open hai ya nahi
  bool isOpen(int idx) => _openCurriculumIndex == idx;

  // ✅ toggle: ya to open karo, ya close (aur dusre sab auto close)
  void toggle(int idx) {
    if (_openCurriculumIndex == idx) {
      // same section dobara tap -> close all
      _openCurriculumIndex = null;
    } else {
      // koi naya section -> sirf ye open
      _openCurriculumIndex = idx;
    }
    notifyListeners();
  }

  void toggleReviews() {
    showAllReviews = !showAllReviews;
    notifyListeners();
  }

  Future<void> loadCourseById(int courseId) async {
    loading = true;
    error = null;
    // ✅ naye course pe jaate hi state reset
    _openCurriculumIndex = null;

    notifyListeners();

    try {
      var authToken = await SharedPreferenceHelper().getAuthToken();
      var url = '$BASE_URL/api/course_details_by_id?course_id=$courseId';
      if (authToken != null && authToken.isNotEmpty) {
        url = '$BASE_URL/api/course_details_by_id?auth_token=$authToken&course_id=$courseId';
      }

      final res = await ApiClient().get(url);
      final list = CourseLandingData.listFromResponse(res.body);
      if (list.isEmpty) {
        error = "No data";
      } else {
        data = list.first;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
