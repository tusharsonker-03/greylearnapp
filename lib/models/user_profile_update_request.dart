import 'package:flutter/cupertino.dart';

class UserProfileUpdateRequest {
  final String authToken;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String country;
  final String state;
  final String city;
  final String pincode;
  final List<BoardDetail> boardDetails;
  final List<EducationDetail> educationDetails;
  final String? linkedinLink;
  final String? githubLink;

  @override
  String toString() {
    return 'UserProfileUpdateRequest{authToken: $authToken, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, gender: $gender, country: $country, state: $state, city: $city, pincode: $pincode, boardDetails: $boardDetails, educationDetails: $educationDetails, linkedinLink: $linkedinLink, githubLink: $githubLink}';
  }

  UserProfileUpdateRequest({
    required this.authToken,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.country,
    required this.state,
    required this.city,
    required this.pincode,
    required this.boardDetails,
    required this.educationDetails,
    this.linkedinLink,
    this.githubLink,
  });

  Map<String, String> toFormData() {
    final Map<String, String> data = {
      'auth_token': authToken,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'country': country,
      'state': state,
      'city': city,
      'pincode': pincode,
    };

    // Board info
    for (int i = 0; i < boardDetails.length; i++) {
      final b = boardDetails[i];
      final index = i + 1;
      data['board_type[$index]'] = b.boardType;
      data['board[$index]'] = b.board;
      data['board_marks[$index]'] = b.boardMarks;
      data['board_year[$index]'] = b.boardYear;
      data['medium[$index]'] = b.medium;
    }

    // Education info
    for (int i = 0; i < educationDetails.length; i++) {
      final e = educationDetails[i];
      final index = e.index.toString();
      data['education_type[$index]'] = e.educationType ?? '';
      data['institute_name[$index]'] = e.instituteName ?? '';
      data['course_type[$index]'] = e.courseType ?? '';
      data['course_name[$index]'] = e.courseName ?? '';
      data['specialization_name[$index]'] = e.specializationName ?? '';
      data['month[$index]'] = e.month ?? '';
      data['year[$index]'] = e.year ?? '';
      data['grading_system[$index]'] = e.gradingSystem ?? '';
      data['marks[$index]'] = e.marks ?? '';
    }

    if (linkedinLink != null) data['linkedin_link'] = linkedinLink!;
    if (githubLink != null) data['github_link'] = githubLink!;

    debugPrint(data.toString());
    return data;
  }
}

class BoardDetail {
  final String boardType;
  final String board;
  final String boardMarks;
  final String boardYear;
  final String medium;

  BoardDetail({
    required this.boardType,
    required this.board,
    required this.boardMarks,
    required this.boardYear,
    required this.medium,
  });

}

class EducationDetail {
  final int index;
  final String? educationType;
  final String? instituteName;
  final String? courseType;
  final String? courseName;
  final String? specializationName;
  final String? month;
  final String? year;
  final String? gradingSystem;
  final String? marks;

  EducationDetail({
    required this.index,
    this.educationType,
    this.instituteName,
    this.courseType,
    this.courseName,
    this.specializationName,
    this.month,
    this.year,
    this.gradingSystem,
    this.marks,
  });

}
