// // ignore_for_file: use_build_context_synchronously
//
// import 'dart:convert';
// import 'dart:io';
// import 'package:academy_app/constants.dart';
// import 'package:academy_app/models/common_functions.dart';
// import 'package:academy_app/models/country.dart';
// import 'package:academy_app/models/user.dart';
// import 'package:academy_app/providers/auth.dart';
// import 'package:academy_app/providers/countries.dart';
// import 'package:academy_app/providers/user_profile.dart';
// import 'package:academy_app/widgets/app_bar_two.dart';
// import 'package:academy_app/widgets/user_image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:provider/provider.dart';
//
// import '../Utils/FieldInputHelper.dart';
// import '../models/config_data.dart';
// import '../models/edit_profile_response.dart';
// import '../models/user_profile_update_request.dart';
// import '../providers/courses.dart';
// import '../providers/shared_pref_helper.dart';
// import 'package:dropdown_search/dropdown_search.dart';
//
// import '../widgets/pdf_upload_widget.dart';
//
// class EditProfileScreen extends StatefulWidget {
//   static const routeName = '/edit-profile';
//   const EditProfileScreen({super.key});
//
//   @override
//   // ignore: library_private_types_in_public_api
//   _EditProfileScreenState createState() => _EditProfileScreenState();
// }
//
// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final GlobalKey<FormState> _formKey = GlobalKey();
//   final GlobalKey<FormState> _formKey1 = GlobalKey();
//   ConfigData configData = ConfigData();
//   bool _isLoading = false;
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   // final Map<String, TextEditingController> _controllers = {};
//   final TextEditingController _firstname = TextEditingController();
//   final TextEditingController _lastname = TextEditingController();
//   final TextEditingController _mobile = TextEditingController();
//   final TextEditingController _dob = TextEditingController();
//   final TextEditingController _gender = TextEditingController();
//   final TextEditingController _country = TextEditingController();
//   final TextEditingController _state = TextEditingController();
//   final TextEditingController _city = TextEditingController();
//   final TextEditingController _pincode = TextEditingController();
//   final TextEditingController _classXMarks = TextEditingController();
//   final TextEditingController _uGcourseName = TextEditingController();
//   final TextEditingController _uGSpecailaization = TextEditingController();
//   final TextEditingController _uGMarks = TextEditingController();
//   final TextEditingController _uGGrade = TextEditingController();
//   final TextEditingController _gCourseName = TextEditingController();
//   final TextEditingController _gSpecailaization = TextEditingController();
//   final TextEditingController _gMarks = TextEditingController();
//   final TextEditingController _gGrade = TextEditingController();
//   final TextEditingController _linkedinLink = TextEditingController();
//   final TextEditingController _githubLink = TextEditingController();
//   final TextEditingController _uGInstituteName = TextEditingController();
//   final TextEditingController _gInstituteName = TextEditingController();
//
//
//   String _selectedGender = 'Male';
//   String _selectedCountry = '101';
//   String _selectedState = '0';
//   String _selectedCity = '0';
//   //class x
//   String _selectedXBoard = '';
//   String _selectedXYear = '';
//   String _selectedXMedium = '';
//   //class UG
//   String _selectedUGName = '';
//   String _selectedUGType = '';
//   String _selectedUGMonth = '';
//   String _selectedUGYear = '';
//   //class G
//   String _selectedGName = '';
//   String _selectedGType = '';
//   String _selectedGMonth = '';
//   String _selectedGYear = '';
//   File? _selectedPdf;
//   static const int maxFileSize = 2 * 1024 * 1024; // 2MB
//   var _isInit = true;
//   List<BoardDetail> boardDetailsList = [];
//   List<EducationDetail> boardunGDetailsList = [];
//   final List<Map<String, String>> boardControllers = [];
//   final List<Map<String, String>> boardUnGControllers = [];
//   Map<String, String> boardDetail = {};
//   Map<String, String> unGDetail = {};
//   List<Option> yearOptions = [];
//   List<Option> listBoardClass = [];
//   List<Option> listBoardMedium = [];
//   List<Option> listuGInstitute = [];
//   List<Option> listuGCourseType = [];
//   List<Option> listMonths = [];
//   // List of items in our dropdown menu
//   var items = [
//     'Male',
//     'Female',
//   ];
//   @override
//   void initState() {
//     super.initState();
//     getConfigData();
//     Provider.of<UserProfile>(context, listen: false).getUserProfileDetails().then((_) async {
//       final userdata = Provider.of<UserProfile>(context, listen: false).editProfileResponse;
//       await setUserProfileFields(userdata);
//     });
//     Future.delayed(const Duration(seconds: 2), () {
//       debugPrint('called-->fetchCityList');
//       Provider.of<Countries>(context,listen: false).fetchCityList(_selectedState);
//     });
//   }
//
//
//   bool isCompleteUGFilled() {
//     final enteredMarks = double.tryParse(_uGMarks.text.trim());
//
//     if (enteredMarks != null) {
//       if (_selectedUGGradingSystem == 'gpa_out_of_4' && enteredMarks > 4) {
//         CommonFunctions.showWarningToast("UG marks must be 4 or less (GPA out of 4 selected).");
//         return false;
//       }
//       if (_selectedUGGradingSystem == 'gpa_out_of_10' && enteredMarks > 10) {
//         CommonFunctions.showWarningToast("UG marks must be 10 or less (GPA out of 10 selected).");
//         return false;
//       }
//       if (_selectedUGGradingSystem == 'percentage' && enteredMarks > 100) {
//         CommonFunctions.showWarningToast("UG marks must be 100 or less (Percentage selected).");
//         return false;
//       }
//     }
//
//     if (_uGInstituteName.text.trim().isEmpty ||
//         _uGcourseName.text.trim().isEmpty ||
//         _uGSpecailaization.text.trim().isEmpty ||
//         _selectedUGType == null || _selectedUGType == '' ||
//         _selectedUGMonth == null || _selectedUGMonth == '' ||
//         _selectedUGYear == null || _selectedUGYear == '') {
//       CommonFunctions.showWarningToast("Please complete all required UG fields.");
//       return false;
//     }
//
//     return true;
//   }
//
//
//   bool isCompleteGraduateFilled() {
//     final enteredMarks = double.tryParse(_gMarks.text.trim());
//
//     if (enteredMarks != null) {
//       if (_selectedGrGradingSystem == 'gpa_out_of_4' && enteredMarks > 4) {
//         CommonFunctions.showWarningToast("Graduate marks must be 4 or less (GPA out of 4 selected).");
//         return false;
//       }
//       if (_selectedGrGradingSystem == 'gpa_out_of_10' && enteredMarks > 10) {
//         CommonFunctions.showWarningToast("Graduate marks must be 10 or less (GPA out of 10 selected).");
//         return false;
//       }
//       if (_selectedGrGradingSystem == 'percentage' && enteredMarks > 100) {
//         CommonFunctions.showWarningToast("Graduate marks must be 100 or less (Percentage selected).");
//         return false;
//       }
//     }
//
//     if (_gInstituteName.text.trim().isEmpty ||
//         _gCourseName.text.trim().isEmpty ||
//         _gSpecailaization.text.trim().isEmpty ||
//         _selectedGType == null || _selectedGType == '' ||
//         _selectedGMonth == null || _selectedGMonth == '' ||
//         _selectedGYear == null || _selectedGYear == '') {
//       CommonFunctions.showWarningToast("Please complete all required Graduate fields.");
//       return false;
//     }
//
//     return true;
//   }
//
//   bool _anyUGFieldFilled() {
//     final currentYear = DateTime.now().year;
//     final selectedYear = int.tryParse(_selectedUGYear ?? '');
//     final isYearBeforeCurrent = selectedYear != null && selectedYear < currentYear;
//
//     final hasAnyMarks = _uGMarks.text.trim().isNotEmpty ||
//         (_selectedUGGradingSystem != null &&
//             _selectedUGGradingSystem!.trim().isNotEmpty &&
//             _selectedUGGradingSystem != 'Select');
//
//     return _uGInstituteName.text.trim().isNotEmpty ||
//         _uGcourseName.text.trim().isNotEmpty ||
//         _uGSpecailaization.text.trim().isNotEmpty ||
//         (_selectedUGType != null && _selectedUGType!.trim().isNotEmpty && _selectedUGType != 'Select') ||
//         (_selectedUGMonth != null && _selectedUGMonth!.trim().isNotEmpty && _selectedUGMonth != 'Select') ||
//         (_selectedUGYear != null && _selectedUGYear!.trim().isNotEmpty && _selectedUGYear != 'Select') ||
//         (isYearBeforeCurrent && hasAnyMarks);
//   }
//
//
//   bool _anyGraduateFieldFilled() {
//     final currentYear = DateTime
//         .now()
//         .year;
//     final selectedYear = int.tryParse(_selectedGYear ?? '');
//     final isYearBeforeCurrent = selectedYear != null &&
//         selectedYear < currentYear;
//
//     final hasAnyMarks = _gMarks.text
//         .trim()
//         .isNotEmpty ||
//         (_selectedGrGradingSystem != null &&
//             _selectedGrGradingSystem!.trim().isNotEmpty &&
//             _selectedGrGradingSystem != 'Select');
//
//     return _gInstituteName.text
//         .trim()
//         .isNotEmpty ||
//         _gCourseName.text
//             .trim()
//             .isNotEmpty ||
//         _gSpecailaization.text
//             .trim()
//             .isNotEmpty ||
//         (_selectedGType != null && _selectedGType!.trim().isNotEmpty &&
//             _selectedGType != 'Select') ||
//         (_selectedGMonth != null && _selectedGMonth!.trim().isNotEmpty &&
//             _selectedGMonth != 'Select') ||
//         (_selectedGYear != null && _selectedGYear!.trim().isNotEmpty &&
//             _selectedGYear != 'Select') ||
//         (isYearBeforeCurrent && hasAnyMarks);
//   }
//
//
//
//   Future<void> getConfigData() async {
//     dynamic data = await SharedPreferenceHelper().getConfigData();
//     if (data != null) {
//       final decodedData = ConfigData.fromJson(json.decode(data));
//       setState(() {
//         configData = decodedData;
//       });
//     }
//
//     const int startYear = 1900;
//     final int endYear = DateTime.now().year+10;
//
//     yearOptions = [
//       for (var y = endYear; y >= startYear; y--)
//         Option(label: y.toString(), value: y.toString()),
//     ];
//
//     listBoardClass = List<Option>.from(configData.userprofilefields?[13]?.options ?? []);
//     listBoardMedium = List<Option>.from(configData.userprofilefields?[16]?.options ?? []);
//     listuGCourseType = List<Option>.from(configData.userprofilefields?[19]?.options ?? []);
//     listMonths = List<Option>.from(configData.userprofilefields?[22]?.options ?? []);
//     listuGInstitute = List<Option>.from(configData.userprofilefields?[22]?.options ?? []);
//
//   }
//   callStateListApi(var id){
//     setState(() {
//       _isLoading = true;
//     });
//     Provider.of<Countries>(context,listen: false).fetchStateList(id)
//         .then((_) {
//       setState(() {
//         _isLoading = false;
//       });
//     });
//   }
//   callCityListApi(var id){
//     setState(() {
//       _isLoading = true;
//     });
//     Provider.of<Countries>(context,listen: false).fetchCityList(id)
//         .then((_) {
//       setState(() {
//         _isLoading = false;
//       });
//     });
//   }
//   @override
//   void didChangeDependencies() {
//     if (_isInit) {
//       setState(() {
//         _isLoading = true;
//       });
//       Provider.of<Countries>(context).fetchCountryList()
//           .then((_) {
//             setState(() {
//               _isLoading = false;
//             });
//       });
//       callStateListApi(_selectedCountry);
//       callCityListApi(_selectedState);
//     }
//     _isInit = false;
//     super.didChangeDependencies();
//   }
//
//   // Future<void> _submit() async {
//   //   if (!_formKey.currentState!.validate()) {
//   //     // Invalid!
//   //     CommonFunctions.showWarningToast(
//   //       'Request Failed.. Field can not empty',
//   //     );
//   //     return;
//   //   }
//   //
//   //   // ✅ UG / Graduate mandatory check
//   //   if (!_checkEducationFields()) {
//   //     return; // stop submit
//   //   }
//   //
//   //
//   //   // ✅ Check for Class 10 Marks > 100
//   //   final classXMarks = int.tryParse(_classXMarks.text.trim()) ?? 0;
//   //   if (classXMarks > 100) {
//   //     CommonFunctions.showWarningToast("Class 10 Marks cannot be more than 100");
//   //     return; // Stop submit
//   //   }
//   //   if (classXMarks < 0) {
//   //     CommonFunctions.showWarningToast("Class 10 Marks cannot be negative");
//   //     return; // Stop submit
//   //   }
//   //
//   //   validate();
//   //   _formKey.currentState!.save();
//   //   setState(() {
//   //     _isLoading = true;
//   //   });
//   //
//   //   final token = await SharedPreferenceHelper().getAuthToken();
//   //
//   //     boardDetailsList.clear();
//   //     final detail = BoardDetail(
//   //       boardType: '1' ?? "",
//   //       board: _selectedXBoard ?? "",
//   //       boardMarks: _classXMarks.text ?? "",
//   //       boardYear: _selectedXYear ?? "",
//   //       medium: _selectedXMedium ?? "",
//   //     );
//   //     boardDetailsList.add(detail);
//   //     //debugPrint(boardDetailsList.toString());
//   //
//   //     final uGDetails = EducationDetail(
//   //       index: 3,
//   //       educationType: "3" ?? "",
//   //       instituteName: _selectedUGName ?? "",
//   //       courseName: _uGcourseName.text ?? "",
//   //       courseType: _selectedUGType ?? "",
//   //       specializationName: _uGSpecailaization.text ?? "",
//   //       month: _selectedUGMonth ?? "",
//   //       year: _selectedUGYear ?? "",
//   //       gradingSystem: _uGGrade.text ?? "",
//   //       marks: _uGMarks.text ?? "",
//   //     );
//   //   boardunGDetailsList.add(uGDetails);
//   //
//   //   final gDetails = EducationDetail(
//   //     index: 4,
//   //     educationType: "4" ?? "",
//   //     instituteName: _selectedGName ?? "",
//   //     courseName: _gCourseName.text ?? "",
//   //     courseType: _selectedGType ?? "",
//   //     specializationName: _gSpecailaization.text ?? "",
//   //     month: _selectedGMonth ?? "",
//   //     year: _selectedGYear ?? "",
//   //     gradingSystem: _gGrade.text ?? "",
//   //     marks: _gMarks.text ?? "",
//   //   );
//   //   boardunGDetailsList.add(gDetails);
//   //
//   //   final request =  UserProfileUpdateRequest(
//   //       authToken: token ?? '',
//   //       firstName:  _firstname.text ?? "",
//   //       lastName: _lastname.text ?? "",
//   //       dateOfBirth: _dob.text ?? "",
//   //       gender: _selectedGender ?? "",
//   //       country: _country.text ?? "",
//   //       state: _state.text ?? "",
//   //       city: _city.text ?? "",
//   //       pincode: _pincode.text ?? "",
//   //       linkedinLink: _linkedinLink.text ?? "",
//   //       githubLink: _githubLink.text ?? '',
//   //       boardDetails: boardDetailsList,
//   //       educationDetails: boardunGDetailsList);
//   //   // Log user in
//   //     print("request.toString()");
//   //     print(request.toFormData());
//   //     await Provider.of<Auth>(context, listen: false)
//   //         .uploadUserProfileWithResume(userMap: request, resumeFile: File(_selectedPdf?.path ?? ""));
//   //
//   //   setState(() {
//   //     _isLoading = false;
//   //   });
//   // }
//
//
//
//   Future<void> _submit() async {
//     if (!_anyUGFieldFilled() && !_anyGraduateFieldFilled()) {
//       CommonFunctions.showWarningToast("Please fill either UG or Graduate details.");
//       return;
//     }
//
//     // if (_anyUGFieldFilled() && !isCompleteUGFilled()) {
//     //   CommonFunctions.showWarningToast("Please complete all required UG fields.");
//     //   return;
//     // }
//     // if (_anyGraduateFieldFilled() && !isCompleteGraduateFilled()) {
//     //   CommonFunctions.showWarningToast("Please complete all required Graduate fields.");
//     //   return;
//     // }
//
//     if (_anyUGFieldFilled()) {
//       bool isUGValid = isCompleteUGFilled();
//       if (!isUGValid) return; // Show toast inside the function only
//     }
//
//     if (_anyGraduateFieldFilled()) {
//       bool isGraduateValid = isCompleteGraduateFilled();
//       if (!isGraduateValid) return; // Show toast inside the function only
//     }
//
//
//     if (!_formKey.currentState!.validate()) {
//       CommonFunctions.showWarningToast('Request Failed.. Field can not be empty');
//       return;
//     }
//
//     setState(() => _isLoading = true);
//     final token = await SharedPreferenceHelper().getAuthToken();
//
//     final xMarks = double.tryParse(_classXMarks.text.trim());
//
//     if (xMarks != null && xMarks > 100) {
//       CommonFunctions.showWarningToast("Class 10 marks cannot be more than 100.");
//       setState(() => _isLoading = false); // stop loading
//       return;
//     }
//
//     // Step 1: Class X
//     boardDetailsList.clear();
//     boardDetailsList.add(BoardDetail(
//       boardType: '1',
//       board: _selectedXBoard,
//       boardMarks: _classXMarks.text.trim(),
//       boardYear: _selectedXYear,
//       medium: _selectedXMedium,
//     ));
//
//     // Step 2: UG + Graduate
//     boardunGDetailsList.clear();
//
//     if (_anyUGFieldFilled()) {
//       boardunGDetailsList.add(EducationDetail(
//         index: 3,
//         educationType: "3",
//         instituteName: _selectedUGName.isNotEmpty
//             ? _selectedUGName
//             : _uGInstituteName.text.trim(), // ✅ fallback to text
//         courseName: _uGcourseName.text.trim(),
//         courseType: _selectedUGType,
//         specializationName: _uGSpecailaization.text.trim(),
//         month: _selectedUGMonth,
//         year: _selectedUGYear,
//         gradingSystem: _selectedUGGradingSystem,
//         marks: _uGMarks.text.trim(),
//       ));
//     }
//
//     if (_anyGraduateFieldFilled()) {
//       boardunGDetailsList.add(EducationDetail(
//         index: 4,
//         educationType: "4",
//         instituteName: _selectedGName.isNotEmpty
//             ? _selectedGName
//             : _gInstituteName.text.trim(),
//         courseName: _gCourseName.text.trim(),
//         courseType: _selectedGType,
//         specializationName: _gSpecailaization.text.trim(),
//         month: _selectedGMonth,
//         year: _selectedGYear,
//         gradingSystem: _selectedGrGradingSystem,
//         marks: _gMarks.text.trim(),
//       ));
//     }
//
//     // Step 3: Request
//     final request = UserProfileUpdateRequest(
//       authToken: token ?? '',
//       firstName: _firstname.text.trim(),
//       lastName: _lastname.text.trim(),
//       dateOfBirth: _dob.text.trim(),
//       gender: _selectedGender,
//       country: _country.text.trim(),
//       state: _state.text.trim(),
//       city: _city.text.trim(),
//       pincode: _pincode.text.trim(),
//       linkedinLink: _linkedinLink.text.trim(),
//       githubLink: _githubLink.text.trim(),
//       boardDetails: boardDetailsList,
//       educationDetails: boardunGDetailsList,
//     );
//
//     print("=== API Request ===");
//     print(request.toFormData());
//
//     await Provider.of<Auth>(context, listen: false).uploadUserProfileWithResume(
//       userMap: request,
//       resumeFile: File(_selectedPdf?.path ?? ""),
//     );
//
//     // Step 4: Refresh UI
//     await Provider.of<UserProfile>(context, listen: false).getUserProfileDetails();
//     final updatedUser = Provider.of<UserProfile>(context, listen: false).editProfileResponse;
//     setUserProfileFields(updatedUser);
//
//     setState(() => _isLoading = false);
//   }
//
//
//   InputDecoration getInputDecoration(String hintext, IconData iconData) {
//     return InputDecoration(
//       border: InputBorder.none,
//       enabledBorder: kDefaultInputBorder,
//       focusedBorder: kDefaultFocusInputBorder,
//       focusedErrorBorder: kDefaultFocusErrorBorder,
//       errorBorder: kDefaultFocusErrorBorder,
//       filled: true,
//       hintStyle: const TextStyle(color: kFormInputColor),
//       hintText: hintext,
//       fillColor: Colors.white70,
//       prefixIcon: Icon(
//         iconData,
//         color: kFormInputColor,
//       ),
//       contentPadding: const EdgeInsets.symmetric(vertical: 5),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const CustomAppBarTwo(),
//       backgroundColor: kBackgroundColor,
//       body: FutureBuilder(
//         future: Provider.of<UserProfile>(context, listen: false).getUserProfileDetails(),
//         builder: (ctx, dataSnapshot) {
//           if (dataSnapshot.error != null) {
//             return const Center(
//               child: Text('Error Occured'),
//             );
//           } else {
//             return Consumer<UserProfile>(
//               builder: (context, authData, child) {
//                 final user = authData.editProfileResponse;
//                 // setUserProfileFields(user);
//                 return SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Padding(
//                         padding:
//                         EdgeInsets.only(left: 15, top: 10, bottom: 5.0),
//                         child: Text(
//                           'Update Profile Picture',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                         width: double.infinity,
//                         child:user.image != null ? UserImagePicker(
//                           image: user.image,
//                         ) : SizedBox.shrink(),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(10.0),
//                           child: Form(
//                             key: _formKey,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 buildUI(context),
//                                 const SizedBox(
//                                   height: 15,
//                                 ),
//                                 SizedBox(
//                                   width: double.infinity,
//                                   child: _isLoading
//                                       ? const CircularProgressIndicator()
//                                       : MaterialButton(
//                                     onPressed: _submit,
//                                     color: kRedColor,
//                                     textColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 15, vertical: 15),
//                                     splashColor: Colors.redAccent,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius:
//                                       BorderRadius.circular(7.0),
//                                       side: const BorderSide(
//                                           color: kRedColor),
//                                     ),
//                                     child: const Text(
//                                       'Update Now',
//                                       style: TextStyle(
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//           // if (dataSnapshot.connectionState == ConnectionState.waiting) {
//           //   return Center(
//           //     child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
//           //   );
//           // } else {
//           //
//           // }
//         },
//       ),
//     );
//   }
//
//  Widget buildUI(BuildContext context){
//     debugPrint(configData.userprofilefields?[4]?.options.toString());
//     dynamic list = configData.userprofilefields?[4]?.options;
//    return  Column(
//       children: [
//         buildFormField("First Name",_firstname),
//         buildFormField("Last Name",_lastname),
//         buildFormFieldPhone("Mobile",),
//         buildFormFieldCalender("Date of birth",context),
//         buildFormFieldGender("Gender",list ?? []),
//         buildFormFieldCountry("Country"),
//         buildFormFieldState("State"),
//         buildFormFieldCity("City"),
//         buildFormPincodeField("Pin code",_pincode),
//         buildDividerTitle("Class X Details"),
//         buildFormFieldClassX("Board Name",listBoardClass,0),
//         buildFormField("Your Marks",_classXMarks),
//         buildFormFieldClassX("Year of passing",yearOptions,1),
//         buildFormFieldClassX("Medium",listBoardMedium,2),
//         buildDividerTitle("Under Graduate Details"),
//         buildFormUnderGraField("College / Institute Name",_uGInstituteName),
//         buildFormFieldUnderGradu("Course Type",listuGCourseType,1),
//         buildFormUnderGraField("Course Name",_uGcourseName),
//         buildFormUnderGraField("Specialization",_uGSpecailaization),
//         buildFormFieldUnderGradu("Month of passing",listMonths,2),
//         buildFormFieldUnderGradu("Year of passing",yearOptions,3),
//         gradeNMarksUIUG(),
//         buildInfoTitle("Graduate Details"),
//           buildFormGraduateField("College / Institute Name",_gInstituteName),
//           buildFormFieldGradu("Course Type",listuGCourseType,1),
//           buildFormGraduateField("Course Name",_gCourseName),
//           buildFormGraduateField("Specialization",_gSpecailaization),
//           buildFormFieldGradu("Month of passing",listMonths,2),
//           buildFormFieldGradu("Year of passing",yearOptions,3),
//         gradeNMarksUIGraduate(),
//         buildformLinkedin("Linkedin link",_linkedinLink),
//         buildformGithub("Github link",_githubLink),
//         buildFormFieldResume("Upload CV")
//       ],
//     );
//   }
//   gradeNMarksUIUG(){
//    final currentYear =  DateTime.now().year;
//    final selectedYear =  int.tryParse(_selectedUGYear) ?? 1900;
//     if(selectedYear < currentYear){
//      return Column(
//        children: [
//          buildFormField("Grading System-",_uGGrade),
//          buildFormField("Marks-",_uGMarks)
//        ]
//      );
//     }else{
//       return const SizedBox.shrink();
//     }
//   }
//
//   Widget buildFormField(String label,TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             controller: controller,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(   // 👈 hintText का color control
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//                 getIconForField(label),
//                 color: Colors.grey.shade400,
//
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//
//               filled: true,
//               fillColor: Colors.white,
//               // ✅ Light grey border with radius
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: FieldInputHelper.getKeyboardType(label),
//             inputFormatters: FieldInputHelper.getInputFormatters(label),
//             validator: (value) {
//               if(label.contains('Grading System-') || label.contains('Marks-')){
//                 return null;
//               }
//               if (value == null || value.trim().isEmpty) {
//                 return '$label cannot be empty';
//               }
//               return null;
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//
//
//   gradeNMarksUIGraduate(){
//     final currentYear =  DateTime.now().year;
//     final selectedYear =  int.tryParse(_selectedGYear) ?? 1900;
//     if(selectedYear < currentYear){
//       return Column(
//           children: [
//             buildFormField("Grading System-",_gGrade),
//             buildFormField("Marks-",_gMarks)
//           ]
//       );
//     }else{
//       return const SizedBox.shrink();
//     }
//   }
//
//
//   Widget buildTitle(String label){
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 5.0),
//       child: Text(
//         label,
//         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//       ),
//     );
//   }
//
//   Widget buildFormUnderGraField(String label,TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             controller: controller,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(   // 👈 hintText का color control
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//               getIconForField(label),
//                 color: Colors.grey.shade400,
//
//             ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//
//               filled: true,
//               fillColor: Colors.white,
//               // ✅ Light grey border with radius
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: FieldInputHelper.getKeyboardType(label),
//             inputFormatters: FieldInputHelper.getInputFormatters(label),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFormGraduateField(String label,TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             controller: controller,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(   // 👈 hintText का color control
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//                 getIconForField(label),
//                 color: Colors.grey.shade400,
//
//               ),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//
//               filled: true,
//               fillColor: Colors.white,
//               // ✅ Light grey border with radius
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: FieldInputHelper.getKeyboardType(label),
//             inputFormatters: FieldInputHelper.getInputFormatters(label),
//           ),
//         ),
//       ],
//     );
//   }
//
//
//   Widget buildFormFieldPhone(String label) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             enabled: false, // disabled but styled
//             controller: _mobile,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(   // 👈 hintText का color control
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//                 getIconForField(label), // e.g. phone icon
//                 color: Colors.grey.shade400,
//               ),
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//
//               // ✅ Inner white background
//               filled: true,
//               fillColor: Colors.grey.shade200,
//
//               // ✅ Borders
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               disabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: FieldInputHelper.getKeyboardType(label),
//             inputFormatters: FieldInputHelper.getInputFormatters(label),
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) {
//                 return '$label cannot be empty';
//               }
//               return null;
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Widget buildFormFieldPhone(String label,) {
//   //   return Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: [
//   //       buildTitle(label),
//   //       Padding(
//   //         padding: const EdgeInsets.only(bottom: 8.0),
//   //         child: TextFormField(
//   //           enabled: false,
//   //           controller: _mobile,
//   //           style: const TextStyle(fontSize: 14),
//   //           decoration: getInputDecoration(label, getIconForField(label)),
//   //           keyboardType: FieldInputHelper.getKeyboardType(label),
//   //           inputFormatters: FieldInputHelper.getInputFormatters(label),
//   //           validator: (value) {
//   //             if (value == null || value.trim().isEmpty) {
//   //               return '$label cannot be empty';
//   //             }
//   //             return null;
//   //           },
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }
//
//
//   Widget buildFormFieldCalender(String label,BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child:GestureDetector(
//             onTap: () => _selectDate(context),
//             child: AbsorbPointer(
//               child: TextFormField(
//                 controller: _dob,
//                 style: const TextStyle(fontSize: 14),
//                 decoration: InputDecoration(
//                   hintText: label,
//                   hintStyle: TextStyle(   // 👈 hintText का color control
//                     color: Colors.grey.shade500,
//                   ),
//                   prefixIcon: Icon(
//                     getIconForField(label), // e.g. phone icon
//                     color: Colors.grey.shade400,
//                   ),
//                   contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//
//                   // ✅ Inner white background
//                   filled: true,
//                   fillColor: Colors.white,
//
//                   // ✅ Borders
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 keyboardType: FieldInputHelper.getKeyboardType(label),
//                 inputFormatters: FieldInputHelper.getInputFormatters(label),
//                 readOnly: true,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please select your date of birth';
//                   }
//                   // Optionally: validate that the picked date is not in the future
//                   try {
//                     final dob = DateFormat('yyyy-MM-dd').parse(value);
//                     if (dob.isAfter(DateTime.now())) {
//                       return 'Date of birth cannot be in the future';
//                     }
//                   } catch (_) {
//                     return 'Invalid date format';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) {
//                   debugPrint("value-->>");
//                   debugPrint(value);
//                   if (value != null) {
//                     debugPrint(value);
//                     debugPrint(_dob.text);
//                     // _formData['dateOfBirth'] = value;
//                   }
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFormFieldGender(String label, List<Option?>? list) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         DropdownButtonFormField<String>(
//           value: _selectedGender,
//           isExpanded: true,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//             enabledBorder: OutlineInputBorder(
//               borderSide: BorderSide(color: Colors.grey.shade300),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             // focusedBorder: OutlineInputBorder(
//             //   borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
//             //   borderRadius: BorderRadius.circular(10),
//             // ),
//           ),
//           dropdownColor: kBackgroundColor,
//           icon: const Icon(
//             Icons.keyboard_arrow_down,
//             color: Colors.black54,
//           ),
//           items: items.map((String gender) {
//             return DropdownMenuItem(
//               value: gender,
//               child: Text(
//                 gender,
//                 style: const TextStyle(
//                   color: kTextColor,
//                   fontSize: 15,
//                 ),
//               ),
//             );
//           }).toList(),
//           onChanged: (String? newValue) {
//             setState(() {
//               _selectedGender = newValue!;
//             });
//           },
//         ),
//       ],
//     );
//   }
//
//   // Widget buildFormFieldGender(String label,List<Option?>? list) {
//   //   return Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: [
//   //       Padding(
//   //         padding: const EdgeInsets.only(bottom: 5.0),
//   //         child: Text(
//   //           label,
//   //           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//   //         ),
//   //       ),
//   //       Card(
//   //         elevation: 0.1,
//   //         child: Padding(
//   //           padding: const EdgeInsets.symmetric(horizontal: 10),
//   //           child: DropdownButton(
//   //             dropdownColor: kBackgroundColor,
//   //               underline: const SizedBox(),
//   //             // Initial Value
//   //             value: _selectedGender,
//   //             isExpanded: true,
//   //             // Down Arrow Icon
//   //             icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54,
//   //             ),
//   //             // Array list of items
//   //             items: items.map((String items) {
//   //               return DropdownMenuItem(value: items, child: Text(items,style:
//   //               const TextStyle(color: kTextColor, fontSize: 15,),));
//   //             }).toList(),
//   //             // After selecting the desired option,it will
//   //             // change button value to selected value
//   //             onChanged: (String? newValue) {
//   //               setState(() {
//   //                 _selectedGender = newValue!;
//   //               });
//   //             },
//   //           ),
//   //           // DropdownButton(
//   //           //   dropdownColor: kBackgroundColor,
//   //           //   underline: const SizedBox(),
//   //           //   value: _selectedGender.isNotEmpty ? _selectedGender : 'Male',
//   //           //   onChanged: (value) async {
//   //           //     setState(() {
//   //           //       _selectedGender = value.toString();
//   //           //       // _gender.text = _selectedGender;
//   //           //     });
//   //           //
//   //           //   },
//   //           //   isExpanded: true,
//   //           //   items: list?.map((list) {
//   //           //     return DropdownMenuItem<String>(
//   //           //       value: list?.label ?? "",
//   //           //       child: Text(
//   //           //         list?.value ?? "",
//   //           //         style: const TextStyle(
//   //           //           color: kTextColor,
//   //           //           fontSize: 15,
//   //           //         ),
//   //           //       ),
//   //           //     );
//   //           //   }).toList(),
//   //           // ),
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }
//
//   Widget buildFormFieldCountry(String label) {
//     _country.text = _selectedCountry;
//
//     final list = Provider
//         .of<Countries>(context, listen: false)
//         .countryList;
//
//     final filteredList = list.whereType<Country>().toList() ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         Card(
//           elevation: 0.1,
//           child: DropdownSearch<Country>(
//             popupProps: const PopupProps.menu(
//               showSearchBox: true,
//               fit: FlexFit.loose,
//               menuProps: MenuProps(
//                 backgroundColor: kBackgroundColor, // dropdownColor equivalent
//               ),
//               searchFieldProps: TextFieldProps(
//                 decoration: InputDecoration(
//                   hintText: 'Search country...',
//                 ),
//               ),
//             ),
//             items: filteredList,
//             itemAsString: (Country c) => c.name ?? '',
//             dropdownDecoratorProps: DropDownDecoratorProps(
//               dropdownSearchDecoration: InputDecoration(
//                 // filled: true,
//                 // fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder:  OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey.shade400), // On focus
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//             ),
//
//             dropdownButtonProps: const DropdownButtonProps(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.black54,
//               ),
//             ),
//
//             selectedItem: filteredList.firstWhere(
//                   (country) => country.id == _selectedCountry,
//               orElse: () => Country(id: '0', name: 'Select Country'),
//             ),
//             onChanged: (Country? country) {
//               setState(() {
//                 _selectedCountry = country?.id ?? '';
//                 _country.text = _selectedCountry;
//               });
//               callStateListApi(_selectedCountry);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildformLinkedin(String label,TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             controller: controller,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//                 getIconForField(label), // e.g. phone icon
//                 color: Colors.grey.shade400,
//               ),
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//
//               // ✅ Inner white background
//               filled: true,
//               fillColor: Colors.white,
//
//               // ✅ Borders
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: FieldInputHelper.getKeyboardType(label),
//             inputFormatters: FieldInputHelper.getInputFormatters(label),
//           ),
//         ),
//       ],
//     );
//   }
//
//
//   Widget buildformGithub(String label,TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             controller: controller,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(   // 👈 hintText का color control
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//                 getIconForField(label), // e.g. phone icon
//                 color: Colors.grey.shade400,
//               ),
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//
//               // ✅ Inner white background
//               filled: true,
//               fillColor: Colors.white,
//
//               // ✅ Borders
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: FieldInputHelper.getKeyboardType(label),
//             inputFormatters: FieldInputHelper.getInputFormatters(label),
//           ),
//         ),
//       ],
//     );
//   }
//
//
//   Widget buildFormFieldState(String label) {
//
//     final list = Provider
//         .of<Countries>(context, listen: false)
//         .stateList;
//     final filteredList = list.whereType<Country>().toList() ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         Card(
//           elevation: 0.1,
//           child: DropdownSearch<Country>(
//             popupProps: const PopupProps.menu(
//               showSearchBox: true,
//               fit: FlexFit.loose,
//               menuProps: MenuProps(
//                 backgroundColor: kBackgroundColor, // dropdownColor equivalent
//               ),
//               searchFieldProps: TextFieldProps(
//                 decoration: InputDecoration(
//                   hintText: 'Search state...',
//                 ),
//               ),
//             ),
//             items: filteredList,
//             itemAsString: (Country c) => c.name ?? '',
//             dropdownDecoratorProps: DropDownDecoratorProps(
//               dropdownSearchDecoration: InputDecoration(
//                 // filled: true,
//                 // fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder:  OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey.shade300), // On focus
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//             ),
//             // 👇 यह property जोड़नी है
//             dropdownButtonProps: const DropdownButtonProps(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.black54,
//               ),
//             ),
//
//             selectedItem: filteredList.firstWhere(
//                   (country) => country.id == _selectedState,
//               orElse: () => Country(id: '1', name: 'Select State'),
//             ),
//             onChanged: (Country? country) {
//               setState(() {
//                 _selectedState = country?.id ?? '';
//                 _state.text = _selectedState;
//               });
//               callCityListApi(_selectedState);
//             },
//           ),
//         ),
//       ],
//     );
//   }
//   Widget buildFormFieldCity(String label) {
//     final list = Provider
//         .of<Countries>(context, listen: false)
//         .cityList;
//     final filteredList = list.whereType<Country>().toList() ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         Card(
//           elevation: 0.1,
//           child: DropdownSearch<Country>(
//             popupProps: const PopupProps.menu(
//               showSearchBox: true,
//               fit: FlexFit.loose,
//               menuProps: MenuProps(
//                 backgroundColor: kBackgroundColor, // dropdownColor equivalent
//               ),
//               searchFieldProps: TextFieldProps(
//                 decoration: InputDecoration(
//                   hintText: 'Search city...',
//                 ),
//               ),
//             ),
//             items: filteredList,
//             itemAsString: (Country c) => c.name ?? '',
//             dropdownDecoratorProps: DropDownDecoratorProps(
//               dropdownSearchDecoration: InputDecoration(
//                 // filled: true,
//                 // fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // Change this color
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder:  OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey.shade300), // On focus
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//             ),
//             dropdownButtonProps: const DropdownButtonProps(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.black54,
//               ),
//             ),
//             selectedItem: filteredList.firstWhere(
//                   (country) => country.id == _selectedCity,
//               orElse: () => Country(id: '', name: 'Select City'),
//             ),
//             onChanged: (Country? country) {
//               setState(() {
//                 _selectedCity = country?.id ?? '';
//                 _city.text = _selectedCity;
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//
//
//   Widget buildFormPincodeField(String label, TextEditingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         buildTitle(label),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 8.0),
//           child: TextFormField(
//             controller: controller,
//             style: const TextStyle(fontSize: 14),
//             decoration: InputDecoration(
//               hintText: label,
//               hintStyle: TextStyle(   // 👈 hintText का color control
//                 color: Colors.grey.shade500,
//               ),
//               prefixIcon: Icon(
//                 getIconForField(label), // e.g. phone icon
//                 color: Colors.grey.shade400,
//               ),
//               contentPadding:
//               const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
//
//               // ✅ Inner white background
//               filled: true,
//               fillColor: Colors.white,
//
//               // ✅ Borders
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             keyboardType: TextInputType.number,
//             inputFormatters: label == "Pin code"
//                 ? [
//               FilteringTextInputFormatter.digitsOnly,      // sirf numbers
//               LengthLimitingTextInputFormatter(6),         // max 6 digit
//             ]
//                 : FieldInputHelper.getInputFormatters(label),   // baaki fields ka default
//             validator: (value) {
//               if (label == "Pin code") {
//                 if (value == null || value.isEmpty) {
//                   return "Pin code cannot be empty";
//                 } else if (value.length != 6) {
//                   return "Pin code must be exactly 6 digits";
//                 }
//               }
//               return null; // other fields ke liye no error
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildDividerTitle(String label) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const SizedBox(
//           height: 20.0,
//         ),
//         const Divider(
//           height: 10,
//           color: kSecondaryColor,
//         ),
//         Container(
//           padding: const EdgeInsets.only(top: 5.0,bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildInfoTitle(String label) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const SizedBox(height: 20.0),
//         const Text(
//           "Please fill your Under Graduate or Graduate details",
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w400,
//             color: Colors.red,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         Container(
//           padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFormFieldClassX(String label,var list,int index) {
//     final filteredList = list.whereType<Option>().toList() ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         Card(
//           elevation: 0.1,
//           child: DropdownSearch<Option>(
//             popupProps: const PopupProps.menu(
//               showSearchBox: true,
//               fit: FlexFit.loose,
//               menuProps: MenuProps(
//                 backgroundColor: kBackgroundColor, // dropdownColor equivalent
//               ),
//               searchFieldProps: TextFieldProps(
//                 decoration: InputDecoration(
//                   hintText: 'Search field name..',
//                 ),
//               ),
//             ),
//             items: filteredList,
//             itemAsString: (Option c) => c.label ?? '',
//             dropdownDecoratorProps: DropDownDecoratorProps(
//               dropdownSearchDecoration: InputDecoration(
//                 // filled: true,
//                 // fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // Change this color
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder:  OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // On focus
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//             ),
//             dropdownButtonProps: const DropdownButtonProps(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.black54,
//               ),
//             ),
//             selectedItem: filteredList.firstWhere(
//                   (option) => option.value == (index == 0 ? _selectedXBoard : index == 1 ? _selectedXYear : index == 2 ? _selectedXMedium : ''),
//               orElse: () => Option(label: 'Select ', value: 'Select '),
//             ),
//             onChanged: (Option? option) {
//               setState(() {
//                 if(index == 0){
//                   _selectedXBoard = option?.value ?? '';;
//                 }else if(index == 1){
//                   _selectedXYear = option?.value ?? '';;
//                 }else if(index == 2){
//                   _selectedXMedium = option?.value ?? '';;
//                 }
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFormFieldUnderGradu(String label,var list,int index) {
//     final filteredList = list.whereType<Option>().toList() ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         Card(
//           elevation: 0.1,
//           child: DropdownSearch<Option>(
//             popupProps: const PopupProps.menu(
//               showSearchBox: true,
//               fit: FlexFit.loose,
//               menuProps: MenuProps(
//                 backgroundColor: kBackgroundColor, // dropdownColor equivalent
//               ),
//               searchFieldProps: TextFieldProps(
//                 decoration: InputDecoration(
//                   hintText: 'Search field name..',
//                 ),
//               ),
//             ),
//             items: filteredList,
//             itemAsString: (Option c) => c.label ?? '',
//             dropdownDecoratorProps: DropDownDecoratorProps(
//               dropdownSearchDecoration: InputDecoration(
//                 // filled: true,
//                 // fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // Change this color
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder:  OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // On focus
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//             ),
//             dropdownButtonProps: const DropdownButtonProps(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.black54,
//               ),
//             ),
//             selectedItem: filteredList.firstWhere(
//                   (option) => option.value == (index == 0 ? _selectedUGName : index == 1 ? _selectedUGType : index == 2 ? _selectedUGMonth : index == 3 ? _selectedUGYear : ''),
//               orElse: () => Option(label: 'Select ', value: 'Select '),
//             ),
//             onChanged: (Option? option) {
//               setState(() {
//                 if(index == 0){
//                   _selectedUGName = option?.value ?? '';
//                 }else if(index == 1){
//                   _selectedUGType = option?.value ?? '';
//                 }else if(index == 2){
//                   _selectedUGMonth = option?.value ?? '';
//                 }else if(index == 3){
//                   _selectedUGYear = option?.value ?? '';
//                 }
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFormFieldGradu(String label,var list,int index) {
//     final filteredList = list.whereType<Option>().toList() ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         Card(
//           elevation: 0.1,
//           child: DropdownSearch<Option>(
//             popupProps: const PopupProps.menu(
//               showSearchBox: true,
//               fit: FlexFit.loose,
//               menuProps: MenuProps(
//                 backgroundColor: kBackgroundColor, // dropdownColor equivalent
//               ),
//               searchFieldProps: TextFieldProps(
//                 decoration: InputDecoration(
//                   hintText: 'Search field name..',
//                 ),
//               ),
//             ),
//             items: filteredList,
//             itemAsString: (Option c) => c.label ?? '',
//             dropdownDecoratorProps: DropDownDecoratorProps(
//               dropdownSearchDecoration: InputDecoration(
//                 // filled: true,
//                 // fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // Change this color
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder:  OutlineInputBorder(
//                   borderSide:  BorderSide(color: Colors.grey.shade300), // On focus
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//
//             ),
//             dropdownButtonProps: const DropdownButtonProps(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 color: Colors.black54,
//               ),
//             ),
//             selectedItem: filteredList.firstWhere(
//                   (option) => option.value == (index == 0 ? _selectedGName : index == 1 ? _selectedGType : index == 2 ? _selectedGMonth : index == 3 ? _selectedGYear : ''),
//               orElse: () => Option(label: 'Select ', value: 'Select '),
//             ),
//             onChanged: (Option? option) {
//               setState(() {
//                 if(index == 0){
//                   _selectedGName = option?.value ?? '';
//                 }else if(index == 1){
//                   _selectedGType = option?.value ?? '';
//                 }else if(index == 2){
//                   _selectedGMonth = option?.value ?? '';
//                 }else if(index == 3){
//                   _selectedGYear = option?.value ?? '';
//                 }
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFormFieldResume(String label){
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5.0),
//           child: Text(
//             label,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//           ),
//         ),
//         PdfUploadWidget(
//           selectedPdf: _selectedPdf,
//           label: label,
//           onFileSelected: (file) {
//             debugPrint(file?.path.toString());
//             // Save to state, send to API, etc.
//             _selectedPdf = file;
//           },
//         ),
//       ],
//     );
//   }
//
//
//
//
//   // Widget buildFormFieldXMarks(String label,int index,int value) {
//   //   final name = configData.userprofilefields?[index]?.fieldname;
//   //   return Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: [
//   //       Padding(
//   //         padding: const EdgeInsets.only(bottom: 5.0),
//   //         child: Text(
//   //           label,
//   //           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//   //         ),
//   //       ),
//   //       Padding(
//   //         padding: const EdgeInsets.only(bottom: 8.0),
//   //         child: TextFormField(
//   //           controller: _controllers[name],
//   //           style: const TextStyle(fontSize: 14),
//   //           decoration: getInputDecoration(label, getIconForField(label)),
//   //           keyboardType: FieldInputHelper.getKeyboardType(label),
//   //           inputFormatters: FieldInputHelper.getInputFormatters(label),
//   //           validator: (value) {
//   //             if (value == null || value.trim().isEmpty) {
//   //               return '$label cannot be empty';
//   //             }
//   //             return null;
//   //           },
//   //           onSaved: (value){
//   //             boardDetail['$name'] = value ?? '';
//   //             boardControllers.add(boardDetail);
//   //           },
//   //         ),
//   //       ),
//   //     ],
//   //   );
//   // }
//
//
//
//
//   IconData getIconForField(String label) {
//     final key = label.toLowerCase();
//
//     if (key.contains('email')) return Icons.email;
//     if (key.contains('name')) return Icons.person;
//     if (key.contains('phone') || key.contains('mobile')) return Icons.phone;
//     if (key.contains('address')) return Icons.home;
//     if (key.contains('bio') || key.contains('about')) return Icons.info_outline;
//     if (key.contains('twitter')) return MdiIcons.twitter;
//     if (key.contains('facebook')) return MdiIcons.facebook;
//     if (key.contains('linkedin')) return MdiIcons.linkedin;
//     if (key.contains('GitHub Link')) return MdiIcons.github;
//     if (key.contains('date of birth')) return Icons.calendar_today;
//
//     return Icons.text_fields; // default
//   }
//
//   String getTitleForField(String label){
//     final key = label.toLowerCase();
//
//     if (key.contains('class_x')) return "Class X Details";
//     if (key.contains('under_graduate')) return "Under Graduate Details";
//     if (key.contains('graduate')) return "Graduate Details";
//     return "";
//   }
//   bool getBoolForField(String label){
//     final key = label.toLowerCase();
//
//     if (key.contains('class_x')) return true;
//     if (key.contains('under_graduate')) return true;
//     if (key.contains('graduate')) return true;
//     return false;
//   }
//
//
//
//   Future<void> _selectDate(BuildContext context) async {
//       // Close keyboard if open:
//       FocusScope.of(context).unfocus();
//       // If the field already has a value, parse it so the picker opens there:
//       DateTime initialDate = DateTime(1990);
//       if ((_dob.text ?? "").isNotEmpty) {
//         try {
//           initialDate = DateFormat('yyyy-MM-dd').parse(_dob.text ?? "");
//           debugPrint(initialDate.toString());
//         } catch (_) {
//           // ignore parse errors, fallback to 1990
//         }
//       }
//
//       final DateTime? pickedDate = await showDatePicker(
//         context: context,
//         initialDate: initialDate,
//         firstDate: DateTime(1900),
//         lastDate: DateTime.now(),
//         builder: (ctx, child) {
//           return Theme(
//             data: ThemeData.light(),  // force light theme for the dialog
//             child: child!,            // the actual date picker
//           );
//         },
//       );
//
//       if (pickedDate != null) {
//         final formatted = DateFormat('yyyy-MM-dd').format(pickedDate);
//         setState(() {
//           _dob.text = formatted;
//           debugPrint("_controllers-->");
//           debugPrint(_dob.text.toString());
//         });
//       }
//     }
//
//
//     @override
//   void dispose() {
//     _firstname.dispose();
//     _lastname.dispose();
//     _mobile.dispose();
//     _dob.dispose();
//     _gender.dispose();
//     _country.dispose();
//     _state.dispose();
//     _city.dispose();
//     _pincode.dispose();
//     _classXMarks.dispose();
//     _uGcourseName.dispose();
//     _uGSpecailaization.dispose();
//     _uGInstituteName.dispose();
//     _uGMarks.dispose();
//     _uGGrade.dispose();
//     _gCourseName.dispose();
//     _gSpecailaization.dispose();
//     _gGrade.dispose();
//     _gMarks.dispose();
//     _gInstituteName.dispose();
//     _linkedinLink.dispose();
//     _githubLink.dispose();
//     super.dispose();
//   }
//
//   setUserProfileFields(EditProfileResponse user){
//     debugPrint('user.gender');
//     debugPrint(user.gender);
//     _firstname.text =user.firstName ?? '';
//     _lastname.text =user.lastName ?? '';
//     _mobile.text = user.phone ?? '0000000000';
//     _dob.text =user.dateOfBirth ?? '';
//     _selectedGender =user.gender ?? 'Male';
//     _country.text =user.country ?? '';
//     _state.text =user.state ?? '';
//     _city.text =user.city ?? '';
//     _pincode.text =user.pincode ?? '';
//     _classXMarks.text =user.classX?.marks ?? '';
//
//     _uGcourseName.text =user.underGraduate?.courseName ?? '';
//     _uGSpecailaization.text =user.underGraduate?.specializationName ?? '';
//     _uGInstituteName.text =user.underGraduate?.instituteName ?? '';
//     _uGMarks.text =user.underGraduate?.marks ?? '';
//     _uGGrade.text =user.underGraduate?.gradingSystem ?? '';
//
//     _gCourseName.text =user.graduate?.courseName ?? '';
//     _gSpecailaization.text =user.graduate?.specializationName ?? '';
//     _gInstituteName.text =user.graduate?.instituteName ?? '';
//     _gMarks.text =user.graduate?.marks ?? '';
//     _gGrade.text =user.graduate?.gradingSystem ?? '';
//
//     _linkedinLink.text =user.linkedin ?? '';
//     _githubLink.text =user.linkedin ?? '';
//
//     // _selectedGender = user.gender ?? '';
//     _selectedCountry = user.country ?? '';
//     _selectedState = user.state ?? '';
//     _selectedCity = user.city ?? '';
//     //class x
//     _selectedXBoard = user.classX?.boardName ?? '';
//     _selectedXYear = user.classX?.passingYear ?? '';
//     _selectedXMedium = user.classX?.medium ?? '';
//     //class UG
//     _selectedUGName = user.underGraduate?.instituteName ?? '';
//     _selectedUGType = user.underGraduate?.courseType ?? '';
//     _selectedUGMonth = user.underGraduate?.month ?? '';
//     _selectedUGYear = user.underGraduate?.year ?? '';
//     //class G
//     _selectedGName = user.graduate?.instituteName ?? '';
//     _selectedGType = user.graduate?.courseType ?? '';
//     _selectedGMonth = user.graduate?.month ?? '';
//     _selectedGYear = user.graduate?.year ?? '';
//   }
//
//   validate(){
//     if(_selectedCountry == 0){
//       CommonFunctions.showWarningToast('Please select country',);
//       return;
//     }else if(_selectedState == 0){
//       CommonFunctions.showWarningToast('Please select state',);
//       return;
//     }else if(_selectedCity == 0){
//       CommonFunctions.showWarningToast("Please select city");
//       return;
//     }else if(_selectedXBoard == 0){
//       CommonFunctions.showWarningToast("Please select class x board");
//       return;
//     }else if(_selectedXYear == 0){
//       CommonFunctions.showWarningToast("Please select class x passing year");
//       return;
//     }else if(_selectedXMedium == 0){
//       CommonFunctions.showWarningToast("Please select class x medium");
//       return;
//     }else if(_selectedUGName == 0 || _selectedGName == 0){
//       CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data",);
//       return;
//     }else if(_selectedUGType == 0 || _selectedGType == 0){
//       CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data",);
//       return;
//     }else if(_selectedUGMonth == 0 || _selectedGMonth == 0){
//       CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data");
//       return;
//     }else if(_selectedUGYear == 0 || _selectedGYear == 0){
//       CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data",);
//       return;
//     }
//   }
//
// }



// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:academy_app/constants.dart';
import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/models/country.dart';
import 'package:academy_app/models/user.dart';
import 'package:academy_app/providers/auth.dart';
import 'package:academy_app/providers/countries.dart';
import 'package:academy_app/providers/user_profile.dart';
import 'package:academy_app/widgets/app_bar_two.dart';
import 'package:academy_app/widgets/user_image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../Utils/FieldInputHelper.dart';
import '../models/config_data.dart';
import '../models/edit_profile_response.dart';
import '../models/user_profile_update_request.dart';
import '../providers/courses.dart';
import '../providers/shared_pref_helper.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../widgets/pdf_upload_widget.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';
  const EditProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final GlobalKey<FormState> _formKey1 = GlobalKey();
  ConfigData configData = ConfigData();
  bool _isLoading = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  // final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _firstname = TextEditingController();
  final TextEditingController _lastname = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _gender = TextEditingController();
  final TextEditingController _country = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _classXMarks = TextEditingController();
  final TextEditingController _uGcourseName = TextEditingController();
  final TextEditingController _uGSpecailaization = TextEditingController();
  final TextEditingController _uGMarks = TextEditingController();
  final TextEditingController _uGGrade = TextEditingController();
  final TextEditingController _gCourseName = TextEditingController();
  final TextEditingController _gSpecailaization = TextEditingController();
  final TextEditingController _gMarks = TextEditingController();
  final TextEditingController _gGrade = TextEditingController();
  final TextEditingController _linkedinLink = TextEditingController();
  final TextEditingController _githubLink = TextEditingController();
  final TextEditingController _uGInstituteName = TextEditingController();
  final TextEditingController _gInstituteName = TextEditingController();


  String _selectedGender = 'Male';
  String _selectedCountry = '101';
  String _selectedState = '0';
  String _selectedCity = '0';
  //class x
  String _selectedXBoard = '';
  String _selectedXYear = '';
  String _selectedXMedium = '';
  //class UG
  String _selectedUGName = '';
  String _selectedUGType = '';
  String _selectedUGMonth = '';
  String _selectedUGYear = '';
  //class G
  String _selectedGName = '';
  String _selectedGType = '';
  String _selectedGMonth = '';
  String _selectedGYear = '';
  File? _selectedPdf;
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB
  var _isInit = true;
  List<BoardDetail> boardDetailsList = [];
  List<EducationDetail> boardunGDetailsList = [];
  final List<Map<String, String>> boardControllers = [];
  final List<Map<String, String>> boardUnGControllers = [];
  Map<String, String> boardDetail = {};
  Map<String, String> unGDetail = {};
  List<Option> yearOptions = [];
  List<Option> listBoardClass = [];
  List<Option> listBoardMedium = [];
  List<Option> listuGInstitute = [];
  List<Option> listuGCourseType = [];
  List<Option> listMonths = [];

  String? _selectedUGGradingSystem;
  String? _selectedGrGradingSystem;

  // List of items in our dropdown menu
  var items = [
    'Male',
    'Female',
  ];



  // bool isCompleteUGFilled() {
  //   final enteredMarksStr = _uGMarks.text.trim();
  //   final selectedGrading = _selectedUGGradingSystem;
  //
  //   // ❌ Validate empty fields
  //   if (selectedGrading == null || selectedGrading.trim().isEmpty || selectedGrading == 'Select') {
  //     CommonFunctions.showWarningToast("Please select UG grading system.");
  //     return false;
  //   }
  //
  //   if (enteredMarksStr.isEmpty) {
  //     CommonFunctions.showWarningToast("Please enter UG marks.");
  //     return false;
  //   }
  //
  //   final enteredMarks = double.tryParse(enteredMarksStr);
  //   if (enteredMarks == null) {
  //     CommonFunctions.showWarningToast("Invalid UG marks.");
  //     return false;
  //   }
  //
  //   // ❌ Validate limits
  //   if (selectedGrading == 'gpa_out_of_4' && enteredMarks > 4) {
  //     CommonFunctions.showWarningToast("UG marks must be 4 or less (GPA out of 4 selected).");
  //     return false;
  //   }
  //   if (selectedGrading == 'gpa_out_of_10' && enteredMarks > 10) {
  //     CommonFunctions.showWarningToast("UG marks must be 10 or less (GPA out of 10 selected).");
  //     return false;
  //   }
  //   if (selectedGrading == 'percentage' && enteredMarks > 100) {
  //     CommonFunctions.showWarningToast("UG marks must be 100 or less (Percentage selected).");
  //     return false;
  //   }
  //
  //   // ✅ Other required fields
  //   if (_uGInstituteName.text.trim().isEmpty ||
  //       _uGcourseName.text.trim().isEmpty ||
  //       _uGSpecailaization.text.trim().isEmpty ||
  //       _selectedUGType == null || _selectedUGType == '' ||
  //       _selectedUGMonth == null || _selectedUGMonth == '' ||
  //       _selectedUGYear == null || _selectedUGYear == '') {
  //     CommonFunctions.showWarningToast("Please complete all required UG fields.");
  //     return false;
  //   }
  //
  //   return true;
  // }

  bool isCompleteUGFilled() {
    final currentDate = DateTime.now();
    final currentYear = currentDate.year;
    final currentMonth = currentDate.month;

    final selectedYear = int.tryParse(_selectedUGYear ?? '') ?? 0;
    final selectedMonthIndex = _getMonthIndex(_selectedUGMonth);

    final isPast = selectedYear < currentYear ||
        (selectedYear == currentYear && selectedMonthIndex < currentMonth);

    // ✅ Basic mandatory fields
    if (_uGInstituteName.text.trim().isEmpty ||
        _uGcourseName.text.trim().isEmpty ||
        _uGSpecailaization.text.trim().isEmpty ||
        _selectedUGType == null || _selectedUGType!.isEmpty || _selectedUGType == 'Select' ||
        _selectedUGMonth == null || _selectedUGMonth!.isEmpty || _selectedUGMonth == 'Select' ||
        _selectedUGYear == null || _selectedUGYear!.isEmpty || _selectedUGYear == 'Select') {
      CommonFunctions.showWarningToast("Please complete all required UG fields.");
      return false;
    }

    // ✅ If past → grading + marks required
    if (isPast) {
      if (_selectedUGGradingSystem == null ||
          _selectedUGGradingSystem!.trim().isEmpty ||
          _selectedUGGradingSystem == 'Select') {
        CommonFunctions.showWarningToast("Please select UG grading system.");
        return false;
      }

      if (_uGMarks.text.trim().isEmpty) {
        CommonFunctions.showWarningToast("Please enter UG marks.");
        return false;
      }

      final enteredMarks = double.tryParse(_uGMarks.text.trim());
      if (enteredMarks == null) {
        CommonFunctions.showWarningToast("Invalid UG marks.");
        return false;
      }

      if (_selectedUGGradingSystem == 'gpa_out_of_4' && enteredMarks > 4) {
        CommonFunctions.showWarningToast("UG marks must be 4 or less (GPA out of 4 selected).");
        return false;
      }
      if (_selectedUGGradingSystem == 'gpa_out_of_10' && enteredMarks > 10) {
        CommonFunctions.showWarningToast("UG marks must be 10 or less (GPA out of 10 selected).");
        return false;
      }
      if (_selectedUGGradingSystem == 'percentage' && enteredMarks > 100) {
        CommonFunctions.showWarningToast("UG marks must be 100 or less (Percentage selected).");
        return false;
      }
    }

    return true;
  }

  bool isCompleteGraduateFilled() {
    final currentDate = DateTime.now();
    final currentYear = currentDate.year;
    final currentMonth = currentDate.month;

    final selectedYear = int.tryParse(_selectedGYear ?? '') ?? 0;
    final selectedMonthIndex = _getMonthIndex(_selectedGMonth);

    final isPast = selectedYear < currentYear ||
        (selectedYear == currentYear && selectedMonthIndex < currentMonth);

    // ✅ Basic mandatory fields
    if (_gInstituteName.text.trim().isEmpty ||
        _gCourseName.text.trim().isEmpty ||
        _gSpecailaization.text.trim().isEmpty ||
        _selectedGType == null || _selectedGType!.isEmpty || _selectedGType == 'Select' ||
        _selectedGMonth == null || _selectedGMonth!.isEmpty || _selectedGMonth == 'Select' ||
        _selectedGYear == null || _selectedGYear!.isEmpty || _selectedGYear == 'Select') {
      CommonFunctions.showWarningToast("Please complete all required Graduate fields.");
      return false;
    }

    // ✅ If past → grading + marks required
    if (isPast) {
      if (_selectedGrGradingSystem == null ||
          _selectedGrGradingSystem!.trim().isEmpty ||
          _selectedGrGradingSystem == 'Select') {
        CommonFunctions.showWarningToast("Please select Graduate grading system.");
        return false;
      }

      if (_gMarks.text.trim().isEmpty) {
        CommonFunctions.showWarningToast("Please enter Graduate marks.");
        return false;
      }

      final enteredMarks = double.tryParse(_gMarks.text.trim());
      if (enteredMarks == null) {
        CommonFunctions.showWarningToast("Invalid Graduate marks.");
        return false;
      }

      if (_selectedGrGradingSystem == 'gpa_out_of_4' && enteredMarks > 4) {
        CommonFunctions.showWarningToast("Graduate marks must be 4 or less (GPA out of 4 selected).");
        return false;
      }
      if (_selectedGrGradingSystem == 'gpa_out_of_10' && enteredMarks > 10) {
        CommonFunctions.showWarningToast("Graduate marks must be 10 or less (GPA out of 10 selected).");
        return false;
      }
      if (_selectedGrGradingSystem == 'percentage' && enteredMarks > 100) {
        CommonFunctions.showWarningToast("Graduate marks must be 100 or less (Percentage selected).");
        return false;
      }
    }

    return true;
  }


  // bool isCompleteGraduateFilled() {
  //   final enteredMarks = double.tryParse(_gMarks.text.trim());
  //
  //   if (_selectedGrGradingSystem == null ||
  //       _selectedGrGradingSystem!.trim().isEmpty ||
  //       _selectedGrGradingSystem == 'Select') {
  //     CommonFunctions.showWarningToast("Please select Graduate grading system.");
  //     return false;
  //   }
  //
  //   if (_gMarks.text.trim().isEmpty) {
  //     CommonFunctions.showWarningToast("Please enter Graduate marks.");
  //     return false;
  //   }
  //
  //   if (enteredMarks != null) {
  //     if (_selectedGrGradingSystem == 'gpa_out_of_4' && enteredMarks > 4) {
  //       CommonFunctions.showWarningToast("Graduate marks must be 4 or less (GPA out of 4 selected).");
  //       return false;
  //     }
  //     if (_selectedGrGradingSystem == 'gpa_out_of_10' && enteredMarks > 10) {
  //       CommonFunctions.showWarningToast("Graduate marks must be 10 or less (GPA out of 10 selected).");
  //       return false;
  //     }
  //     if (_selectedGrGradingSystem == 'percentage' && enteredMarks > 100) {
  //       CommonFunctions.showWarningToast("Graduate marks must be 100 or less (Percentage selected).");
  //       return false;
  //     }
  //   }
  //
  //   if (_gInstituteName.text.trim().isEmpty ||
  //       _gCourseName.text.trim().isEmpty ||
  //       _gSpecailaization.text.trim().isEmpty ||
  //       _selectedGType == null || _selectedGType == '' ||
  //       _selectedGMonth == null || _selectedGMonth == '' ||
  //       _selectedGYear == null || _selectedGYear == '') {
  //     CommonFunctions.showWarningToast("Please complete all required Graduate fields.");
  //     return false;
  //   }
  //
  //   return true;
  // }


  bool _anyUGFieldFilled() {
    final currentYear = DateTime.now().year;
    final selectedYear = int.tryParse(_selectedUGYear ?? '');
    final isYearBeforeCurrent = selectedYear != null && selectedYear < currentYear;

    final hasAnyMarks = _uGMarks.text.trim().isNotEmpty ||
        (_selectedUGGradingSystem != null &&
            _selectedUGGradingSystem!.trim().isNotEmpty &&
            _selectedUGGradingSystem != 'Select');

    return _uGInstituteName.text.trim().isNotEmpty ||
        _uGcourseName.text.trim().isNotEmpty ||
        _uGSpecailaization.text.trim().isNotEmpty ||
        (_selectedUGType != null && _selectedUGType!.trim().isNotEmpty && _selectedUGType != 'Select') ||
        (_selectedUGMonth != null && _selectedUGMonth!.trim().isNotEmpty && _selectedUGMonth != 'Select') ||
        (_selectedUGYear != null && _selectedUGYear!.trim().isNotEmpty && _selectedUGYear != 'Select') ||
        (isYearBeforeCurrent && hasAnyMarks);
  }


  bool _anyGraduateFieldFilled() {
    final currentYear = DateTime
        .now()
        .year;
    final selectedYear = int.tryParse(_selectedGYear ?? '');
    final isYearBeforeCurrent = selectedYear != null &&
        selectedYear < currentYear;

    final hasAnyMarks = _gMarks.text
        .trim()
        .isNotEmpty ||
        (_selectedGrGradingSystem != null &&
            _selectedGrGradingSystem!.trim().isNotEmpty &&
            _selectedGrGradingSystem != 'Select');

    return _gInstituteName.text
        .trim()
        .isNotEmpty ||
        _gCourseName.text
            .trim()
            .isNotEmpty ||
        _gSpecailaization.text
            .trim()
            .isNotEmpty ||
        (_selectedGType != null && _selectedGType!.trim().isNotEmpty &&
            _selectedGType != 'Select') ||
        (_selectedGMonth != null && _selectedGMonth!.trim().isNotEmpty &&
            _selectedGMonth != 'Select') ||
        (_selectedGYear != null && _selectedGYear!.trim().isNotEmpty &&
            _selectedGYear != 'Select') ||
        (isYearBeforeCurrent && hasAnyMarks);
  }

  // @override
  // void initState() {
  //   super.initState();
  //   getConfigData();
  //   Provider.of<UserProfile>(context, listen: false).getUserProfileDetails().then((_) async {
  //     final userdata = Provider.of<UserProfile>(context, listen: false).editProfileResponse;
  //     await setUserProfileFields(userdata);
  //   });
  //   Future.delayed(const Duration(seconds: 2), () {
  //     debugPrint('called-->fetchCityList');
  //     Provider.of<Countries>(context,listen: false).fetchCityList(_selectedState);
  //   });
  //
  // }



  @override
  void initState() {
    super.initState();
    getConfigData();

    // Step 1: Get profile first
    Provider.of<UserProfile>(context, listen: false).getUserProfileDetails().then((_) async {
      final userdata = Provider.of<UserProfile>(context, listen: false).editProfileResponse;

      // Step 2: Fetch city list based on state from profile
      await Provider.of<Countries>(context, listen: false).fetchCityList(userdata.state ?? '');

      // Step 3: Now assign profile fields
      await setUserProfileFields(userdata);
    });
  }




  Future<void> getConfigData() async {
    dynamic data = await SharedPreferenceHelper().getConfigData();
    if (data != null) {
      final decodedData = ConfigData.fromJson(json.decode(data));
      setState(() {
        configData = decodedData;
      });
    }

    const int startYear = 1900;
    final int endYear = DateTime.now().year+10;

    yearOptions = [
      for (var y = endYear; y >= startYear; y--)
        Option(label: y.toString(), value: y.toString()),
    ];

    listBoardClass = List<Option>.from(configData.userprofilefields?[13]?.options ?? []);
    listBoardMedium = List<Option>.from(configData.userprofilefields?[16]?.options ?? []);
    listuGCourseType = List<Option>.from(configData.userprofilefields?[19]?.options ?? []);
    listMonths = List<Option>.from(configData.userprofilefields?[22]?.options ?? []);
    listuGInstitute = List<Option>.from(configData.userprofilefields?[22]?.options ?? []);

  }
  callStateListApi(var id){
    setState(() {
      _isLoading = true;
    });
    Provider.of<Countries>(context,listen: false).fetchStateList(id)
        .then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }
  callCityListApi(var id){
    setState(() {
      _isLoading = true;
    });
    Provider.of<Countries>(context,listen: false).fetchCityList(id)
        .then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }
  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      Provider.of<Countries>(context).fetchCountryList()
          .then((_) {
        setState(() {
          _isLoading = false;
        });
      });
      callStateListApi(_selectedCountry);
      callCityListApi(_selectedState);
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> _submit() async {
    if (!_anyUGFieldFilled() && !_anyGraduateFieldFilled()) {
      CommonFunctions.showWarningToast("Please fill either UG or Graduate details.");
      return;
    }

    // if (_anyUGFieldFilled() && !isCompleteUGFilled()) {
    //   CommonFunctions.showWarningToast("Please complete all required UG fields.");
    //   return;
    // }
    // if (_anyGraduateFieldFilled() && !isCompleteGraduateFilled()) {
    //   CommonFunctions.showWarningToast("Please complete all required Graduate fields.");
    //   return;
    // }

    if (_anyUGFieldFilled()) {
      bool isUGValid = isCompleteUGFilled();
      if (!isUGValid) return; // Show toast inside the function only
    }

    if (_anyGraduateFieldFilled()) {
      bool isGraduateValid = isCompleteGraduateFilled();
      if (!isGraduateValid) return; // Show toast inside the function only
    }


    if (!_formKey.currentState!.validate()) {
      CommonFunctions.showWarningToast('Request Failed.. Field can not be empty');
      return;
    }

    setState(() => _isLoading = true);
    final token = await SharedPreferenceHelper().getAuthToken();

    final xMarks = double.tryParse(_classXMarks.text.trim());

    if (xMarks != null && xMarks > 100) {
      CommonFunctions.showWarningToast("Class 10 marks cannot be more than 100.");
      setState(() => _isLoading = false); // stop loading
      return;
    }

    // Step 1: Class X
    boardDetailsList.clear();
    boardDetailsList.add(BoardDetail(
      boardType: '1',
      board: _selectedXBoard,
      boardMarks: _classXMarks.text.trim(),
      boardYear: _selectedXYear,
      medium: _selectedXMedium,
    ));

    // Step 2: UG + Graduate
    boardunGDetailsList.clear();

    if (_anyUGFieldFilled()) {
      boardunGDetailsList.add(EducationDetail(
        index: 3,
        educationType: "3",
        instituteName: _selectedUGName.isNotEmpty
            ? _selectedUGName
            : _uGInstituteName.text.trim(), // ✅ fallback to text
        courseName: _uGcourseName.text.trim(),
        courseType: _selectedUGType,
        specializationName: _uGSpecailaization.text.trim(),
        month: _selectedUGMonth,
        year: _selectedUGYear,
        gradingSystem: _selectedUGGradingSystem,
        marks: _uGMarks.text.trim(),
      ));
    }

    if (_anyGraduateFieldFilled()) {
      boardunGDetailsList.add(EducationDetail(
        index: 4,
        educationType: "4",
        instituteName: _selectedGName.isNotEmpty
            ? _selectedGName
            : _gInstituteName.text.trim(),
        courseName: _gCourseName.text.trim(),
        courseType: _selectedGType,
        specializationName: _gSpecailaization.text.trim(),
        month: _selectedGMonth,
        year: _selectedGYear,
        gradingSystem: _selectedGrGradingSystem,
        marks: _gMarks.text.trim(),
      ));
    }

    // Step 3: Request
    final request = UserProfileUpdateRequest(
      authToken: token ?? '',
      firstName: _firstname.text.trim(),
      lastName: _lastname.text.trim(),
      dateOfBirth: _dob.text.trim(),
      gender: _selectedGender,
      country: _country.text.trim(),
      state: _state.text.trim(),
      city: _city.text.trim(),
      pincode: _pincode.text.trim(),
      linkedinLink: _linkedinLink.text.trim(),
      githubLink: _githubLink.text.trim(),
      boardDetails: boardDetailsList,
      educationDetails: boardunGDetailsList,
    );

    print("=== API Request ===");
    print(request.toFormData());

    await Provider.of<Auth>(context, listen: false).uploadUserProfileWithResume(
      userMap: request,
      resumeFile: File(_selectedPdf?.path ?? ""),
    );

    // Step 4: Refresh UI
    await Provider.of<UserProfile>(context, listen: false).getUserProfileDetails();
    final updatedUser = Provider.of<UserProfile>(context, listen: false).editProfileResponse;
    setUserProfileFields(updatedUser);

    setState(() => _isLoading = false);
  }

  // Future<void> _submit() async {
  //   if (!_anyUGFieldFilled() && !_anyGraduateFieldFilled()) {
  //     CommonFunctions.showWarningToast("Please fill either UG or Graduate details.");
  //     return;
  //   }
  //
  //   //  Step 1: Check UG or Graduate filled
  //   if (_anyUGFieldFilled() && !isCompleteUGFilled()) {
  //     CommonFunctions.showWarningToast("Please complete all required UG fields.");
  //     return;
  //   }
  //   if (_anyGraduateFieldFilled() && !isCompleteGraduateFilled()) {
  //     CommonFunctions.showWarningToast("Please complete all required Graduate fields.");
  //     return;
  //   }
  //
  //
  //
  //   //  Step 2: Validate form fields
  //   if (!_formKey.currentState!.validate()) {
  //     CommonFunctions.showWarningToast('Request Failed.. Field can not be empty');
  //     return;
  //   }
  //
  //   _formKey.currentState!.save();
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   final token = await SharedPreferenceHelper().getAuthToken();
  //
  //   //  Step 3: Class X Board Detail
  //   // boardDetailsList.clear();
  //   final detail = BoardDetail(
  //     boardType: '1' ?? "",
  //     board: _selectedXBoard ?? "",
  //     boardMarks: _classXMarks.text ?? "",
  //     boardYear: _selectedXYear ?? "",
  //     medium: _selectedXMedium ?? "",
  //   );
  //   boardDetailsList.add(detail);
  //   //debugPrint(boardDetailsList.toString());
  //
  //   //  Step 4: UG Details
  //   final uGDetails = EducationDetail(
  //     index: 3,
  //     educationType: "3",
  //     instituteName: _selectedUGName ?? '',
  //     courseName: _uGcourseName.text.trim(),
  //     courseType: _selectedUGType ?? '',
  //     specializationName: _uGSpecailaization.text.trim(),
  //     month: _selectedUGMonth ?? '',
  //     year: _selectedUGYear ?? '',
  //     gradingSystem: _uGGrade.text.trim(),
  //     marks: _uGMarks.text.trim(),
  //   );
  //
  //   boardunGDetailsList.add(uGDetails);
  //
  //   //  Step 5: G Details
  //   final gDetails = EducationDetail(
  //     index: 4,
  //     educationType: "4",
  //     instituteName: _selectedGName ?? '',
  //     courseName: _gCourseName.text.trim(),
  //     courseType: _selectedGType ?? '',
  //     specializationName: _gSpecailaization.text.trim(),
  //     month: _selectedGMonth ?? '',
  //     year: _selectedGYear ?? '',
  //     gradingSystem: _gGrade.text.trim(),
  //     marks: _gMarks.text.trim(),
  //   );
  //
  //   // boardunGDetailsList.clear();
  //   boardunGDetailsList.add(gDetails);
  //
  //   //  Step 6: Build request
  //   final request = UserProfileUpdateRequest(
  //     authToken: token ?? '',
  //     firstName: _firstname.text.trim(),
  //     lastName: _lastname.text.trim(),
  //     dateOfBirth: _dob.text.trim(),
  //     gender: _selectedGender ?? '',
  //     country: _country.text.trim(),
  //     state: _state.text.trim(),
  //     city: _city.text.trim(),
  //     pincode: _pincode.text.trim(),
  //     linkedinLink: _linkedinLink.text.trim(),
  //     githubLink: _githubLink.text.trim(),
  //     boardDetails: boardDetailsList,
  //     educationDetails: boardunGDetailsList,
  //   );
  //
  //   // Step 7: Upload request with resume
  //   print("request.toString()");
  //   print(request.toFormData());
  //
  //   await Provider.of<Auth>(context, listen: false).uploadUserProfileWithResume(
  //     userMap: request,
  //     resumeFile: File(_selectedPdf?.path ?? ""),
  //   );
  //
  //
  //
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }


  InputDecoration getInputDecoration(String hintext, IconData iconData) {
    return InputDecoration(
      border: InputBorder.none,
      enabledBorder: kDefaultInputBorder,
      focusedBorder: kDefaultFocusInputBorder,
      focusedErrorBorder: kDefaultFocusErrorBorder,
      errorBorder: kDefaultFocusErrorBorder,
      filled: true,
      hintStyle: const TextStyle(color: kFormInputColor),
      hintText: hintext,
      fillColor: Colors.white70,
      prefixIcon: Icon(
        iconData,
        color: kFormInputColor,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarTwo(),
      backgroundColor: kBackgroundColor,
      body: FutureBuilder(
        future: Provider.of<UserProfile>(context, listen: false).getUserProfileDetails(),
        builder: (ctx, dataSnapshot) {
          if (dataSnapshot.error != null) {
            return const Center(
              child: Text('Error Occured'),
            );
          } else {
            return Consumer<UserProfile>(
              builder: (context, authData, child) {
                final user = authData.editProfileResponse;
                // setUserProfileFields(user);
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding:
                        EdgeInsets.only(left: 15, top: 10, bottom: 5.0),
                        child: Text(
                          'Update Profile Picture',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child:user.image != null ? UserImagePicker(
                          image: user.image,
                        ) : SizedBox.shrink(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildUI(context),
                                const SizedBox(
                                  height: 15,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : MaterialButton(
                                    onPressed: _submit,
                                    color: kRedColor,
                                    textColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                    splashColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(7.0),
                                      side: const BorderSide(
                                          color: kRedColor),
                                    ),
                                    child: const Text(
                                      'Update Now',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          // if (dataSnapshot.connectionState == ConnectionState.waiting) {
          //   return Center(
          //     child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
          //   );
          // } else {
          //
          // }
        },
      ),
    );
  }

  Widget buildUI(BuildContext context){
    debugPrint(configData.userprofilefields?[4]?.options.toString());
    dynamic list = configData.userprofilefields?[4]?.options;
    return  Column(
      children: [
        buildFormField("First Name",_firstname),
        buildFormField("Last Name",_lastname),
        buildFormFieldPhone("Mobile"),
        buildFormFieldCalender("Date of birth",context),
        buildFormFieldGender("Gender",list ?? []),
        buildFormFieldCountry("Country"),
        buildFormFieldState("State"),
        buildFormFieldCity("City"),
        buildFormPincodeField("Pin code",_pincode),
        // buildDividerTitle("Class X Details"),
        // buildFormFieldClassX("Board Name",listBoardClass,0),
        // buildFormField("Your Marks",_classXMarks),
        // buildFormFieldClassX("Year of passing",yearOptions,1),
        // buildFormFieldClassX("Medium",listBoardMedium,2),
        buildDividerTitle("Under Graduate Details"),
        buildGradField("College / Institute Name",_uGInstituteName),
        buildFormFieldUnderGradu("Course Type",listuGCourseType,1),
        buildGradField("Course Name",_uGcourseName),
        buildGradField("Specialization",_uGSpecailaization),
        buildFormFieldUnderGradu("Month of passing",listMonths,2),
        buildFormFieldUnderGradu("Year of passing",yearOptions,3),
        gradeNMarksUIUG(),
        buildInstruction("Graduate Details"),
        buildGradField("College / Institute Name",_gInstituteName),
        buildFormFieldGradu("Course Type",listuGCourseType,1),
        buildGradField("Course Name",_gCourseName),
        buildGradField("Specialization",_gSpecailaization),
        buildFormFieldGradu("Month of passing",listMonths,2),
        buildFormFieldGradu("Year of passing",yearOptions,3),
        gradeNMarksUIGraduate(),
        buildlinkDeatils("Linkedin link",_linkedinLink),
        buildlinkDeatils("Github link",_githubLink),
        buildFormFieldResume("Upload CV")
      ],
    );
  }

  // gradeNMarksUIUG(){
  //  final currentYear =  DateTime.now().year;
  //  final selectedYear =  int.tryParse(_selectedUGYear) ?? 1900;
  //   if(selectedYear < currentYear){
  //    return Column(
  //      children: [
  //        buildUGGradingSystemDropdown(),
  //        buildFormField("Marks",_uGMarks)
  //      ]
  //    );
  //   }else{
  //     return const SizedBox.shrink();
  //   }
  // }


  Widget gradeNMarksUIUG() {
    final currentDate = DateTime.now();
    final currentYear = currentDate.year;
    final currentMonth = currentDate.month;

    final selectedYear = int.tryParse(_selectedUGYear) ?? 0;
    final selectedMonthIndex = _getMonthIndex(_selectedUGMonth);

    print("Selected Year: $selectedYear");
    print("Selected Month Index: $selectedMonthIndex");
    print("Current Year: $currentYear");
    print("Current Month: $currentMonth");

    if (selectedYear < currentYear ||
        (selectedYear == currentYear && selectedMonthIndex < currentMonth)) {
      return Column(
        children: [
          buildUGGradingSystemDropdown(),
          buildFormField("Marks", _uGMarks),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  int _getMonthIndex(String? month) {
    if (month == null || month.trim().isEmpty) return -1;

    try {
      // ✅ Parse short month name like "Aug", "Jul", "Jan"
      final date = DateFormat.MMM().parseStrict(month.trim());
      return date.month; // returns 1-12
    } catch (e) {
      print('Error parsing month: $month');
      return -1;
    }
  }



  // Grading system method



  Widget buildUGGradingSystemDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Grading System",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),

          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xffD3D3D3), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white, // dropdown background
            ),
            child: DropdownButtonFormField<String>(
                value: (_selectedUGGradingSystem != null && _selectedUGGradingSystem!.isNotEmpty)
                    ? _selectedUGGradingSystem
                    : null,
                isExpanded: true,
                alignment: AlignmentDirectional.centerStart,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.arrow_drop_down_sharp, color: Colors.black),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  // contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                ),
                hint: const Text("Select Grade", style: TextStyle(color: Colors.black, fontSize: 14)),
                items: const [
                  DropdownMenuItem(value: 'gpa_out_of_10', child: Text("GPA out of 10")),
                  DropdownMenuItem(value: 'gpa_out_of_4', child: Text("GPA out of 4")),
                  DropdownMenuItem(value: 'percentage', child: Text("Percentage")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUGGradingSystem = value;
                  });
                }

            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // gradeNMarksUIGraduate(){
  //   final currentYear =  DateTime.now().year;
  //   final selectedYear =  int.tryParse(_selectedGYear) ?? 1900;
  //   if(selectedYear < currentYear){
  //     return Column(
  //         children: [
  //           buildGGradingSystemDropdown(),
  //           buildFormField("Marks",_gMarks)
  //         ]
  //     );
  //   }else{
  //     return const SizedBox.shrink();
  //   }
  // }

  Widget gradeNMarksUIGraduate() {
    final currentDate = DateTime.now();
    final currentYear = currentDate.year;
    final currentMonth = currentDate.month;

    final selectedYear = int.tryParse(_selectedGYear) ?? 0;
    final selectedMonthIndex = _getMonthIndex(_selectedGMonth);

    print("Graduate Selected Year: $selectedYear");
    print("Graduate Selected Month Index: $selectedMonthIndex");
    print("Current Year: $currentYear");
    print("Current Month: $currentMonth");

    if (selectedYear < currentYear ||
        (selectedYear == currentYear && selectedMonthIndex < currentMonth)) {
      return Column(
        children: [
          buildGGradingSystemDropdown(),
          buildFormField("Marks", _gMarks),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }



  Widget buildGGradingSystemDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Grading System",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),

          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xffD3D3D3), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white, // dropdown background
            ),
            child: DropdownButtonFormField<String>(
                value: (_selectedGrGradingSystem != null && _selectedGrGradingSystem!.isNotEmpty)
                    ? _selectedGrGradingSystem
                    : null,
                isExpanded: true,
                alignment: AlignmentDirectional.centerStart,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.arrow_drop_down_sharp, color: Colors.black),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  // contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                ),
                hint: const Text("Select Grade", style: TextStyle(color: Colors.black, fontSize: 14)),
                items: const [
                  DropdownMenuItem(value: 'gpa_out_of_10', child: Text("GPA out of 10")),
                  DropdownMenuItem(value: 'gpa_out_of_4', child: Text("GPA out of 4")),
                  DropdownMenuItem(value: 'percentage', child: Text("Percentage")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGrGradingSystem = value;
                  });
                }

            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  Widget buildTitle(String label){
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
    );
  }

  // new

  Widget buildGradField(String label,TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(label),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)).copyWith(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFD3D3D3),width: 1, // thin border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color:Color(0xFFD3D3D3),width: 1, // thin border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),            keyboardType: FieldInputHelper.getKeyboardType(label),
            inputFormatters: FieldInputHelper.getInputFormatters(label),
          ),
        ),
      ],
    );
  }



  Widget buildFormField(String label,TextEditingController controller,{String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(label),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)).copyWith(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFD3D3D3),width: 1, // thin border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color:Color(0xFFD3D3D3),width: 1, // thin border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: FieldInputHelper.getKeyboardType(label),
            inputFormatters: FieldInputHelper.getInputFormatters(label),
            validator: (value) {
              if(label.contains('Grading System') || label.contains('Marks')){
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return '$label cannot be empty';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }


  Widget buildFormFieldPhone(String label,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(label),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            enabled: false,
            controller: _mobile,
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(
              label,
              getIconForField(label),

            ).copyWith(
              fillColor: Colors.grey.shade200, // Ensure background is white
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              border: OutlineInputBorder(
                borderSide:  BorderSide(color: Colors.grey.shade200, width: 1), // lighter border
                borderRadius: BorderRadius.circular(10),
              ),

            ),


            keyboardType: FieldInputHelper.getKeyboardType(label),
            inputFormatters: FieldInputHelper.getInputFormatters(label),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label cannot be empty';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget buildFormFieldCalender(String label,BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(label),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child:GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dob,
                style: const TextStyle(fontSize: 14),
                decoration: getInputDecoration(label, getIconForField(label)).copyWith(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFD3D3D3),width: 1, // thin border
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFD3D3D3),width: 1, // thin border
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),                 keyboardType: FieldInputHelper.getKeyboardType(label),
                inputFormatters: FieldInputHelper.getInputFormatters(label),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your date of birth';
                  }
                  // Optionally: validate that the picked date is not in the future
                  try {
                    final dob = DateFormat('yyyy-MM-dd').parse(value);
                    if (dob.isAfter(DateTime.now())) {
                      return 'Date of birth cannot be in the future';
                    }
                  } catch (_) {
                    return 'Invalid date format';
                  }
                  return null;
                },
                onSaved: (value) {
                  debugPrint("value-->>");
                  debugPrint(value);
                  if (value != null) {
                    debugPrint(value);
                    debugPrint(_dob.text);
                    // _formData['dateOfBirth'] = value;
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget buildFormFieldGender(String label,List<Option?>? list) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 5.0),
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //         ),
  //       ),
  //       Card(
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 10),
  //           child: DropdownButton(
  //             dropdownColor: kBackgroundColor,
  //               underline: const SizedBox(),
  //             // Initial Value
  //             value: _selectedGender,
  //             isExpanded: true,
  //             // Down Arrow Icon
  //             icon: const Icon(Icons.keyboard_arrow_down),
  //             // Array list of items
  //             items: items.map((String items) {
  //               return DropdownMenuItem(value: items, child: Text(items,style:
  //               const TextStyle(color: kTextColor, fontSize: 15,),));
  //             }).toList(),
  //             // After selecting the desired option,it will
  //             // change button value to selected value
  //             onChanged: (String? newValue) {
  //               setState(() {
  //                 _selectedGender = newValue!;
  //               });
  //             },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget buildFormFieldGender(String label, List<Option?>? list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Fill color white
            border: Border.all(color: Color(0xFFD3D3D3), width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButton(
            dropdownColor: kBackgroundColor,
            underline: const SizedBox(),
            value: _selectedGender,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down_sharp,color: Colors.black,),
            items: items.map((String items) {
              return DropdownMenuItem(
                value: items,
                child: Text(
                  items,
                  style: const TextStyle(color: kTextColor, fontSize: 15),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }


  // Widget buildFormFieldCountry(String label) {
  //   _country.text = _selectedCountry;
  //
  //   final list = Provider
  //       .of<Countries>(context, listen: false)
  //       .countryList;
  //
  //   final filteredList = list.whereType<Country>().toList() ?? [];
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 5.0),
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //         ),
  //       ),
  //       Card(
  //         elevation: 0.1,
  //         child: DropdownSearch<Country>(
  //           popupProps: const PopupProps.menu(
  //             showSearchBox: true,
  //             fit: FlexFit.loose,
  //             menuProps: MenuProps(
  //               backgroundColor: kBackgroundColor, // dropdownColor equivalent
  //             ),
  //             searchFieldProps: TextFieldProps(
  //               decoration: InputDecoration(
  //                 hintText: 'Search country...',
  //               ),
  //             ),
  //           ),
  //           items: filteredList,
  //           itemAsString: (Country c) => c.name ?? '',
  //           dropdownDecoratorProps: DropDownDecoratorProps(
  //             dropdownSearchDecoration: InputDecoration(
  //               // filled: true,
  //               // fillColor: Colors.white,
  //               contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //               enabledBorder: OutlineInputBorder(
  //                 borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               focusedBorder:  OutlineInputBorder(
  //                 borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //
  //           ),
  //           selectedItem: filteredList.firstWhere(
  //                 (country) => country.id == _selectedCountry,
  //             orElse: () => Country(id: '0', name: 'Select Country'),
  //           ),
  //           onChanged: (Country? country) {
  //             setState(() {
  //               _selectedCountry = country?.id ?? '';
  //               _country.text = _selectedCountry;
  //             });
  //             callStateListApi(_selectedCountry);
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget buildFormFieldCountry(String label) {
    _country.text = _selectedCountry;

    final list = Provider.of<Countries>(context, listen: false).countryList;
    final filteredList = list.whereType<Country>().toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xffD3D3D3), width: .1),
            ),
            child: DropdownSearch<Country>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                menuProps: MenuProps(
                  backgroundColor: kBackgroundColor,
                ),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    suffixIcon: Icon(Icons.keyboard_arrow_down), // This is the down arrow icon
                  ),
                ),
              ),
              items: filteredList,
              itemAsString: (Country c) => c.name ?? '',
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffD3D3D3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xffD3D3D3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              selectedItem: filteredList.firstWhere(
                    (country) => country.id == _selectedCountry,
                orElse: () => Country(id: '0', name: 'Select Country'),
              ),
              onChanged: (Country? country) {
                setState(() {
                  _selectedCountry = country?.id ?? '';
                  _country.text = _selectedCountry;
                });
                callStateListApi(_selectedCountry);
              },
            )

        ),
      ],
    );
  }



  Widget buildFormPincodeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(label),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(   // 👈 hintText का color control
                color: Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                getIconForField(label), // e.g. phone icon
                color: Colors.grey.shade400,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 14),

              // ✅ Inner white background
              filled: true,
              fillColor: Colors.white,

              // ✅ Borders
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: label == "Pin code"
                ? [
              FilteringTextInputFormatter.digitsOnly,      // sirf numbers
              LengthLimitingTextInputFormatter(6),         // max 6 digit
            ]
                : FieldInputHelper.getInputFormatters(label),   // baaki fields ka default
            validator: (value) {
              if (label == "Pin code") {
                if (value == null || value.isEmpty) {
                  return "Pin code cannot be empty";
                } else if (value.length != 6) {
                  return "Pin code must be exactly 6 digits";
                }
              }
              return null; // other fields ke liye no error
            },
          ),
        ),
      ],
    );
  }




  Widget buildFormFieldState(String label) {

    final list = Provider
        .of<Countries>(context, listen: false)
        .stateList;
    final filteredList = list.whereType<Country>().toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Card(
          elevation: 0.1,
          child: DropdownSearch<Country>(
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              menuProps: MenuProps(
                backgroundColor: kBackgroundColor, // dropdownColor equivalent
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search state...',
                ),
              ),
            ),
            items: filteredList,
            itemAsString: (Country c) => c.name ?? '',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                // filled: true,
                // fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

            ),
            selectedItem: filteredList.firstWhere(
                  (country) => country.id == _selectedState,
              orElse: () => Country(id: '1', name: 'Select State'),
            ),
            onChanged: (Country? country) {
              setState(() {
                _selectedState = country?.id ?? '';
                _state.text = _selectedState;
              });
              callCityListApi(_selectedState);
            },
          ),
        ),
      ],
    );
  }

  Widget buildFormFieldCity(String label) {
    final list = Provider
        .of<Countries>(context, listen: false)
        .cityList;
    final filteredList = list.whereType<Country>().toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Card(
          elevation: 0.1,
          child: DropdownSearch<Country>(
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              menuProps: MenuProps(
                backgroundColor: kBackgroundColor, // dropdownColor equivalent
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search city...',
                ),
              ),
            ),
            items: filteredList,
            itemAsString: (Country c) => c.name ?? '',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                // filled: true,
                // fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

            ),
            selectedItem: filteredList.firstWhere(
                  (country) => country.id == _selectedCity,
              orElse: () => Country(id: '', name: 'Select City'),
            ),
            onChanged: (Country? country) {
              setState(() {
                _selectedCity = country?.id ?? '';
                _city.text = _selectedCity;
              });
            },
          ),
        ),
      ],
    );
  }
  Widget buildDividerTitle(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 20.0,
        ),
        const Divider(
          height: 10,
          color: kSecondaryColor,
        ),
        Container(
          padding: const EdgeInsets.only(top: 5.0,bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  // red instruction
  Widget buildInstruction(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20.0),
        const Text(
          'Please fill your under graduate or graduate details',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Container(
          padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }


  // Widget buildFormFieldClassX(String label,var list,int index) {
  //   final filteredList = list.whereType<Option>().toList() ?? [];
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 5.0),
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //         ),
  //       ),
  //       Card(
  //         child: DropdownSearch<Option>(
  //           popupProps: const PopupProps.menu(
  //             showSearchBox: true,
  //             fit: FlexFit.loose,
  //             menuProps: MenuProps(
  //               backgroundColor: kBackgroundColor, // dropdownColor equivalent
  //             ),
  //             searchFieldProps: TextFieldProps(
  //               decoration: InputDecoration(
  //                 hintText: 'Search field name..',
  //               ),
  //             ),
  //           ),
  //           items: filteredList,
  //           itemAsString: (Option c) => c.label ?? '',
  //           dropdownDecoratorProps: DropDownDecoratorProps(
  //             dropdownSearchDecoration: InputDecoration(
  //               // filled: true,
  //               // fillColor: Colors.white,
  //               contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //               enabledBorder: OutlineInputBorder(
  //                 borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               focusedBorder:  OutlineInputBorder(
  //                 borderSide: const BorderSide(color: Color(0xffD3D3D3)), // On focus
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //
  //           ),
  //           selectedItem: filteredList.firstWhere(
  //                 (option) => option.value == (index == 0 ? _selectedXBoard : index == 1 ? _selectedXYear : index == 2 ? _selectedXMedium : ''),
  //             orElse: () => Option(label: 'Select ', value: 'Select '),
  //           ),
  //           onChanged: (Option? option) {
  //             setState(() {
  //               if(index == 0){
  //                 _selectedXBoard = option?.value ?? '';;
  //               }else if(index == 1){
  //                 _selectedXYear = option?.value ?? '';;
  //               }else if(index == 2){
  //                 _selectedXMedium = option?.value ?? '';;
  //               }
  //             });
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget buildFormFieldClassX(String label, var list, int index) {
    final filteredList = list.whereType<Option>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // fill color
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Color(0xffD3D3D3), width: 1),
          ),
          child: DropdownSearch<Option>(
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              menuProps: MenuProps(
                backgroundColor: kBackgroundColor,
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search field name..',
                ),
              ),
            ),
            items: filteredList,
            itemAsString: (Option c) => c.label ?? '',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3),width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3),width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            selectedItem: filteredList.firstWhere(
                  (option) =>
              option.value ==
                  (index == 0
                      ? _selectedXBoard
                      : index == 1
                      ? _selectedXYear
                      : index == 2
                      ? _selectedXMedium
                      : ''),
              orElse: () => Option(label: 'Select ', value: 'Select '),
            ),
            onChanged: (Option? option) {
              setState(() {
                if (index == 0) {
                  _selectedXBoard = option?.value ?? '';
                } else if (index == 1) {
                  _selectedXYear = option?.value ?? '';
                } else if (index == 2) {
                  _selectedXMedium = option?.value ?? '';
                }
              });
            },
          ),
        ),
      ],
    );
  }


  Widget buildFormFieldUnderGradu(String label,var list,int index) {
    final filteredList = list.whereType<Option>().toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Card(
          elevation: 0.1,
          child: DropdownSearch<Option>(
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              menuProps: MenuProps(
                backgroundColor: kBackgroundColor, // dropdownColor equivalent
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search field name..',
                ),
              ),
            ),
            items: filteredList,
            itemAsString: (Option c) => c.label ?? '',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                // filled: true,
                // fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

            ),
            selectedItem: filteredList.firstWhere(
                  (option) => option.value == (
                  index == 0 ? _selectedUGName :
                  index == 1 ? _selectedUGType :
                  index == 2 ? _selectedUGMonth :
                  index == 3 ? _selectedUGYear : ''
              ),
              orElse: () => Option(label: 'Select ', value: 'Select '),
            ),

            onChanged: (Option? option) {
              setState(() {
                if(index == 0){
                  _selectedUGName = option?.value ?? '';

                }else if(index == 1){
                  _selectedUGType = option?.value ?? '';
                }else if(index == 2){
                  _selectedUGMonth = option?.value ?? '';
                }else if(index == 3){
                  _selectedUGYear = option?.value ?? '';
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget buildFormFieldGradu(String label,var list,int index) {
    final filteredList = list.whereType<Option>().toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        Card(
          elevation: 0.1,
          child: DropdownSearch<Option>(
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              menuProps: MenuProps(
                backgroundColor: kBackgroundColor, // dropdownColor equivalent
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search field name..',
                ),
              ),
            ),
            items: filteredList,
            itemAsString: (Option c) => c.label ?? '',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                // filled: true,
                // fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xffD3D3D3)), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

            ),
            selectedItem: filteredList.firstWhere(
                  (option) => option.value == (index == 0 ? _selectedGName : index == 1 ? _selectedGType : index == 2 ? _selectedGMonth : index == 3 ? _selectedGYear : ''),
              orElse: () => Option(label: 'Select ', value: 'Select '),
            ),
            onChanged: (Option? option) {
              setState(() {
                if(index == 0){
                  _selectedGName = option?.value ?? '';
                }else if(index == 1){
                  _selectedGType = option?.value ?? '';
                }else if(index == 2){
                  _selectedGMonth = option?.value ?? '';
                }else if(index == 3){
                  _selectedGYear = option?.value ?? '';
                }
              });
            },
          ),
        ),
      ],
    );
  }


  Widget buildlinkDeatils(String label,TextEditingController controller,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle(label),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)).copyWith(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFD3D3D3),width: 1, // thin border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color:Color(0xFFD3D3D3),width: 1, // thin border
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: FieldInputHelper.getKeyboardType(label),
            inputFormatters: FieldInputHelper.getInputFormatters(label),
          ),
        ),
      ],
    );
  }


  Widget buildFormFieldResume(String label){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ),
        PdfUploadWidget(
          selectedPdf: _selectedPdf,
          label: label,
          onFileSelected: (file) {
            debugPrint(file?.path.toString());
            // Save to state, send to API, etc.
            _selectedPdf = file;
          },
        ),
      ],
    );
  }




  // Widget buildFormFieldXMarks(String label,int index,int value) {
  //   final name = configData.userprofilefields?[index]?.fieldname;
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 5.0),
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //         ),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.only(bottom: 8.0),
  //         child: TextFormField(
  //           controller: _controllers[name],
  //           style: const TextStyle(fontSize: 14),
  //           decoration: getInputDecoration(label, getIconForField(label)),
  //           keyboardType: FieldInputHelper.getKeyboardType(label),
  //           inputFormatters: FieldInputHelper.getInputFormatters(label),
  //           validator: (value) {
  //             if (value == null || value.trim().isEmpty) {
  //               return '$label cannot be empty';
  //             }
  //             return null;
  //           },
  //           onSaved: (value){
  //             boardDetail['$name'] = value ?? '';
  //             boardControllers.add(boardDetail);
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }




  IconData getIconForField(String label) {
    final key = label.toLowerCase();

    if (key.contains('email')) return Icons.email;
    if (key.contains('name')) return Icons.person;
    if (key.contains('phone') || key.contains('mobile')) return Icons.phone;
    if (key.contains('address')) return Icons.home;
    if (key.contains('bio') || key.contains('about')) return Icons.info_outline;
    if (key.contains('twitter')) return MdiIcons.twitter;
    if (key.contains('facebook')) return MdiIcons.facebook;
    if (key.contains('linkedin')) return MdiIcons.linkedin;
    if (key.contains('GitHub Link')) return MdiIcons.github;
    if (key.contains('date of birth')) return Icons.calendar_today;

    return Icons.text_fields; // default
  }

  String getTitleForField(String label){
    final key = label.toLowerCase();

    if (key.contains('class_x')) return "Class X Details";
    if (key.contains('under_graduate')) return "Under Graduate Details";
    if (key.contains('graduate')) return "Graduate Details";
    return "";
  }
  bool getBoolForField(String label){
    final key = label.toLowerCase();

    if (key.contains('class_x')) return true;
    if (key.contains('under_graduate')) return true;
    if (key.contains('graduate')) return true;
    return false;
  }



  Future<void> _selectDate(BuildContext context) async {
    // Close keyboard if open:
    FocusScope.of(context).unfocus();
    // If the field already has a value, parse it so the picker opens there:
    DateTime initialDate = DateTime(1990);
    if ((_dob.text ?? "").isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(_dob.text ?? "");
        debugPrint(initialDate.toString());
      } catch (_) {
        // ignore parse errors, fallback to 1990
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light(),  // force light theme for the dialog
          child: child!,            // the actual date picker
        );
      },
    );

    if (pickedDate != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        _dob.text = formatted;
        debugPrint("_controllers-->");
        debugPrint(_dob.text.toString());
      });
    }
  }


  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _mobile.dispose();
    _dob.dispose();
    _gender.dispose();
    _country.dispose();
    _state.dispose();
    _city.dispose();
    _pincode.dispose();
    _classXMarks.dispose();
    _uGcourseName.dispose();
    _uGSpecailaization.dispose();
    _uGInstituteName.dispose();
    _uGMarks.dispose();
    _uGGrade.dispose();
    _gCourseName.dispose();
    _gSpecailaization.dispose();
    _gGrade.dispose();
    _gMarks.dispose();
    _gInstituteName.dispose();
    _linkedinLink.dispose();
    _githubLink.dispose();
    super.dispose();
  }

  setUserProfileFields(EditProfileResponse user){
    debugPrint('user.gender');
    debugPrint(user.gender);
    _firstname.text = user.firstName ?? '';
    _lastname.text = user.lastName ?? '';
    _mobile.text = user.phone ?? '0000000000';
    _dob.text =user.dateOfBirth ?? '';
    _selectedGender =user.gender ?? 'Male';
    _country.text =user.country ?? '';
    _state.text =user.state ?? '';
    _city.text =user.city ?? '';
    _selectedCity = user.city ?? '';
    _pincode.text =user.pincode ?? '';
    _classXMarks.text =user.classX?.marks ?? '';

    _uGcourseName.text =user.underGraduate?.courseName ?? '';
    _uGSpecailaization.text =user.underGraduate?.specializationName ?? '';
    _uGInstituteName.text =user.underGraduate?.instituteName ?? '';
    _uGMarks.text =user.underGraduate?.marks ?? '';
    _uGGrade.text =user.underGraduate?.gradingSystem ?? '';
    _selectedUGGradingSystem = user.underGraduate?.gradingSystem ?? '';



    _gCourseName.text =user.graduate?.courseName ?? '';
    _gSpecailaization.text =user.graduate?.specializationName ?? '';
    _gInstituteName.text =user.graduate?.instituteName ?? '';
    _gMarks.text =user.graduate?.marks ?? '';
    _gGrade.text =user.graduate?.gradingSystem ?? '';
    _selectedGrGradingSystem = user.graduate?.gradingSystem ?? '';


    _linkedinLink.text =user.linkedin ?? '';
    _githubLink.text =user.github ?? '';

    // _selectedGender = user.gender ?? '';
    _selectedCountry = user.country ?? '';
    _selectedState = user.state ?? '';
    _selectedCity = user.city ?? '';
    //class x
    _selectedXBoard = user.classX?.boardName ?? '';
    _selectedXYear = user.classX?.passingYear ?? '';
    _selectedXMedium = user.classX?.medium ?? '';
    //class UG
    _selectedUGName = user.underGraduate?.instituteName ?? '';
    _selectedUGType = user.underGraduate?.courseType ?? '';
    _selectedUGMonth = user.underGraduate?.month ?? '';
    _selectedUGYear = user.underGraduate?.year ?? '';
    //class G
    _selectedGName = user.graduate?.instituteName ?? '';
    _selectedGType = user.graduate?.courseType ?? '';
    _selectedGMonth = user.graduate?.month ?? '';
    _selectedGYear = user.graduate?.year ?? '';
  }

  validateFormData(){
    if(_selectedCountry == 0){
      CommonFunctions.showWarningToast('Please select country',);
      return;
    }else if(_selectedState == 0){
      CommonFunctions.showWarningToast('Please select state',);
      return;
    }else if(_selectedCity == 0){
      CommonFunctions.showWarningToast("Please select city");
      return;
    }else if(_selectedXBoard == 0){
      CommonFunctions.showWarningToast("Please select class x board");
      return;
    }else if(_selectedXYear == 0){
      CommonFunctions.showWarningToast("Please select class x passing year");
      return;
    }else if(_selectedXMedium == 0){
      CommonFunctions.showWarningToast("Please select class x medium");
      return;
    }
    else if(_selectedUGName == 0 &&  _selectedGName == 0){
      CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data",);
      return;
    }else if(_selectedUGType == 0 && _selectedGType == 0){
      CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data",);
      return;
    }else if(_selectedUGMonth == 0 && _selectedGMonth == 0){
      CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data");
      return;
    }else if(_selectedUGYear == 0 && _selectedGYear == 0){
      CommonFunctions.showWarningToast("Please Fill Under Graduate or Graduate Data",);
      return;
    }





  }


}




