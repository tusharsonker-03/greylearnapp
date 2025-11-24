// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:academy_app/models/common_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../models/update_verify_model.dart';
import '../providers/auth.dart';
import '../providers/shared_pref_helper.dart';
import 'auth_screen.dart';
import 'tabs_screen.dart';

class DeviceVerificationScreen extends StatefulWidget {
  static const routeName = '/device_verification';
  const DeviceVerificationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DeviceVerificationScreenState createState() =>
      _DeviceVerificationScreenState();
}

Future<UpdateVerifyModel> verifyEmail(
  String email,
  String verificationCode,
) async {
  String apiUrl = "$BASE_URL/api/new_login_confirmation/submit";

  final response = await http.post(Uri.parse(apiUrl), body: {
    'email': email,
    'new_device_verification_code': verificationCode,
    // 'auth_token': token
  });

  print('➡️ POST $apiUrl');
  print('   email="$email", otp="$verificationCode"');
  print('⬅️ status=${response.statusCode}');
  print('⬅️ body=${response.body}');

  if (response.statusCode == 200) {
    final String responseString = response.body;
    print("Api Response Data : $responseString");

    return updateVerifyModelFromJson(responseString);
  } else {
    throw Exception('Failed to load data');
  }
}

Future<UpdateVerifyModel> resendCode(
  String email,
) async {
  String apiUrl = "$BASE_URL/api/new_login_confirmation/resend";

  final response = await http.post(Uri.parse(apiUrl), body: {
    'email': email,
  });

  print("🔹 [DEBUG] Response Status Code: ${response.statusCode}");
  print("🔹 [DEBUG] Response Body: ${response.body}");

  if (response.statusCode == 200) {
    final String responseString = response.body;
    print("✅ [DEBUG] Request successful, parsing JSON...");
    return updateVerifyModelFromJson(responseString);
  } else {
    throw Exception('Failed to load data');
  }
}

class _DeviceVerificationScreenState extends State<DeviceVerificationScreen> {
  GlobalKey<FormState> globalFormKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  var _isLoading = false;
  var _isResendLoading = false;

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
  // per-box: 1 => first backspace stay, 0 => normal
  late List<int> _stayOnce;
  int _lastTapped = -1; // last tapped box index

  bool _isPasting = false;
  int _pasteStart = -1;
  String? _email;
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
    _stayOnce = List<int>.filled(6, 0); // NEW
    _lastTapped = -1; // 👈 NEW
    _startResendCooldown(60);

  }

  Future<void> _submit() async {
    // raw debug
    debugPrint("🟦 [_submit] raw _value='$_value' length=${_value.length}");

    // ✅ CHANGED: OTP sanitize + 6-digit guard
    final otp = _value.replaceAll(RegExp(r'[^0-9]'), '');
    if (otp.length != 6) {
      CommonFunctions.showErrorDialog(
          'Please enter the 6-digit code.', context);
      debugPrint("🟥 [_submit] invalid OTP '$otp' (len=${otp.length})");
      return;
    }

    if (!globalFormKey.currentState!.validate()) return;
    globalFormKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
              {};

      // ✅ CHANGED: email resolve with fallbacks
      String email = (args['email'] ?? '').toString().trim();
      if (email.isEmpty) {
        try {
          // try provider user
          email = context.read<Auth>().user.email?.toString().trim() ?? '';
        } catch (_) {}
      }
      if (email.isEmpty) {
        // last resort: if you still have form email in this screen’s state, use that.
        // email = _authData['email']?.trim() ?? '';
      }

      debugPrint("🟩 [_submit] using email='$email', otp='$otp'");

      if (email.isEmpty) {
        CommonFunctions.showErrorDialog(
            'Email not found. Please login again.', context);
        setState(() => _isLoading = false);
        return;
      }

      // ✅ CHANGED: pass sanitized OTP
      final UpdateVerifyModel user = await verifyEmail(email, otp);

      // ✅ CHANGED: success => validity == 1
      if (user.validity == 1) {
        final token = (user.token ?? '').trim();
        debugPrint(
            "🟩 [verifyEmail] validity=1, token='${token.isEmpty ? "(empty)" : token}'");

        if (token.isNotEmpty) {
          await SharedPreferenceHelper().setAuthToken(token);
          context.read<Auth>().setTokenAfterVerify(token); // 👈 IMPORTANT
        }

        // 👇👇 NEW: API response se aaya user_id save karo (JWT decode nahi)
        final uid = user.userId?.toString();
        if (uid != null && uid.isNotEmpty) {
          await SharedPreferenceHelper().setUserId(uid);
          debugPrint('✅ [DV] Saved user_id = $uid');
        } else {
          debugPrint('🟨 [DV] user_id not present in verify response');
        }

        print('User Token Data : $token');
        // (optional but recommended) persist token & validity in userData
        final prefs = await SharedPreferences.getInstance();
        final userDataRaw = prefs.getString('userData');
        if (userDataRaw != null) {
          final map = Map<String, dynamic>.from(json.decode(userDataRaw));
          map['token'] = token;
          map['validity'] = 1; // ✅ CHANGED
          await prefs.setString('userData', json.encode(map));
        }

        // navigate & return
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TabsScreen(index: 0)),
        );
        CommonFunctions.showSuccessToast(
          'Welcome, ${user.firstName} ${user.lastName}',
        );
        return; // ✅ CHANGED: stop further code
      } else {
        debugPrint(
            "🟨 [verifyEmail] validity=${user.validity}, message='${user.message}'");
        CommonFunctions.showErrorDialog(
            user.message?.toString() ?? 'Verification failed', context);
      }
    } catch (error, st) {
      debugPrint("🟥 [_submit] exception: $error");
      debugPrint("🟥 [_submit] stacktrace:\n$st");
      CommonFunctions.showErrorDialog('Could not verify email!', context);
    }

    setState(() => _isLoading = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_email == null) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
              {};
      var e = (args['emayil'] ?? '').toString().trim();
      if (e.isEmpty) {
        try {
          e = context.read<Auth>().user.email?.toString().trim() ?? '';
        } catch (_) {}
      }
      if (e.isNotEmpty) {
        setState(() => _email = e);
      }
    }
  }

  // Future<void> _submit() async {
  //   debugPrint("🟦 [_submit] raw _value='$_value' length=${_value.length}");
  //
  //
  //   if (!globalFormKey.currentState!.validate()) {
  //     // Invalid!
  //     return;
  //   }
  //   globalFormKey.currentState!.save();
  //
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //
  //     final Map<String, dynamic> arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  //
  //
  //     final email = arguments['email'];
  //     // final token = arguments['token'];
  //
  //     final UpdateVerifyModel user = await verifyEmail(email, _value,);
  //
  //     if (user.validity == 1) {
  //       // ✅ 1) Token uthao response se
  //       final token = (user.token ?? '').trim();
  //
  //       // ✅ 2) SharedPrefs me save karo (aapke helper ka naam use karo)
  //       if (token.isNotEmpty) {
  //         await SharedPreferenceHelper().setAuthToken(token);
  //       }
  //
  //
  //       // (optional but recommended) — existing 'userData' ko update karo
  //       // taaki app ke baaki hisse bhi token ko wahi se padhen
  //       final prefs = await SharedPreferences.getInstance();
  //       final userDataRaw = prefs.getString('userData');
  //       if (userDataRaw != null) {
  //         final map = Map<String, dynamic>.from(json.decode(userDataRaw));
  //         map['token'] = token; // 👈 update token only
  //         await prefs.setString('userData', json.encode(map));
  //       }
  //
  //       Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (context) => TabsScreen(index: 0,)));
  //       CommonFunctions.showSuccessToast(user.message.toString());
  //     } else {
  //       CommonFunctions.showErrorDialog(user.message.toString(), context);
  //     }
  //   } catch (error) {
  //     const errorMsg = 'Could not verify email!';
  //     CommonFunctions.showErrorDialog(errorMsg, context);
  //   }
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  Future<void> _resend() async {
    setState(() {
      _isResendLoading = true;
    });
    try {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
              {};
      final email = (args['email'] ?? '').toString().trim();

      if (email.isEmpty) {
        CommonFunctions.showErrorDialog(
            'Email not found. Please login again.', context);
        return;
      }

      final UpdateVerifyModel res = await resendCode(email);

      // 🔑 Success detect (without res.status):
      final msg = (res.message ?? '').trim();
      final looksLikeSuccess = res.validity == 1 ||
          msg.toLowerCase().contains('sent') || // e.g. "Verification code sent"
          msg.toLowerCase().contains('resent'); // e.g. "Code resent"

      if (looksLikeSuccess) {
        CommonFunctions.showSuccessToast(
            msg.isNotEmpty ? msg : 'Verification code sent');
        _startResendCooldown(60); // ⬅️ add this

        // Yahin par raho; navigate karne ki zarurat nahi
      } else {
        CommonFunctions.showErrorDialog(
            msg.isNotEmpty ? msg : 'Could not send code!', context);
      }
    } catch (error) {
      CommonFunctions.showErrorDialog('Could not send code!', context);
    } finally {
      setState(() {
        _isResendLoading = false;
      });
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
                        const SizedBox(height: 40),
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
                                  text: (_email != null && _email!.isNotEmpty)
                                      ?  _maskEmail(_email!)
                                      : 'your email',
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
                        _isResendLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: Color(0xFF27AE60),
                              ))
                            : (_resendCooldown > 0)
                                ? Text(
                                    'Resend in 00:${_resendCooldown.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.grey),
                                  )
                                : TextButton(
                                    onPressed: _resend,
                                    child: const Text(
                                      'Resend',
                                      style: TextStyle(color: kBlueColor),
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                        // ? const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60),))
                        // : TextButton(
                        //     onPressed: _resend,
                        //     child: const Text(
                        //       'Resend',
                        //       style: TextStyle(color: kBlueColor),
                        //       textAlign: TextAlign.start,
                        //     ),
                        //   ),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                  color: Color(0xFF27AE60),
                                ))
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
