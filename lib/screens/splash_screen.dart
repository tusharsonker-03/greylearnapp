// // ignore_for_file: use_build_context_synchronously
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';
//
// import 'package:academy_app/constants.dart';
// import 'package:academy_app/models/config_data.dart';
// import 'package:academy_app/providers/config.dart';
// import 'package:academy_app/screens/auth_screen_private.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Utils/base_url_global_helper.dart';
// import '../providers/shared_pref_helper.dart';
// import 'tabs_screen.dart';
// import '../api/api_client.dart';
//
//
// /// -------- Developer Options guard (Flutter side) --------
// const _devCh = MethodChannel('app.security.devoptions');
// // TOP: imports ke niche hi yeh key add karo
// const _kDevGateEnforceKey = 'dev_gate_enforce';
// /// Build-time flag (can be overridden via --dart-define)
// /// if true then show developer Option and false off developer option
// const bool kEnforceDevGateDefault =
// bool.fromEnvironment('ENFORCE_DEV_GATE', defaultValue: false);
// Future<bool> _isDevOn() async {
//   try {
//     final v = await _devCh.invokeMethod<bool>('isDevOptionsEnabled');
//     return v == true;
//   } catch (_) {
//     return false;
//   }
// }
//
// Future<void> _openDevSettings() async {
//   try { await _devCh.invokeMethod('openDevOptions'); } catch (_) {}
// }
//
// /// --------------------------------------------------------
//
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   dynamic courseAccessibility;
//   var _isInit = true;
//   var _isLoading = false;
//   ConfigData configData = ConfigData();
//   ConnectivityResult _connectionStatus = ConnectivityResult.none;
//   final Connectivity _connectivity = Connectivity();
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;
//
//   bool _devBlocked = false;
//   Timer? _devPoll;
//   // NEW: tester flag (default: true = enforce gate)
//   bool _enforceDevGate = true;
//
//   bool _openedFromNotification = false;
//
//
//   // NEW: load/save flag helpers
//   Future<void> _loadEnforceFlag() async {
//     final p = await SharedPreferences.getInstance();
//     // default true = enforce
//     final v = p.getBool(_kDevGateEnforceKey) ?? kEnforceDevGateDefault;
//     if (mounted) setState(() => _enforceDevGate = v);
//   }
//
//   Future<void> _setEnforceFlag(bool v) async {
//     final p = await SharedPreferences.getInstance();
//     await p.setBool(_kDevGateEnforceKey, v);
//     if (!mounted) return;
//     setState(() => _enforceDevGate = v);
//     // flag change par dobara check
//     _checkDevNow();
//   }
//
//
//   Future<void> _checkDevNow() async {
//     // ⚠️ Agar enforce OFF hai → kabhi block mat karo
//     if (!_enforceDevGate) {
//       if (!mounted) return;
//       setState(() => _devBlocked = false);
//       _devPoll?.cancel();
//       return;
//     }
//
//     final on = await _isDevOn();
//     if (!mounted) return;
//     setState(() => _devBlocked = on);
//
//     _devPoll?.cancel();
//     // optional: jab tak ON hai, har 2s me re-check
//     if (on) {
//       _devPoll = Timer.periodic(const Duration(seconds: 2), (_) async {
//         final again = await _isDevOn();
//         if (!mounted) return;
//         if (!again) {
//           setState(() => _devBlocked = false);
//           _devPoll?.cancel();
//           // ✅ ADD THIS: resume normal flow once Dev Options are OFF
//           if (mounted) donLogin();
//         }
//       });
//     }
//
//   }
//
//
//   /// Guarded navigate helper: dev ON hai to navigation block karo
//   Future<bool> _devGateBeforeNavigate() async {
//
//     // ⚠️ Enforce OFF → navigation allow
//     if (!_enforceDevGate) return true;
//     if (_devBlocked) {
//       // optional toast/snackbar
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please turn off Developer Options to continue')),
//       );
//       return false;
//     }
//     // double-check just before navigating
//     final on = await _isDevOn();
//     if (on) {
//       setState(() => _devBlocked = true);
//       return false;
//     }
//     return true;
//   }
//
//
//
//
//   systemSettings() async {
//     var url = "$BASE_URL/api/system_settings";
//     var response = await ApiClient().get(url);
//     debugPrint(response.toString());
//     if (response.statusCode == 200) {
//       var data = json.decode(response.body);
//       setState(() {
//         courseAccessibility = data['course_accessibility'];
//       });
//     } else {
//       setState(() {
//         courseAccessibility = '';
//       });
//     }
//   }
//   Future<void> initConnectivity() async {
//     late ConnectivityResult result;
//     try {
//       result = await _connectivity.checkConnectivity();
//     } on PlatformException catch (e) {
//       // ignore: avoid_print
//       print(e.toString());
//       return;
//     }
//
//     if (!mounted) {
//       return Future.value(null);
//     }
//
//     return _updateConnectionStatus(result);
//   }
//
//   Future<void> _updateConnectionStatus(ConnectivityResult result) async {
//     setState(() {
//       _connectionStatus = result;
//     });
//   }
//   @override
//   void initState() {
//     initConnectivity();
//     _connectivitySubscription =
//         _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
//
//     /// ✅ Yaha config set kar rahe hain ApiBase me
//     ApiBase.setConfig(configData);
//
//     systemSettings();
//     super.initState();
//
//     // 2) Start DevOptions check/poll
//     _loadEnforceFlag().then((_) => _checkDevNow());
//
//     // 🔽 Add this block
//     FirebaseMessaging.instance.getInitialMessage().then((message) {
//       if (message != null) {
//         debugPrint('💡 App opened via notification');
//         _openedFromNotification = true;
//       }
//       // call donLogin after checking
//       donLogin();
//     });
//
//
//   }
//
//
//
//   @override
//   void dispose() {
//     _connectivitySubscription.cancel();
//     super.dispose();
//   }
//
//   void donLogin() {
//     if (_openedFromNotification) {
//       debugPrint('⏭️ Skip auto navigation because app opened via notification');
//       return;
//     }
//
//     String? token;
//     Future.delayed(const Duration(seconds: 3), () async {
//       // ✅ ADD THIS: block navigation if Dev Options ON
//       final canGo = await _devGateBeforeNavigate();
//       if (!canGo) return;
//
//       token = await SharedPreferenceHelper().getAuthToken();
//       if (token != null && token!.isNotEmpty) {
//         Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => TabsScreen(index: 0,))
//         );
//       } else {
//         if (courseAccessibility == 'publicly') {
//           Navigator.of(context).pushReplacement(
//               MaterialPageRoute(builder: (context) => TabsScreen(index: 0,))
//           );
//         } else {
//           Navigator.of(context).pushReplacement(
//               MaterialPageRoute(builder: (context) => const AuthScreenPrivate())
//           );
//         }
//       }
//     });
//   }
//
//
//   // void donLogin() {
//   //
//   //   if (_openedFromNotification) {
//   //     debugPrint('⏭️ Skip auto navigation because app opened via notification');
//   //     return; // do nothing, let notification routing handle it
//   //   }
//   //
//   //   String? token;
//   //   Future.delayed(const Duration(seconds: 3), () async {
//   //     token = await SharedPreferenceHelper().getAuthToken();
//   //     if (token != null && token!.isNotEmpty) {
//   //       Navigator.of(context).pushReplacement(
//   //           MaterialPageRoute(builder: (context) => TabsScreen(index: 0,)));
//   //     } else {
//   //       if (courseAccessibility == 'publicly') {
//   //         Navigator.of(context).pushReplacement(
//   //             MaterialPageRoute(builder: (context) => TabsScreen(index: 0,)));
//   //       } else {
//   //         Navigator.of(context).pushReplacement(MaterialPageRoute(
//   //             builder: (context) => const AuthScreenPrivate()));
//   //       }
//   //     }
//   //   });
//   // }
//
//
//   @override
//   void didChangeDependencies() {
//     if (_isInit) {
//       setState(() {
//         _isLoading = true;
//       });
//
//       Provider.of<Config>(context).fetchConfigData().then((_) {
//         setState(() {
//           _isLoading = false;
//           configData = Provider.of<Config>(context, listen: false).configItems;
//
//
//         });
//       });
//     }
//     setData();
//     _isInit = false;
//     super.didChangeDependencies();
//   }
//
//   setData() async{
//     // await  Provider.of<Config>(context).fetchConfigData();
//     // configData = Provider.of<Config>(context, listen: false).configItems;
//     // _isLoading = false;
//     if(configData.appname?.isNotEmpty ?? false) {
//       await SharedPreferenceHelper().setConfigData(json.encode(configData));
//     }
//   }
//   showLoader(){
//         return _connectionStatus == ConnectivityResult.none
//             ? Center(child: Column(
//           //     children: [
//           //         SizedBox(
//           //             height:
//           //             MediaQuery.of(context).size.height * .15),
//           //         Image.asset(
//           //           "assets/images/no_connection.png",
//           //           height: MediaQuery.of(context).size.height * .35,
//           //         ),
//           //         const Padding(
//           //           padding: EdgeInsets.all(4.0),
//           //           child: Text('There is no Internet connection'),
//           //         ),
//           //         const Padding(
//           //           padding: EdgeInsets.all(4.0),
//           //           child:
//           //           Text('Please check your Internet connection'),
//           //         ),
//           // ],
//         ),) : Center(child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     // Agar Developer Options ON hai → blocking UI (no navigation)
//     if (_enforceDevGate && _devBlocked) {
//       return Scaffold(
//         backgroundColor: Color(0xff003840), // Dim background
//         body: SafeArea(
//           child: Center(
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.85,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.9),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.25),
//                         blurRadius: 20,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.warning_amber_rounded,
//                         color: Color(0xFFB3261E),
//                         size: 64,
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Developer Options Enabled',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       const Text(
//                         'For your security, this app cannot run while Developer Options or USB Debugging are enabled. Please disable them to continue.',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 15,
//                           color: Colors.black54,
//                           height: 1.4,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       FilledButton.icon(
//                         onPressed: _openDevSettings,
//                         icon: const Icon(Icons.settings),
//                         label: const Text('Open Developer Options'),
//                         style: FilledButton.styleFrom(
//                           backgroundColor: const Color(0xff005E6A),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       TextButton(
//                         onPressed: () => SystemNavigator.pop(),
//                         child: const Text(
//                           'Exit App',
//                           style: TextStyle(
//                             color: Colors.redAccent,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: SizedBox(
//           height: MediaQuery.of(context).size.height,
//           width: double.infinity,
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Image.asset(
//                   height: 240,
//                   width: 240,
//                   'assets/images/logo.png'),
//                 const Padding(
//                   padding: EdgeInsets.all(4.0),
//                   child: Text('Learn, Practice & Upskill'),
//                 ),
//                 const SizedBox(height: 8,),
//                 // FutureBuilder(
//                 //   future:
//                 //   Provider.of<Config>(context, listen: false).fetchConfigData(),
//                 //   builder: (ctx, dataSnapshot) {
//                 //     if (dataSnapshot.connectionState == ConnectionState.waiting) {
//                 //       return SizedBox(
//                 //         height: MediaQuery.of(context).size.height * .5,
//                 //         child: Center(
//                 //           child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
//                 //         ),
//                 //       );
//                 //     } else {
//                 //       if (dataSnapshot.error != null) {
//                 //         //error
//                 //         return _connectionStatus == ConnectivityResult.none
//                 //             ? Center(
//                 //           child: Column(
//                 //             children: [
//                 //               SizedBox(
//                 //                   height:
//                 //                   MediaQuery.of(context).size.height * .15),
//                 //               Image.asset(
//                 //                 "assets/images/no_connection.png",
//                 //                 height: MediaQuery.of(context).size.height * .35,
//                 //               ),
//                 //               const Padding(
//                 //                 padding: EdgeInsets.all(4.0),
//                 //                 child: Text('There is no Internet connection'),
//                 //               ),
//                 //               const Padding(
//                 //                 padding: EdgeInsets.all(4.0),
//                 //                 child:
//                 //                 Text('Please check your Internet connection'),
//                 //               ),
//                 //             ],
//                 //           ),
//                 //         )
//                 //             : const Center(
//                 //           child: Text('Error Occured'),
//                 //           // child: Text(dataSnapshot.error.toString()),
//                 //         );
//                 //       } else {
//                 //         if(_isLoading){
//                 //           return Center(child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)));
//                 //         } else {
//                 //           return Container();
//                 //         }
//                 //       }
//                 //     }
//                 //   },
//                 // ),
//                 showLoader()
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:academy_app/constants.dart';
import 'package:academy_app/models/config_data.dart';
import 'package:academy_app/providers/config.dart';
import 'package:academy_app/screens/auth_screen_private.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/base_url_global_helper.dart';
import '../Utils/deeplink_gate.dart';
import '../providers/shared_pref_helper.dart';
import 'tabs_screen.dart';
import '../api/api_client.dart';


/// -------- Developer Options guard (Flutter side) --------
const _devCh = MethodChannel('app.security.devoptions');
// TOP: imports ke niche hi yeh key add karo
const _kDevGateEnforceKey = 'dev_gate_enforce';
/// Build-time flag (can be overridden via --dart-define)
/// if true then show developer Option and false off developer option
const bool kEnforceDevGateDefault =
bool.fromEnvironment('ENFORCE_DEV_GATE', defaultValue: false);

Future<bool> _isDevOn() async {
  try {
    final v = await _devCh.invokeMethod<bool>('isDevOptionsEnabled');
    return v == true;
  } catch (_) {
    return false;
  }
}

Future<void> _openDevSettings() async {
  try { await _devCh.invokeMethod('openDevOptions'); } catch (_) {}
}

/// --------------------------------------------------------


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  dynamic courseAccessibility;
  var _isInit = true;
  var _isLoading = false;
  ConfigData configData = ConfigData();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  bool _didNavigate = false; // ensure single-shot default nav
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _autoNavTimer;          // 👈 default navigation timer

  bool _devBlocked = false;
  Timer? _devPoll;
  // NEW: tester flag (default: true = enforce gate)
  bool _enforceDevGate = true;

  bool _openedFromNotification = false;


  // NEW: load/save flag helpers
  Future<void> _loadEnforceFlag() async {
    final p = await SharedPreferences.getInstance();
    // default true = enforce
    final v = p.getBool(_kDevGateEnforceKey) ?? kEnforceDevGateDefault;
    if (mounted) setState(() => _enforceDevGate = v);
  }

  Future<void> _setEnforceFlag(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDevGateEnforceKey, v);
    if (!mounted) return;
    setState(() => _enforceDevGate = v);
    // flag change par dobara check
    _checkDevNow();
  }


  Future<void> _checkDevNow() async {
    // ⚠️ Agar enforce OFF hai → kabhi block mat karo
    if (!_enforceDevGate) {
      if (!mounted) return;
      setState(() => _devBlocked = false);
      _devPoll?.cancel();
      return;
    }

    final on = await _isDevOn();
    if (!mounted) return;
    setState(() => _devBlocked = on);

    _devPoll?.cancel();
    // optional: jab tak ON hai, har 2s me re-check
    if (on) {
      _devPoll = Timer.periodic(const Duration(seconds: 2), (_) async {
        final again = await _isDevOn();
        if (!mounted) return;
        if (!again) {
          setState(() => _devBlocked = false);
          _devPoll?.cancel();
          // ✅ ADD THIS: resume normal flow once Dev Options are OFF
          if (mounted) donLogin();
        }
      });
    }

  }


  /// Guarded navigate helper: dev ON hai to navigation block karo
  Future<bool> _devGateBeforeNavigate() async {

    // ⚠️ Enforce OFF → navigation allow
    if (!_enforceDevGate) return true;
    if (_devBlocked) {
      // optional toast/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn off Developer Options to continue')),
      );
      return false;
    }
    // double-check just before navigating
    final on = await _isDevOn();
    if (on) {
      setState(() => _devBlocked = true);
      return false;
    }
    return true;
  }




  systemSettings() async {
    var url = "$BASE_URL/api/system_settings";
    var response = await ApiClient().get(url);
    debugPrint(response.toString());
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        courseAccessibility = data['course_accessibility'];
      });
    } else {
      setState(() {
        courseAccessibility = '';
      });
    }
  }
  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print(e.toString());
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }
  @override
  void initState() {
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    /// ✅ Yaha config set kar rahe hain ApiBase me
    ApiBase.setConfig(configData);

    systemSettings();
    super.initState();

    // 2) Start DevOptions check/poll
    _loadEnforceFlag().then((_) => _checkDevNow());

    DeepLinkGate.tookControl.addListener(() {
      if (DeepLinkGate.tookControl.value) {
        _autoNavTimer?.cancel();
        _didNavigate = true; // ensure splash khud kuch na kare
        debugPrint('[SPLASH] DeepLinkGate -> cancel auto nav');
      }
    });

    // 🔽 Add this block
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('💡 App opened via notification');
        _openedFromNotification = true;
      }
      // call donLogin after checking
      donLogin();
    });


  }



  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void donLogin() {
    // 1) Deep link ya notification ne control liya ho to skip
    if (DeepLinkGate.tookControl.value) {
      debugPrint('[SPLASH] deep link handled -> skip default nav');
      return;
    }
    if (_openedFromNotification) {
      debugPrint('[SPLASH] opened from notification -> skip default nav');
      return;
    }
    if (_didNavigate) return;

    // 2) Schedule default nav after 3s, but cancelable
    _autoNavTimer?.cancel();
    _autoNavTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted || _didNavigate) return;

      // Re-check just before firing
      if (DeepLinkGate.tookControl.value) {
        debugPrint('[SPLASH] (timer) deep link handled -> abort');
        return;
      }

      // Agar already koi route stack me push ho chuka hai (deep link/notification), abort
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        debugPrint('[SPLASH] (timer) navigator.canPop == true -> abort default nav');
        return;
      }

      final canGo = await _devGateBeforeNavigate();
      if (!canGo || !mounted) return;

      final token = await SharedPreferenceHelper().getAuthToken();
      if (!mounted) return;
      _didNavigate = true;

      if (token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) =>  TabsScreen(index: 0)),
        );
      } else {
        if (courseAccessibility == 'publicly') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) =>  TabsScreen(index: 0)),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreenPrivate()),
          );
        }
      }
    });
  }


  // void donLogin() {
  //
  //   if (_openedFromNotification) {
  //     debugPrint('⏭️ Skip auto navigation because app opened via notification');
  //     return; // do nothing, let notification routing handle it
  //   }
  //
  //   String? token;
  //   Future.delayed(const Duration(seconds: 3), () async {
  //     token = await SharedPreferenceHelper().getAuthToken();
  //     if (token != null && token!.isNotEmpty) {
  //       Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (context) => TabsScreen(index: 0,)));
  //     } else {
  //       if (courseAccessibility == 'publicly') {
  //         Navigator.of(context).pushReplacement(
  //             MaterialPageRoute(builder: (context) => TabsScreen(index: 0,)));
  //       } else {
  //         Navigator.of(context).pushReplacement(MaterialPageRoute(
  //             builder: (context) => const AuthScreenPrivate()));
  //       }
  //     }
  //   });
  // }


  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<Config>(context).fetchConfigData().then((_) {
        setState(() {
          _isLoading = false;
          configData = Provider.of<Config>(context, listen: false).configItems;


        });
      });
    }
    setData();
    _isInit = false;
    super.didChangeDependencies();
  }

  setData() async{
    // await  Provider.of<Config>(context).fetchConfigData();
    // configData = Provider.of<Config>(context, listen: false).configItems;
    // _isLoading = false;
    if(configData.appname?.isNotEmpty ?? false) {
      await SharedPreferenceHelper().setConfigData(json.encode(configData));
    }
  }
  showLoader(){
    return _connectionStatus == ConnectivityResult.none
        ? Center(child: Column(
      //     children: [
      //         SizedBox(
      //             height:
      //             MediaQuery.of(context).size.height * .15),
      //         Image.asset(
      //           "assets/images/no_connection.png",
      //           height: MediaQuery.of(context).size.height * .35,
      //         ),
      //         const Padding(
      //           padding: EdgeInsets.all(4.0),
      //           child: Text('There is no Internet connection'),
      //         ),
      //         const Padding(
      //           padding: EdgeInsets.all(4.0),
      //           child:
      //           Text('Please check your Internet connection'),
      //         ),
      // ],
    ),) : Center(child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)));
  }

  @override
  Widget build(BuildContext context) {

    // Agar Developer Options ON hai → blocking UI (no navigation)
    if (_enforceDevGate && _devBlocked) {
      return Scaffold(
        backgroundColor: Color(0xff003840), // Dim background
        body: SafeArea(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB3261E),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Developer Options Enabled',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'For your security, this app cannot run while Developer Options or USB Debugging are enabled. Please disable them to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _openDevSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Developer Options'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff005E6A),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => SystemNavigator.pop(),
                        child: const Text(
                          'Exit App',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                    height: 240,
                    width: 240,
                    'assets/images/logo.png'),
                const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text('Learn, Practice & Upskill'),
                ),
                const SizedBox(height: 8,),
                // FutureBuilder(
                //   future:
                //   Provider.of<Config>(context, listen: false).fetchConfigData(),
                //   builder: (ctx, dataSnapshot) {
                //     if (dataSnapshot.connectionState == ConnectionState.waiting) {
                //       return SizedBox(
                //         height: MediaQuery.of(context).size.height * .5,
                //         child: Center(
                //           child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
                //         ),
                //       );
                //     } else {
                //       if (dataSnapshot.error != null) {
                //         //error
                //         return _connectionStatus == ConnectivityResult.none
                //             ? Center(
                //           child: Column(
                //             children: [
                //               SizedBox(
                //                   height:
                //                   MediaQuery.of(context).size.height * .15),
                //               Image.asset(
                //                 "assets/images/no_connection.png",
                //                 height: MediaQuery.of(context).size.height * .35,
                //               ),
                //               const Padding(
                //                 padding: EdgeInsets.all(4.0),
                //                 child: Text('There is no Internet connection'),
                //               ),
                //               const Padding(
                //                 padding: EdgeInsets.all(4.0),
                //                 child:
                //                 Text('Please check your Internet connection'),
                //               ),
                //             ],
                //           ),
                //         )
                //             : const Center(
                //           child: Text('Error Occured'),
                //           // child: Text(dataSnapshot.error.toString()),
                //         );
                //       } else {
                //         if(_isLoading){
                //           return Center(child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)));
                //         } else {
                //           return Container();
                //         }
                //       }
                //     }
                //   },
                // ),
                showLoader()
              ],
            ),
          ),
        ),
      ),
    );
  }
}


