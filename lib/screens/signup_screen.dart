// ignore_for_file: use_build_context_synchronously

import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/models/update_user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../constants.dart';
import 'auth_screen.dart';
import 'verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpScreenState createState() => _SignUpScreenState();
}

Future<UpdateUserModel> signUp(String firstName, String lastName, String email,
    String password, String phonenumber) async {
  String apiUrl = "$BASE_URL/api/signup";

  final response = await http.post(Uri.parse(apiUrl), body: {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'password': password,
    'phone': phonenumber,
  });

  if (response.statusCode == 200) {
    final String responseString = response.body;

    return updateUserModelFromJson(responseString);
  } else {
    throw Exception('Failed to load data');
  }
}

class _SignUpScreenState extends State<SignUpScreen> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool hidePassword = true;
  bool _isLoading = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phonenumberController = TextEditingController();

  Future<void> _submit() async {
    if (!globalFormKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    globalFormKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });
    try {
      final UpdateUserModel user = await signUp(
        _firstNameController.text,
        _lastNameController.text,
        _emailController.text,
        _passwordController.text,
        _phonenumberController.text,
      );

      if (user.emailVerification == 'enable') {
        // NEW CONDITION
        if (user.message == "This email userdata already exists") {
          Navigator.of(context).pushNamed(AuthScreen.routeName);
          CommonFunctions.showSuccessToast("This User Already Exist");
        }
        // Already signed up but OTP pending
        else if (user.message ==
            "You have already signed up. Please check your inbox to verify your email address") {
          Navigator.of(context).pushNamed(
            VerificationScreen.routeName,
            arguments: {
              'email': _emailController.text,
              'password': _passwordController.text, // 👈 add this
            },
          );
          CommonFunctions.showSuccessToast(user.message.toString());
        }
        // OTP flow
        else {
          Navigator.of(context).pushNamed(
            VerificationScreen.routeName,
            arguments: {
              'email': _emailController.text,
              'password': _passwordController.text, // 👈 add this
            },
            // arguments: _emailController.text,
          );
          CommonFunctions.showSuccessToast(user.message.toString());
        }
      }
      // Direct success path
      else {
        Navigator.of(context).pushNamed(AuthScreen.routeName);
        CommonFunctions.showSuccessToast('Signup Successful');
      }
    } catch (error) {
      const errorMsg = 'Could not register!';
      CommonFunctions.showErrorDialog(errorMsg, context);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Future<void> _submit() async {
  //   if (!globalFormKey.currentState!.validate()) {
  //     // Invalid form
  //     return;
  //   }
  //   globalFormKey.currentState!.save();
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     final UpdateUserModel user = await signUp(
  //       _firstNameController.text,
  //       _lastNameController.text,
  //       _emailController.text,
  //       _passwordController.text,
  //     );
  //
  //     // 🔹 Check if user already registered
  //     if (user.message != null &&
  //         user.message!.toLowerCase().contains("already")) {
  //       Navigator.of(context).pushNamed(VerificationScreen.routeName);
  //       CommonFunctions.showErrorDialog("You have already registered", context);
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       return;
  //     }
  //
  //     if (user.emailVerification == 'enable') {
  //       Navigator.of(context).pushNamed(
  //         VerificationScreen.routeName,
  //         arguments: _emailController.text,
  //       );
  //       CommonFunctions.showSuccessToast(user.message.toString());
  //     } else {
  //       Navigator.of(context).pushNamed(AuthScreen.routeName);
  //       CommonFunctions.showSuccessToast('Signup Successful');
  //     }
  //   } catch (error) {
  //     const errorMsg = 'Could not register!';
  //     CommonFunctions.showErrorDialog(errorMsg, context);
  //   }
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  InputDecoration getInputDecoration(String hintext, IconData iconData) {
    return InputDecoration(
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(
          Radius.circular(12.0),
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: Color(0xFFF65054)),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: Color(0xFFF65054)),
      ),
      filled: true,
      prefixIcon: Icon(
        iconData,
        color: kTextLowBlackColor,
      ),
      hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      hintText: hintext,
      fillColor: kBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          // ✅ Back button press par kya kare:

          if (Navigator.of(context).canPop()) {
            // agar peeche koi route hai to usi pe wapas jao
            Navigator.of(context).pop();
          } else {
            // agar yeh root screen hai to SignUpScreen pe bhej do
            Navigator.of(context).pushReplacementNamed(SignUpScreen.routeName);

            // ya agar seedha app band karna ho to:
            // SystemNavigator.pop();
          }

          // khud handle kar liya, isliye false
          return false;
        },
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            key: scaffoldKey,
            elevation: 0,
            backgroundColor: kBackgroundColor,
            iconTheme: const IconThemeData(color: kSelectItemColor),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // If we can go back in stack, pop; else go to Sign In screen
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushReplacementNamed(AuthScreen.routeName);
                }
              },
            ),
          ),

          // appBar: AppBar(
          //   key: scaffoldKey,
          //   elevation: 0,
          //   iconTheme: const IconThemeData(color: kSelectItemColor),
          //   backgroundColor: kBackgroundColor,
          // ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Form(
                    key: globalFormKey,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 15),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: kBackgroundColor,
                              child: Image.asset(
                                'assets/images/do_login.png',
                                height: 65,
                              ),
                            ),
                            const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: 17.0, bottom: 5.0),
                                child: Text(
                                  'First Name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  top: 0.0,
                                  right: 15.0,
                                  bottom: 8.0),
                              child: TextFormField(
                                style: const TextStyle(fontSize: 14),
                                decoration: getInputDecoration(
                                    'First Name', Icons.person),
                                keyboardType: TextInputType.name,
                                controller: _firstNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'First name cannot be empty';
                                  }
                                  if (!RegExp(r'^[a-zA-Z ]+$')
                                      .hasMatch(value)) {
                                    // 🔹 Space allowed
                                    return 'Only alphabets are allowed';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  // _authData['email'] = value.toString();
                                  _firstNameController.text = value as String;
                                },
                              ),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: 17.0, bottom: 5.0),
                                child: Text(
                                  'Last Name',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  top: 0.0,
                                  right: 15.0,
                                  bottom: 8.0),
                              child: TextFormField(
                                style: const TextStyle(fontSize: 14),
                                decoration: getInputDecoration(
                                  'Last Name',
                                  Icons.person,
                                ),
                                keyboardType: TextInputType.name,
                                controller: _lastNameController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Last name cannot be empty';
                                  }
                                  if (!RegExp(r'^[a-zA-Z ]+$')
                                      .hasMatch(value)) {
                                    return 'Only alphabets are allowed';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  // _authData['email'] = value.toString();
                                  _lastNameController.text = value as String;
                                },
                              ),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: 17.0, bottom: 5.0),
                                child: Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  top: 0.0,
                                  right: 15.0,
                                  bottom: 8.0),
                              child: TextFormField(
                                style: const TextStyle(fontSize: 14),
                                decoration: getInputDecoration(
                                    'Phone Number', Icons.phone),
                                keyboardType: TextInputType.phone,
                                controller: _phonenumberController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(
                                      10), // max 10 digits
                                  FilteringTextInputFormatter
                                      .digitsOnly, // only digits allowed
                                ],
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Phone number cannot be empty';
                                  }
                                  if (value.length < 10) {
                                    return 'Enter a valid phone number';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _phonenumberController.text = value!;
                                },
                              ),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: 17.0, bottom: 5.0),
                                child: Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  top: 0.0,
                                  right: 15.0,
                                  bottom: 8.0),
                              child: TextFormField(
                                style: const TextStyle(fontSize: 14),
                                decoration: getInputDecoration(
                                  'Email',
                                  Icons.email_outlined,
                                ),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (input) =>
                                    !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                            .hasMatch(input!)
                                        ? "Email Id should be valid"
                                        : null,
                                onSaved: (value) {
                                  // _authData['email'] = value.toString();
                                  _emailController.text = value as String;
                                },
                              ),
                            ),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(left: 17.0, bottom: 5.0),
                                child: Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 15.0,
                                  top: 0.0,
                                  right: 15.0,
                                  bottom: 4.0),
                              child: TextFormField(
                                style: const TextStyle(color: Colors.black),
                                keyboardType: TextInputType.text,
                                controller: _passwordController,
                                onSaved: (input) {
                                  // _authData['password'] = input.toString();
                                  _passwordController.text = input as String;
                                },
                                validator: (input) => input!.length < 3
                                    ? "Password should be more than 3 characters"
                                    : null,
                                obscureText: hidePassword,
                                decoration: InputDecoration(
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12.0)),
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 2),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12.0)),
                                    borderSide: BorderSide(
                                        color: Colors.white, width: 2),
                                  ),
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12.0),
                                    ),
                                  ),
                                  filled: true,
                                  hintStyle: const TextStyle(
                                      color: Colors.black54, fontSize: 14),
                                  hintText: "Password",
                                  fillColor: kBackgroundColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 15),
                                  prefixIcon: const Icon(
                                    Icons.lock_outlined,
                                    color: kTextLowBlackColor,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    color: kTextLowBlackColor,
                                    icon: Icon(hidePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0,
                                          right: 15,
                                          top: 10,
                                          bottom: 10),
                                      child: MaterialButton(
                                        elevation: 0,
                                        onPressed: _submit,
                                        color: kPrimaryColor,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusDirectional.circular(
                                                  10),
                                          // side: const BorderSide(color: kPrimaryColor),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: kTextLowBlackColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(AuthScreen.routeName);
                        },
                        child: const Text(
                          ' Sign In',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                )
              ],
            ),
          ),
        ));
  }
}
