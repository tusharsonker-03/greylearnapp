// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
// ✅ add these (for saving token + notifying Auth)
import 'package:provider/provider.dart';
import '../providers/shared_pref_helper.dart';
import '../providers/auth.dart';
import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/models/update_user_model.dart';
import 'package:academy_app/screens/tabs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../constants.dart';
import 'auth_screen.dart';

class VerificationScreen extends StatefulWidget {
  static const routeName = '/email_verification';
  const VerificationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VerificationScreenState createState() => _VerificationScreenState();
}

Future<UpdateUserModel> verifyEmail(
    String email, String verificationCode) async {
  print("🔵---------------- VERIFY EMAIL API START ----------------");
  print("📩 Email: $email");
  print("🔢 Verification Code: $verificationCode");
   String apiUrl = "$BASE_URL/api/verify_email_address";
  print("🌐 API URL: $apiUrl");


  final response = await http.post(Uri.parse(apiUrl), body: {
    'email': email,
    'verification_code': verificationCode,
  });
  print("🟡 STATUS CODE: ${response.statusCode}");
  print("📥 RAW RESPONSE: ${response.body}");
  if (response.statusCode == 200) {
    print("🟢 RESPONSE OK → Parsing JSON...");

    final String responseString = response.body;

    final model = updateUserModelFromJson(responseString);
    print("🟢 PARSED MODEL: $model");

    print("🔵---------------- VERIFY EMAIL API END ----------------");
    return model;
  } else {
    throw Exception('Failed to load data');
  }
}

Future<UpdateUserModel> resendCode(String email) async {
   String apiUrl = "$BASE_URL/api/resend_verification_code";

  final response = await http.post(Uri.parse(apiUrl), body: {
    'email': email,
  });

  if (response.statusCode == 200) {
    final String responseString = response.body;

    return updateUserModelFromJson(responseString);
  } else {
    throw Exception('Failed to load data');
  }
}

class _VerificationScreenState extends State<VerificationScreen> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  var _isLoading = false;
  String? _emailArg;
  String? _passwordArg;

  final _boxController1 = TextEditingController();
  final _boxController2 = TextEditingController();
  final _boxController3 = TextEditingController();
  final _boxController4 = TextEditingController();
  final _boxController5 = TextEditingController();
  final _boxController6 = TextEditingController();

  final _boxFocus1 = FocusNode();
  final _boxFocus2 = FocusNode();
  final _boxFocus3 = FocusNode();
  final _boxFocus4 = FocusNode();
  final _boxFocus5 = FocusNode();
  final _boxFocus6 = FocusNode();

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focus;
  late TextEditingController _selectedController;
  late FocusNode _selectedFocus;
  late List<int> _stayOnce;
  int _lastTapped = -1; // last tapped box index

  bool _isPasting = false;
  int _pasteStart = -1;
  int _resendCooldown = 0; // seconds left
  Timer? _resendTimer;
  String _value = '';

  @override
  void initState() {
    super.initState();
    _controllers = [
      _boxController1,
      _boxController2,
      _boxController3,
      _boxController4,
      _boxController5,
      _boxController6,
    ];
    _focus = [
      _boxFocus1,
      _boxFocus2,
      _boxFocus3,
      _boxFocus4,
      _boxFocus5,
      _boxFocus6,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? email;
      String? password;

      if (args is String) {
        email = args;
      } else if (args is Map) {
        email = (args['email'] ?? '').toString();
        password = (args['password'] ?? '').toString();
      }

      if (!mounted) return;
      setState(() {
        _emailArg = email;       // 👈 this triggers a rebuild so masked email appears instantly
        _passwordArg = password; // (optional)
      });
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final args = ModalRoute.of(context)!.settings.arguments;
    //   if (args is String) {
    //     // backward compatibility: purane flow me sirf email aata tha
    //     _emailArg = args;
    //   } else if (args is Map) {
    //     _emailArg = (args['email'] ?? '').toString();
    //     _passwordArg = (args['password'] ?? '').toString();
    //   }
    // });
    _stayOnce = List<int>.filled(6, 0); // NEW
    _lastTapped = -1; // 👈 NEW
    _startResendCooldown(60);
  }


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
      // ✅ Resolve email from either String or Map args, or from _emailArg
      final args = ModalRoute.of(context)!.settings.arguments;
      final emailForVerify = _emailArg ??
          (args is String
              ? args
              : (args is Map ? (args['email'] ?? '').toString() : ''));

      if (emailForVerify.isEmpty) {
        CommonFunctions.showErrorDialog('Email not found for verification.', context);
        setState(() => _isLoading = false);
        return;
      }
      final UpdateUserModel user = await verifyEmail(emailForVerify, _value);

      // if (user.status == 200) {
      //   Navigator.of(context).pushNamed(AuthScreen.routeName);
      //   CommonFunctions.showSuccessToast(user.message.toString());
      if (user.status == 200) {
        // 1) read email & password for auto-login
        final email = emailForVerify;
        final password = _passwordArg ??
            (args is Map ? (args['password'] ?? '').toString() : '');

        if (password.isEmpty) {
          // fallback: go to Sign In
          Navigator.of(context).pushNamed(AuthScreen.routeName);
          CommonFunctions.showSuccessToast('Email verified. Please sign in.');
        } else {
          // 2) auto-login
          final res = await _autoLoginPost(email, password);
          if (res.ok) {

            // ✅ welcome from auto-login response
            final first = res.firstName.trim();
            final last  = res.lastName.trim();
            if (first.isNotEmpty || last.isNotEmpty) {
              CommonFunctions.showSuccessToast('Welcome, $first $last');
            }
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => TabsScreen(index: 0)),
                  (route) => false,
            );

          }
        }
      } else {
        CommonFunctions.showErrorDialog(user.message.toString(), context);
      }
    } catch (error) {
      const errorMsg = 'Could not verify email!';
      CommonFunctions.showErrorDialog(errorMsg, context);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resend() async {
    // agar cooldown chal raha hai to ignore
    if (_resendCooldown > 0) return;

    try {
      final args = ModalRoute.of(context)!.settings.arguments;
      final emailForResend = _emailArg ??
          (args is String
              ? args
              : (args is Map ? (args['email'] ?? '').toString() : ''));

      if (emailForResend.isEmpty) {
        CommonFunctions.showErrorDialog('Email not found to resend code.', context);
        return;
      }

      // API hit
      final UpdateUserModel user = await resendCode(emailForResend);

      if (user.status == 200) {
        // ⏱️ 60s cooldown start
        _startResendCooldown(60);

        // Route ko re-push mat karo (warna timer reset ho jayega)
        // Navigator.of(context).pushNamed(VerificationScreen.routeName, arguments: {
        //   'email': emailForResend,
        //   'password': _passwordArg ?? '',
        // });

        CommonFunctions.showSuccessToast('OTP resent. Please check your email.');
      } else {
        CommonFunctions.showErrorDialog(user.message.toString(), context);
      }
    } catch (error) {
      CommonFunctions.showErrorDialog('Could not send code!', context);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        key: scaffoldKey,
        elevation: 0,
        iconTheme: const IconThemeData(color: kSelectItemColor),
        backgroundColor: kBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 30,
            ),
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
                          'Enter code from your email',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity, // full width so text wrap ho jayega
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'OTP sent to ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(
                                  text: (_emailArg != null && _emailArg!.isNotEmpty)
                                      ?  _maskEmail(_emailArg!)
                                      : '',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 17.0, bottom: 5.0),
                            child: Text(
                              'Verification Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                                  (index) => GestureDetector(
                                onTap: () {
                                  // if nothing has been entered focus on the first box
                                  if (_value.isEmpty) {
                                    setState(() {
                                      _selectedFocus = _focus[0];
                                      _selectedController = _controllers[0];
                                    });
                                    FocusScope.of(context)
                                        .requestFocus(_selectedFocus);
                                    // else focus on the box that was tapped
                                  } else {
                                    setState(() {
                                      _selectedFocus = _focus[index];
                                      _selectedController = _controllers[index];
                                    });
                                    FocusScope.of(context)
                                        .requestFocus(_selectedFocus);
                                  }
                                  // 🔽🔽🔽 ADD THIS BLOCK 🔽🔽🔽
                                  setState(() {
                                    for (int i = 0; i < _stayOnce.length; i++)
                                      _stayOnce[i] = 0;
                                    _stayOnce[index] =
                                    1; // first backspace should stay here
                                    _lastTapped =
                                        index; // remember this is the tap-edit box
                                  });
                                  // 🔼🔼🔼 ADD THIS BLOCK 🔼🔼🔼
                                  // print(_selectedController.text);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: SizedBox(
                                    width: 15,
                                    height: 25,
                                    child: Focus(
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent &&
                                            event.logicalKey ==
                                                LogicalKeyboardKey.backspace &&
                                            _controllers[index].text.isEmpty) {
                                          // 👇 agar ye wahi box hai jisko tap karke edit kar rahe the,
                                          // pehli backspace yahin consume karo (previous par NA jao)
                                          if (_lastTapped == index &&
                                              _stayOnce[index] == 1) {
                                            _stayOnce[index] = 0; // consume
                                            return KeyEventResult.handled;
                                          }

                                          // normal behaviour: empty + backspace => previous box
                                          if (index > 0) {
                                            _focus[index - 1].requestFocus();
                                            final prev =
                                            _controllers[index - 1];
                                            prev.selection =
                                                TextSelection.collapsed(
                                                    offset: prev.text.length);
                                          } else {
                                            _focus[0].requestFocus();
                                          }
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: TextField(
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          controller: _controllers[index],
                                          focusNode: _focus[index],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^[0-9]+$')),
                                          ],
                                          onTap: () {
                                            // if nothing has been entered focus on the first box
                                            if (_value.isEmpty) {
                                              setState(() {
                                                _selectedFocus = _focus[0];
                                                _selectedController =
                                                _controllers[0];
                                              });
                                              // FocusScope.of(context)
                                              //     .requestFocus(_selectedFocus);
                                            }
                                            // NEW: jis box par tap kiya uske liye first-backspace stay enable
                                            setState(() {
                                              for (int i = 0;
                                              i < _stayOnce.length;
                                              i++) _stayOnce[i] = 0;
                                              _stayOnce[index] = 1;
                                              _lastTapped = index; // 👈 NEW
                                            });
                                          },
                                          onChanged: (val) {
                                            // agar programmatic paste ke dauran yeh kisi aur box ka onChanged trigger hua,
                                            // to usko ignore kar do
                                            if (_isPasting &&
                                                index != _pasteStart) {
                                              // selection ko end pe rakh do, bas
                                              _controllers[index].selection =
                                                  TextSelection.collapsed(
                                                    offset: _controllers[index]
                                                        .text
                                                        .length,
                                                  );
                                              return;
                                            }

                                            // -------------- BACKSPACE CASE --------------
                                            if (val.isEmpty) {
                                              // 👉 tap-edit sticky: pehli backspace par yahi rukna hai
                                              if (_lastTapped == index &&
                                                  _stayOnce[index] == 1) {
                                                _stayOnce[index] =
                                                0; // consume pehli backspace
                                                setState(() {
                                                  _value =
                                                      _controllers.fold<String>(
                                                          '',
                                                              (p, e) => p + e.text);
                                                });
                                                return; // previous par NA jao
                                              }

                                              // normal: empty + backspace => previous box
                                              if (index > 0) {
                                                _controllers[index].clear();
                                                _selectedFocus =
                                                _focus[index - 1];
                                                _selectedController =
                                                _controllers[index - 1];
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                    _selectedFocus);
                                              }

                                              // value recompute
                                              setState(() {
                                                _value =
                                                    _controllers.fold<String>(
                                                        '',
                                                            (p, e) => p + e.text);
                                              });
                                              // keyboard YAHIN band nahi karte
                                              return;
                                            }

                                            // sirf digits lo
                                            final clean = val.replaceAll(
                                                RegExp(r'[^0-9]'), '');
                                            if (clean.isEmpty) return;

                                            // -------------- MULTI-DIGIT PASTE CASE --------------
                                            if (clean.length > 1) {
                                              _isPasting = true;
                                              _pasteStart = index;

                                              final digits = clean;
                                              int writeIndex = index;

                                              for (int k = 0;
                                              k < digits.length &&
                                                  writeIndex <
                                                      _controllers.length;
                                              k++) {
                                                _controllers[writeIndex].text =
                                                digits[k];
                                                _controllers[writeIndex]
                                                    .selection =
                                                const TextSelection
                                                    .collapsed(offset: 1);
                                                writeIndex++;
                                              }

                                              // paste ke baad sticky reset
                                              for (int i = 0;
                                              i < _stayOnce.length;
                                              i++) _stayOnce[i] = 0;
                                              _lastTapped = -1;

                                              setState(() {
                                                _value =
                                                    _controllers.fold<String>(
                                                        '',
                                                            (prev, e) =>
                                                        prev + e.text);
                                              });

                                              // focus: last filled box ke next pe, ya sab fill ho gaye to keyboard band
                                              if (writeIndex < _focus.length) {
                                                _selectedFocus =
                                                _focus[writeIndex];
                                                _selectedController =
                                                _controllers[writeIndex];
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                    _selectedFocus);
                                              } else {
                                                FocusScope.of(context)
                                                    .unfocus();
                                              }

                                              _isPasting = false;
                                              _pasteStart = -1;
                                              return;
                                            }

                                            // -------------- NORMAL SINGLE DIGIT / OVERWRITE CASE --------------
                                            final digit =
                                            clean[clean.length - 1];

                                            // sirf current box update
                                            _controllers[index].text = digit;
                                            _controllers[index].selection =
                                            const TextSelection.collapsed(
                                                offset: 1);

                                            // type karte hi sticky off, kyunki ab normal flow chalega
                                            _stayOnce[index] = 0;
                                            _lastTapped = -1;

                                            setState(() {
                                              _value =
                                                  _controllers.fold<String>(
                                                      '',
                                                          (prev, e) =>
                                                      prev + e.text);
                                            });

                                            // Move to next box
                                            if (index + 1 < _focus.length) {
                                              _selectedFocus =
                                              _focus[index + 1];
                                              _selectedController =
                                              _controllers[index + 1];
                                              FocusScope.of(context)
                                                  .requestFocus(_selectedFocus);
                                            }

                                            // -------------- CLOSE KEYBOARD ONLY IF ALL DIGITS FILLED --------------
                                            if (_value.length ==
                                                _controllers.length) {
                                              FocusScope.of(context).unfocus();
                                            }
                                          }

                                        // onChanged: (val) {
                                        //   // -------------- BACKSPACE CASE --------------
                                        //   if (val.isEmpty) {
                                        //     // 👉 tap-edit sticky: pehli backspace par yahi rukna hai
                                        //     if (_lastTapped == index && _stayOnce[index] == 1) {
                                        //       _stayOnce[index] = 0; // consume pehli backspace
                                        //       setState(() {
                                        //         _value = _controllers.fold<String>('', (p, e) => p + e.text);
                                        //       });
                                        //       return; // previous par NA jao
                                        //     }
                                        //     if (index > 0) {
                                        //       _controllers[index].clear();
                                        //       _selectedFocus =
                                        //           _focus[index - 1];
                                        //       _selectedController =
                                        //           _controllers[index - 1];
                                        //       FocusScope.of(context)
                                        //           .requestFocus(_selectedFocus);
                                        //     }
                                        //     return; // important → keyboard NEVER closes here
                                        //   }
                                        //
                                        //   // -------------- PASTE CASE (MULTIPLE DIGITS) --------------
                                        //   if (val.length > 1) {
                                        //     final digits = val
                                        //         .replaceAll(
                                        //             RegExp(r'[^0-9]'), '')
                                        //         .split('');
                                        //
                                        //     for (int i = 0;
                                        //         i < _controllers.length;
                                        //         i++) {
                                        //       _controllers[i].text =
                                        //           i < digits.length
                                        //               ? digits[i]
                                        //               : '';
                                        //     }
                                        //     // paste ke baad sticky reset
                                        //     for (int i = 0; i < _stayOnce.length; i++) _stayOnce[i] = 0;
                                        //     _lastTapped = -1;
                                        //
                                        //     setState(() {
                                        //       _value =
                                        //           _controllers.fold<String>(
                                        //               '',
                                        //               (prev, e) =>
                                        //                   prev + e.text);
                                        //     });
                                        //
                                        //     // Keyboard close ONLY if full 6 digits
                                        //     if (_value.length ==
                                        //         _controllers.length) {
                                        //       FocusScope.of(context).unfocus();
                                        //     }
                                        //
                                        //     return;
                                        //   }
                                        //
                                        //   // -------------- NORMAL SINGLE DIGIT CASE --------------
                                        //   _controllers[index].text = val;
                                        //   // type karte hi sticky off, kyunki ab normal flow chalega
                                        //   _stayOnce[index] = 0;
                                        //   _lastTapped = -1;
                                        //
                                        //   setState(() {
                                        //     _value = _controllers.fold<String>(
                                        //         '', (prev, e) => prev + e.text);
                                        //   });
                                        //
                                        //   // Move to next box
                                        //   if (index + 1 < _focus.length) {
                                        //     _selectedFocus = _focus[index + 1];
                                        //     _selectedController =
                                        //         _controllers[index + 1];
                                        //     FocusScope.of(context)
                                        //         .requestFocus(_selectedFocus);
                                        //   }
                                        //
                                        //   // -------------- CLOSE KEYBOARD ONLY IF ALL DIGITS FILLED --------------
                                        //   if (_value.length ==
                                        //       _controllers.length) {
                                        //     FocusScope.of(context).unfocus();
                                        //   }
                                        // }

                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Enter 6 digit verification code send to your email.',
                          style: TextStyle(color: kSecondaryColor),
                        ),
                        TextButton(
                          onPressed: _resendCooldown > 0 ? null : _resend,
                          child: Text(
                            _resendCooldown > 0
                                ? 'Resend (${_resendCooldown}s)'
                                : 'Resend',
                            style: TextStyle(
                              color: _resendCooldown > 0
                                  ? Colors.grey
                                  : kBlueColor,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
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
                                    'Verify',
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
                    'Want to go Back?',
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
          ],
        ),
      ),
    );
  }

  Future<_AutoLoginResult> _autoLoginPost(String email, String password) async {
    print("🔵 AUTO LOGIN STARTED...");
    print("📩 Sending Email: $email");
    print("🔑 Sending Password: $password");
    try {
      String apiUrl = "$BASE_URL/api/auto_login";


      // Agar tumhare paas ApiClient() hai to use bhi kar sakte ho:
      // final resp = await ApiClient().post(url.toString(), body: { ... });

      final resp = await http.post(Uri.parse(apiUrl), body: {
        'email': email,
        'password': password,
      });

      print("🟡 STATUS CODE: ${resp.statusCode}");
      print("🟡 RAW RESPONSE: ${resp.body}");
      if (resp.statusCode != 200) {
        return _AutoLoginResult(ok: false);
      }

      // Expected: {"validity":1, "token": "...", ...} (tumhare backend ke hisaab se)

      final jsonBody = jsonDecode(resp.body);

      // success flags (any one as per your backend)
      final ok = (jsonBody['validity'] == 1 || jsonBody['status'] == true || jsonBody['success'] == true);

      // 🔐 extract token (common keys handled)
      final token = (jsonBody['token'] ??
          jsonBody['access_token'] ??
          jsonBody['auth_token'] ??
          '').toString();

      if (ok && token.isNotEmpty) {
        // SAVE token + notify Auth
        await SharedPreferenceHelper().setAuthToken(token);
        context.read<Auth>().setTokenAfterVerify(token);
      }
      // 👇👇 NEW: API response se aaya user_id save karo (JWT decode nahi)
      final uid = (jsonBody['user_id'] ??
          '').toString();
      if (uid != null && uid.isNotEmpty) {
        await SharedPreferenceHelper().setUserId(uid);
        debugPrint('✅ [DV] Saved user_id = $uid');
      } else {
        debugPrint('🟨 [DV] user_id not present in verify response');
      }

      print('User Token Data : $token');


      // ✅ extract name from auto-login response (handle common key variants)
      String first = '';
      String last  = '';

      // try explicit keys
      first = (jsonBody['first_name'] ??
          jsonBody['firstname'] ??
          jsonBody['firstName'] ??
          '')
          .toString();
      last  = (jsonBody['last_name'] ??
          jsonBody['lastname'] ??
          jsonBody['lastName'] ??
          '')
          .toString();
      // fallback: single "name" → split
      if (first.isEmpty && last.isEmpty && jsonBody['name'] != null) {
        final full = jsonBody['name'].toString().trim();
        if (full.isNotEmpty) {
          final parts = full.split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            first = parts.first;
            if (parts.length > 1) {
              last = parts.sublist(1).join(' ');
            }
          }
        }
      }

      return _AutoLoginResult(ok: ok == true, firstName: first, lastName: last);
    } catch (e) {
      return _AutoLoginResult(ok: false);
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final domain = parts[1];

    if (local.isEmpty) return email;

    // keep first 2 and last 2 (agar itne possible na ho to jitna ho utna)
    final keepStart = local.length >= 2 ? 2 : 1;
    final keepEnd = local.length >= 4 ? 2 : (local.length > 1 ? 1 : 0);

    final start = local.substring(0, keepStart);
    final end = keepEnd > 0 ? local.substring(local.length - keepEnd) : '';
    final middleLen = (local.length - start.length - end.length).clamp(0, 1000);
    final middle = 'x' * middleLen;

    return '$start$middle$end@$domain';
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

}

class _AutoLoginResult {
  final bool ok;
  final String firstName;
  final String lastName;
  _AutoLoginResult({
    required this.ok,
    this.firstName = '',
    this.lastName = '',
  });
}
