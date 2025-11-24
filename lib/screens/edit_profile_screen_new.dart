// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:academy_app/constants.dart';
import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/models/country.dart';
import 'package:academy_app/models/user.dart';
import 'package:academy_app/providers/auth.dart';
import 'package:academy_app/providers/countries.dart';
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
  final Map<String, TextEditingController> _controllers = {};
  String _selectedGender = 'Male';
  String _selectedCountry = '101';
  String _selectedState = '0';
  String _selectedCity = '0';
  //class x
  // String _selectedBoard = '';
  File? _selectedPdf;
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB
  var _isInit = true;
  List<BoardDetail> boardDetailsList = [];
  List<EducationDetail> boardunGDetailsList = [];
  final List<Map<String, String>> boardControllers = [];
  final List<Map<String, String>> boardUnGControllers = [];
  Map<String, String> boardDetail = {};
  Map<String, String> unGDetail = {};


  @override
  void initState() {
    super.initState();
    getConfigData();

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
    // if (!_formKey.currentState!.validate()) {
    //   // Invalid!
    //   return;
    // }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final token = await SharedPreferenceHelper().getAuthToken();
    final Map<String, String> fieldValues = {};

    _controllers.forEach((key, controller) {
      fieldValues[key] = controller.text.trim();
    });

    // final request = UserProfileUpdateRequest(
    //     authToken: token ?? '',
    //     firstName: "Rahul",
    //     lastName: "Patil",
    //     dateOfBirth: "1996-06-24",
    //     gender: "Male",
    //     country: "101",
    //     state: "22",
    //     city: "2726",
    //     pincode: "421306",
    //     boardDetails: [BoardDetail(boardType: 'test', board: 'test', boardMarks: 'test', boardYear: 'test', medium: 'test')],
    //     educationDetails: [EducationDetail(index: 3,educationType: 'test'), EducationDetail(index: 4,educationType: 'test'),],
    // );

    // for (var ctrMap in boardDetail){
    //
    // }
    for (var ctrlMap in boardControllers) {
      final detail = BoardDetail(
        boardType: ctrlMap["board_type"] ?? "",
        board: ctrlMap["board_name"] ?? "",
        boardMarks: ctrlMap["marks"] ?? "",
        boardYear: ctrlMap["year"] ?? "",
        medium: ctrlMap["medium"] ?? "",
      );
      boardDetailsList.add(detail);
      //debugPrint(boardDetailsList.toString());
    }

    for (var ctrlMap in boardUnGControllers) {
      final detail = EducationDetail(
        index: int.tryParse(ctrlMap["education_type"] ?? "") ?? 0,
        educationType: ctrlMap["education_type"] ?? "",
        instituteName: ctrlMap["institute_name"] ?? "",
        courseName: ctrlMap["course_name"] ?? "",
        courseType: ctrlMap["course_type"] ?? "",
        specializationName: ctrlMap["specialization_name"] ?? "",
        month: ctrlMap["month"] ?? "",
        year: ctrlMap["year"] ?? "",
        gradingSystem: ctrlMap["grading_system"] ?? "",
        marks: ctrlMap["marks"] ?? "",
      );
      boardunGDetailsList.add(detail);
      //debugPrint(boardunGDetailsList.toString());
    }

    final request =  UserProfileUpdateRequest(authToken: token ?? '',
        firstName:  _controllers["first_name"]?.text ?? "",
        lastName: _controllers["last_name"]?.text ?? "",
        dateOfBirth: _controllers["date_of_birth"]?.text ?? "",
        gender: _controllers["gender"]?.text ?? "",
        country: _controllers["country"]?.text ?? "",
        state: _controllers["state"]?.text ?? "",
        city: _controllers["city"]?.text ?? "",
        pincode: _controllers["pincode"]?.text ?? "",
        boardDetails: boardDetailsList,
        educationDetails: boardunGDetailsList);
    // Log user in
      print("request.toString()");
      print(request.toString());
      // await Provider.of<Auth>(context, listen: false)
      //     .uploadUserProfileWithResume(userMap: request, resumeFile: File(_selectedPdf?.path ?? ""));

    setState(() {
      _isLoading = false;
    });
  }

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
        future: Provider.of<Auth>(context, listen: false).getUserInfo(),
        builder: (ctx, dataSnapshot) {
          if (dataSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
            );
          } else {
            if (dataSnapshot.error != null) {
              return const Center(
                child: Text('Error Occured'),
              );
            } else {
              return Consumer<Auth>(
                builder: (context, authData, child) {
                  final user = authData.user;
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
                          child: UserImagePicker(
                            image: user.image,
                          ),
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
                                  ListView.builder(
                                    itemCount: configData.userprofilefields?.length ?? 0,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (ctx, i) {
                                      final label = configData.userprofilefields![i]?.fieldlabel ?? '';
                                      final type = configData.userprofilefields![i]?.type ?? '';
                                      final academicType = configData.userprofilefields![i]?.academictype ?? '';
                                      final isPhone = label.toLowerCase().contains('phone');
                                      final isDateField = label.toLowerCase().contains('birth');
                                      final isGender = label.toLowerCase().contains('gender');
                                      final isResume = label.toLowerCase().contains('resume');
                                      final isCountry = label.toLowerCase().contains('country');
                                      final isState = label.toLowerCase().contains('state');
                                      final isCity = label.toLowerCase().contains('city');
                                      final isTypeHidden = type.toLowerCase().contains('hidden');
                                      final isAcademicTypeX = academicType.toLowerCase().contains('class_x');
                                      final isAcademicTypeU = academicType.toLowerCase().contains('under_graduate');
                                      final isAcademicTypeG = academicType.toLowerCase().contains('graduate');
                                      if(isGender){
                                        return buildFormFieldGender(label,configData.userprofilefields?[i]?.options,i);
                                      }else if(isCountry){
                                        return buildFormFieldCountry(label,i);
                                      }else if(isState){
                                        return buildFormFieldState(label,i);
                                      }else if(isCity){
                                        return buildFormFieldCity(label,i);
                                      }
                                      // else if(isDateField){
                                      //   return buildFormFieldCalender(label,i);
                                      // }
                                      else if(isTypeHidden) {
                                        return buildDividerTitle(getTitleForField(configData.userprofilefields![i]?.academictype ?? ''));
                                      }else if(isAcademicTypeX) {
                                        final type = configData.userprofilefields![i]?.type ?? '';
                                        final value = configData.userprofilefields![i]?.value ?? '';
                                        final isTypeText = type.toLowerCase().contains('text');
                                        final isTypeNum = type.toLowerCase().contains('number');
                                        final isTypeSelect = type.toLowerCase().contains('select');
                                        final valueInt = int.tryParse(value) ?? 0;
                                        boardDetail['board_type'] = configData.userprofilefields![i]?.value ?? "";
                                        boardControllers.add(boardDetail);
                                        if(isAcademicTypeX  && (isTypeText || isTypeNum)) {
                                          return buildFormFieldXMarks(label,i,valueInt);
                                        }else if(isAcademicTypeX  && isTypeSelect) {
                                          return buildFormFieldBoardName(label,i,valueInt);
                                        }
                                        // return buildDividerTitle(getTitleForField(configData.userprofilefields![i]?.academictype ?? ''));
                                      }else if(isAcademicTypeU) {
                                        final type = configData.userprofilefields![i]?.type ?? '';
                                        final value = configData.userprofilefields![i]?.value ?? '';
                                        final isTypeText = type.toLowerCase().contains('text');
                                        final isTypeSelect = type.toLowerCase().contains('select');
                                        final valueInt = int.tryParse(value) ?? 0;
                                        unGDetail['education_type'] = configData.userprofilefields![i]?.value ?? "";
                                        boardUnGControllers.add(unGDetail);
                                        if(isAcademicTypeU && isTypeText) {
                                          return buildFormFieldXMarks(label,i,valueInt);
                                        }else if (isAcademicTypeU && isTypeSelect) {
                                          return buildFormFieldBoardName(label,i,valueInt);
                                        }else{
                                          return const SizedBox();
                                        }

                                      }else if(isAcademicTypeG) {
                                        print("isAcademicTypeG--->>");
                                        print(isAcademicTypeG);
                                        final type = configData.userprofilefields![i]?.type ?? '';
                                        final value = configData.userprofilefields![i]?.value ?? '';
                                        final isTypeText = type.toLowerCase().contains('text');
                                        final isTypeSelect = type.toLowerCase().contains('select');
                                        final valueInt = int.tryParse(value) ?? 0;
                                        if(isAcademicTypeG && isTypeText) {
                                          return buildFormFieldXMarks(label,i,valueInt);
                                        }else if(isAcademicTypeG && isTypeSelect) {
                                          return buildFormFieldBoardName(label,i,valueInt);
                                        }else{
                                          return const SizedBox();
                                        }
                                       }else if(isResume){
                                        return buildFormFieldResume(label, i);
                                      }
                                      else if(isPhone) {
                                        return buildFormFieldPhone(label,i,user.firstName.toString());
                                      }else {
                                        return buildFormField(label,i);
                                      }
                                      return SizedBox();
                                    },
                                  ),
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
          }
        },
      ),
    );
  }
  Future<void> getConfigData() async {
    dynamic data = await SharedPreferenceHelper().getConfigData();
    if (data != null) {
      final decodedData = ConfigData.fromJson(json.decode(data));

      // Initialize controllers based on field labels
      for (var field in decodedData.userprofilefields ?? []) {
        if (field.fieldname != null) {
          _controllers[field.fieldname!] = TextEditingController();
        }
      }
      setState(() {
        configData = decodedData;
      });
    }
  }
  Widget buildFormFieldPhone(String label,int index, String phone,) {
    final name = configData.userprofilefields?[index]?.fieldname;
    _controllers[name]?.text = phone ?? "";
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            enabled: false,
            controller: _controllers[name],
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)),
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

  Widget buildFormFieldResume (String label,int index){
    final name = configData.userprofilefields?[index]?.fieldname;

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
            _controllers[name]?.text = _selectedPdf?.path ?? "";
          },
        ),
      ],
    );
  }
  Widget buildFormField(String label,int index) {
    final name = configData.userprofilefields?[index]?.fieldname;
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: _controllers[name],
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)),
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
  Widget buildFormFieldXMarks(String label,int index,int value) {
    final name = configData.userprofilefields?[index]?.fieldname;
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            controller: _controllers[name],
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)),
            keyboardType: FieldInputHelper.getKeyboardType(label),
            inputFormatters: FieldInputHelper.getInputFormatters(label),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label cannot be empty';
              }
              return null;
            },
            onSaved: (value){
              boardDetail['$name'] = value ?? '';
              boardControllers.add(boardDetail);
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
  Widget buildFormFieldCalender(String label,int i) {
    final name = configData.userprofilefields?[i]?.fieldname;

    final isDateField = label.toLowerCase().contains('date of birth');
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            readOnly: true,
            controller: _controllers[name],
            style: const TextStyle(fontSize: 14),
            decoration: getInputDecoration(label, getIconForField(label)),
            keyboardType: FieldInputHelper.getKeyboardType(label),
            inputFormatters: FieldInputHelper.getInputFormatters(label),
            // validator: (value) {
            //   if (value == null || value.trim().isEmpty) {
            //     return '$label cannot be empty';
            //   }
            //   return null;
            // },
            onTap:() {
              _selectDate(name ?? '',isDateField,context);
            },
          ),
        ),
      ],
    );
  }
  Widget buildFormFieldGender(String label,List<Option?>? list,int index) {
    final name = configData.userprofilefields?[index]?.fieldname;
    _controllers[name]?.text = _selectedGender;
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
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButton(
              dropdownColor: kBackgroundColor,
              underline: const SizedBox(),
              value: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value.toString();
                  _controllers[name]?.text = _selectedGender;
                });

              },
              isExpanded: true,
              items: list?.map((list) {
                return DropdownMenuItem<String>(
                  value: list?.label ?? "",
                  child: Text(
                    list?.value ?? "",
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  Widget buildFormFieldCountry(String label,int index) {
    final name = configData.userprofilefields?[index]?.fieldname;
    _controllers[name]?.text = _selectedCountry;

    final list = Provider
        .of<Countries>(context, listen: false)
        .countryList;

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
                  hintText: 'Search country...',
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
                  borderSide: const BorderSide(color: Colors.white), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // On focus
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
                _controllers[name]?.text = _selectedCountry;
              });
              callStateListApi(_selectedCountry);
            },
          ),
        ),
      ],
    );
  }
  Widget buildFormFieldBoardName(String label, int index,int value) {
    final list = configData.userprofilefields?[index]?.options;
    final name = configData.userprofilefields?[index]?.fieldname;
    final fieldlabel = configData.userprofilefields?[index]?.fieldlabel;
    final filteredList = list?.whereType<Option>().toList() ?? [];
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
                  borderSide: const BorderSide(color: Colors.white), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white), // On focus
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

            ),
            selectedItem: filteredList.firstWhere(
                  (option) => option.value == (value == 1 ? boardDetail['$name'].toString(): unGDetail['$name'].toString()),
              orElse: () => Option(label: 'Select $fieldlabel', value: 'Select $fieldlabel'),
            ),
            onChanged: (Option? option) {
              setState(() {
                // _selectedBoard = option?.value ?? '';
                value == 1 ? boardDetail['$name'] = option?.value ?? '' : unGDetail['$name'] = option?.value ?? '';
                value == 1 ? boardControllers.add(boardDetail) : boardUnGControllers.add(unGDetail);

              });
            },
          ),
        ),
      ],
    );
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
  Widget buildFormFieldState(String label,int index) {
    final name = configData.userprofilefields?[index]?.fieldname;

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
                  borderSide: const BorderSide(color: Colors.white), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // On focus
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
                _controllers[name]?.text = _selectedState;
              });
              callCityListApi(_selectedState);
            },
          ),
        ),
      ],
    );
  }
  Widget buildFormFieldCity(String label,int index) {
    final name = configData.userprofilefields?[index]?.fieldname;

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
                  borderSide: const BorderSide(color: Colors.white), // Change this color
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder:  OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // On focus
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
                _controllers[name]?.text = _selectedCity;
              });
            },
          ),
        ),
      ],
    );
  }

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
  Future _selectDate(String name, bool isDateField,BuildContext context) async {
    if(isDateField) {
      FocusScope.of(context).unfocus(); // Close keyboard if open
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime(1990),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        final formatted = DateFormat('yyyy-MM-dd').format(pickedDate);
        _controllers[name]?.text = formatted;
        // userMap[label] = formatted;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }



}
