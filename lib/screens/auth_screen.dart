// ignore_for_file: use_build_context_synchronously

import 'package:academy_app/constants.dart';
import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/providers/auth.dart';
import 'package:academy_app/providers/notification_counter.dart';
import 'package:academy_app/screens/forgot_password_screen.dart';
import 'package:academy_app/screens/signup_screen.dart';
import 'package:academy_app/widgets/string_extension.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import 'device_verifcation.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';
  const AuthScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AuthScreenState createState() => _AuthScreenState();
}


class _AuthScreenState extends State<AuthScreen> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, String> _authData = {
    'email': '',
    'password': '',
  };

  bool hidePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late User userDetails;

  Color getColor(Set<WidgetState> states) {
    const Set<WidgetState> interactiveStates = <WidgetState>{
      WidgetState.pressed,
      WidgetState.hovered,
      WidgetState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.red;
  }

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


  Future<void> _submit() async {
    if (_isLoading) return; // guard
    setClarityUserId(_authData['email'].toString());

    if (!globalFormKey.currentState!.validate()) return;
    globalFormKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 1) Login — await, no .then race
      await Provider.of<Auth>(context, listen: false).login(
        _authData['email'].toString().trim(),
        _authData['password'].toString(),
      );

      // 2) Fresh user snapshot
      userDetails = Provider.of<Auth>(context, listen: false).user;

      // --- Normalize deviceVerification safely ---
      // --- Normalize deviceVerification safely ---
      final raw = (userDetails.deviceVerification ?? '').toString();
      final dv = raw
          .trim()
          .toLowerCase()
          .replaceAll('_', '-')
          .replaceAll(' ', '-')
          .replaceAll('--', '-');

      debugPrint('🔎 deviceVerification from API: "$dv" (raw: "$raw")');

// --- Identify needed verification ---
      final bool needsVerification = dv.contains('need') && dv.contains('verif') ||
          dv.contains('required') && dv.contains('verif') ||
          ['need-verification', 'needed-verification', 'verification-needed', 'verification-required']
              .any((keyword) => dv == keyword);

      if (needsVerification) {
        debugPrint('🔐 Verification needed — navigating to DeviceVerificationScreen');

        if (!mounted) return;
        Navigator.of(context).pushNamed(
          DeviceVerificationScreen.routeName,
          arguments: {
            'email': _authData['email']!.trim(),
          },
        );

        CommonFunctions.showSuccessToast(
          'Needed-Verification',
        );

        setState(() => _isLoading = false);
        return; // ✅ stop here, don't fall into error dialog
      }

// --- Already verified users ---
      if (dv == 'verified' || dv == 'completed') {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);

        CommonFunctions.showSuccessToast(
          'Welcome, ${userDetails.firstName} ${userDetails.lastName}',
        );

        final unread = int.tryParse(
          (userDetails.unreadNotificationsCount ?? "0").toString(),
        ) ??
            0;
        Provider.of<NotificationCounter>(context, listen: false).updateCount(unread);

        setState(() => _isLoading = false);
        return;
      }

// --- Fallback (only if status is truly unknown) ---
      debugPrint('⚠️ Unknown deviceVerification state: $dv');
      CommonFunctions.showErrorDialog(
        (raw.isEmpty ? 'Login failed' : raw.capitalize()),
        context,
      );

    } catch (e) {
      // Network/API error
      CommonFunctions.showErrorDialog('Login failed. Please try again.', context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // Future<void> _submit() async {
  //   setClarityUserId(_authData['email'].toString());
  //   if (!globalFormKey.currentState!.validate()) {
  //     // Invalid!
  //     return;
  //   }
  //   globalFormKey.currentState!.save();
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   await Provider.of<Auth>(context, listen: false).login(
  //     _authData['email'].toString(),
  //     _authData['password'].toString(),
  //   ).then((_) {
  //     setState(() {
  //       _isLoading = false;
  //       userDetails = Provider.of<Auth>(context, listen: false).user;
  //     });
  //   });
  //
  //
  //   if (userDetails.deviceVerification == 'needed-verification') {
  //     // ✅ User ko OTP verification karni hai
  //     Navigator.of(context).pushNamed(
  //       DeviceVerificationScreen.routeName,
  //       arguments: {
  //         'email': _authData['email']!.trim(),   // <-- form se direct
  //         // Agar OTP API token generate karti hai tab usko yahan bhejna
  //         // 'token': userDetails.token,
  //       },
  //     );
  //
  //     CommonFunctions.showSuccessToast(
  //       (userDetails.deviceVerification ?? 'Verification needed').capitalize(),
  //     );
  //
  //   } else if (userDetails.deviceVerification == 'verified' ||
  //       userDetails.deviceVerification == 'completed') {
  //     // ✅ Already verified user, direct home le jao
  //     Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
  //
  //     CommonFunctions.showSuccessToast(
  //       'Welcome, ${userDetails.firstName} ${userDetails.lastName}',
  //     );
  //
  //     Provider.of<NotificationCounter>(context, listen: false)
  //         .updateCount(int.parse(
  //         (userDetails.unreadNotificationsCount ?? "0").toString()));
  //
  //   } else {
  //     // ⚠️ Unknown ya error state
  //     CommonFunctions.showErrorDialog(
  //       (userDetails.deviceVerification ?? 'Login failed').capitalize(),
  //       context,
  //     );
  //   }
  //
  //
  //   setState(() {
  //     _isLoading = false;
  //   });
  //
  // }

  void setClarityUserId(String userId) {
    Clarity.setCustomUserId(userId);
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
          // agar yeh root screen hai to AuthScreen pe bhej do
          Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);

          // ya agar seedha app band karna ho to:
          // SystemNavigator.pop();
        }

        // khud handle kar liya, isliye false
        return false;
      },
    child:Scaffold(
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
              Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
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
                  padding: const EdgeInsets.all(15.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 25,
                        ),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: kBackgroundColor,
                          child: Image.asset(
                            'assets/images/do_login.png',
                            height: 70,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 17.0, bottom: 5.0),
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
                              left: 15.0, top: 0.0, right: 15.0, bottom: 8.0),
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
                              _authData['email'] = value.toString();
                              _emailController.text = value as String;
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 17.0, bottom: 5.0),
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
                              left: 15.0, top: 0.0, right: 15.0, bottom: 4.0),
                          child: TextFormField(
                            style: const TextStyle(color: Colors.black),
                            keyboardType: TextInputType.text,
                            controller: _passwordController,
                            onSaved: (input) {
                              _authData['password'] = input.toString();
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
                                borderSide:
                                BorderSide(color: Colors.white, width: 2),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                                borderSide:
                                BorderSide(color: Colors.white, width: 2),
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
                        InkWell(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(ForgotPassword.routeName);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Forget Password?',
                                style: TextStyle(color: kSecondaryColor),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60),))
                              : Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: MaterialButton(
                              elevation: 0,
                              color: kPrimaryColor,
                              onPressed: _submit,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadiusDirectional.circular(10),
                                // side: const BorderSide(color: kPrimaryColor),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Log In',
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
                        const SizedBox(height: 20),
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
                    'Do not have an account?',
                    style: TextStyle(
                      color: kTextLowBlackColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(SignUpScreen.routeName);
                    },
                    child: const Text(
                      ' Sign up',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ) );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
