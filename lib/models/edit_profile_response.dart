class EditProfileResponse {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? dateOfBirth;
  String? gender;
  String? country;
  String? state;
  String? city;
  String? pincode;
  ClassX? classX;
  Graduate? graduate;
  UnderGraduate? underGraduate;
  String? facebook;
  String? twitter;
  String? linkedin;
  String? github;
  String? biography;
  String? careerNavigatorTitle;
  String? careerNavigatorProgress;
  String? image;
  String? status;

  EditProfileResponse(
      {this.id,
        this.firstName,
        this.lastName,
        this.email,
        this.phone,
        this.dateOfBirth,
        this.gender,
        this.country,
        this.state,
        this.city,
        this.pincode,
        this.classX,
        this.graduate,
        this.underGraduate,
        this.facebook,
        this.twitter,
        this.linkedin,
        this.github,
        this.biography,
        this.careerNavigatorTitle,
        this.careerNavigatorProgress,
        this.image,
        this.status});

  EditProfileResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    phone = json['phone'];
    dateOfBirth = json['date_of_birth'];
    gender = json['gender'];
    country = json['country'];
    state = json['state'];
    city = json['city'];
    pincode = json['pincode'];
    classX =
    json['class_X'] != null ? new ClassX.fromJson(json['class_X']) : null;
    graduate = json['graduate'] != null
        ? Graduate.fromJson(json['graduate'])
        : null;
    underGraduate = json['under_graduate'] != null
        ? UnderGraduate.fromJson(json['under_graduate'])
        : null;
    facebook = json['facebook'];
    twitter = json['twitter'];
    linkedin = json['linkedin'];
    github = json['github'];
    biography = json['biography'];
    careerNavigatorTitle = json['career_navigator_title'];
    careerNavigatorProgress = json['career_navigator_progress'];
    image = json['image'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['first_name'] = this.firstName;
    data['last_name'] = this.lastName;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['date_of_birth'] = this.dateOfBirth;
    data['gender'] = this.gender;
    data['country'] = this.country;
    data['state'] = this.state;
    data['city'] = this.city;
    data['pincode'] = this.pincode;
    if (this.classX != null) {
      data['class_X'] = this.classX!.toJson();
    }
    if (this.graduate != null) {
      data['graduate'] = this.graduate!.toJson();
    }
    data['facebook'] = this.facebook;
    data['twitter'] = this.twitter;
    data['linkedin'] = this.linkedin;
    data['github'] = this.github;
    data['biography'] = this.biography;
    data['career_navigator_title'] = this.careerNavigatorTitle;
    data['career_navigator_progress'] = this.careerNavigatorProgress;
    data['image'] = this.image;
    data['status'] = this.status;
    return data;
  }

  @override
  String toString() {
    return 'EditProfileResponse{id: $id, firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, dateOfBirth: $dateOfBirth, gender: $gender, country: $country, state: $state, city: $city, pincode: $pincode, classX: $classX, graduate: $graduate, underGraduate: $underGraduate, facebook: $facebook, twitter: $twitter, linkedin: $linkedin, github: $github, biography: $biography, careerNavigatorTitle: $careerNavigatorTitle, careerNavigatorProgress: $careerNavigatorProgress, image: $image, status: $status}';
  }
}

class ClassX {
  String? boardType;
  String? boardName;
  String? marks;
  String? medium;
  String? passingYear;

  ClassX(
      {this.boardType,
        this.boardName,
        this.marks,
        this.medium,
        this.passingYear});

  ClassX.fromJson(Map<String, dynamic> json) {
    boardType = json['board_type'];
    boardName = json['board_name'];
    marks = json['marks'];
    medium = json['medium'];
    passingYear = json['passing_year'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['board_type'] = this.boardType;
    data['board_name'] = this.boardName;
    data['marks'] = this.marks;
    data['medium'] = this.medium;
    data['passing_year'] = this.passingYear;
    return data;
  }

  @override
  String toString() {
    return 'ClassX{boardType: $boardType, boardName: $boardName, marks: $marks, medium: $medium, passingYear: $passingYear}';
  }
}

class UnderGraduate {
  String? educationType;
  String? instituteName;
  String? courseType;
  String? courseName;
  String? specializationName;
  String? month;
  String? year;
  String? gradingSystem;
  String? marks;

  UnderGraduate(
      {this.educationType,
        this.instituteName,
        this.courseType,
        this.courseName,
        this.specializationName,
        this.month,
        this.year,
        this.gradingSystem,
        this.marks});

  UnderGraduate.fromJson(Map<String, dynamic> json) {
    educationType = json['education_type'];
    instituteName = json['institute_name'];
    courseType = json['course_type'];
    courseName = json['course_name'];
    specializationName = json['specialization_name'];
    month = json['month'];
    year = json['year'];
    gradingSystem = json['grading_system'];
    marks = json['marks'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['education_type'] = this.educationType;
    data['institute_name'] = this.instituteName;
    data['course_type'] = this.courseType;
    data['course_name'] = this.courseName;
    data['specialization_name'] = this.specializationName;
    data['month'] = this.month;
    data['year'] = this.year;
    data['grading_system'] = this.gradingSystem;
    data['marks'] = this.marks;
    return data;
  }

  @override
  String toString() {
    return 'UnderGraduate{educationType: $educationType, instituteName: $instituteName, courseType: $courseType, courseName: $courseName, specializationName: $specializationName, month: $month, year: $year, gradingSystem: $gradingSystem, marks: $marks}';
  }
}


class Graduate {
  String? educationType;
  String? instituteName;
  String? courseType;
  String? courseName;
  String? specializationName;
  String? month;
  String? year;
  String? gradingSystem;
  String? marks;

  Graduate(
      {this.educationType,
        this.instituteName,
        this.courseType,
        this.courseName,
        this.specializationName,
        this.month,
        this.year,
        this.gradingSystem,
        this.marks});

  Graduate.fromJson(Map<String, dynamic> json) {
    educationType = json['education_type'];
    instituteName = json['institute_name'];
    courseType = json['course_type'];
    courseName = json['course_name'];
    specializationName = json['specialization_name'];
    month = json['month'];
    year = json['year'];
    gradingSystem = json['grading_system'];
    marks = json['marks'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['education_type'] = this.educationType;
    data['institute_name'] = this.instituteName;
    data['course_type'] = this.courseType;
    data['course_name'] = this.courseName;
    data['specialization_name'] = this.specializationName;
    data['month'] = this.month;
    data['year'] = this.year;
    data['grading_system'] = this.gradingSystem;
    data['marks'] = this.marks;
    return data;
  }

  @override
  String toString() {
    return 'Graduate{educationType: $educationType, instituteName: $instituteName, courseType: $courseType, courseName: $courseName, specializationName: $specializationName, month: $month, year: $year, gradingSystem: $gradingSystem, marks: $marks}';
  }
}

