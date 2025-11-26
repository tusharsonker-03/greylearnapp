// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:academy_app/models/config_data.dart';
import 'package:academy_app/providers/bundles.dart';
import 'package:academy_app/providers/shared_pref_helper.dart';
import 'package:academy_app/screens/auth_screen.dart';
import 'package:academy_app/screens/full_screen_popup.dart';
import 'package:academy_app/screens/webview_screen.dart';
import 'package:academy_app/widgets/bundle_grid.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/image_cache.dart';
import '../Utils/link_navigator.dart';
import '../Utils/subscription_popup.dart';
import '../models/course.dart';
import '../providers/categories.dart';
import '../providers/config.dart';
import '../widgets/category_list_item.dart';
import '../widgets/course_grid.dart';
import '../providers/courses.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import 'bundle_list_screen.dart';
import 'course_detail_screen.dart';
import 'course_section.dart';
import 'courses_screen.dart';
import '../models/common_functions.dart';
import '../api/api_client.dart';
import 'newcoursedetail_landing_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _isInit = true;
  var _isLoading = false;
  var topCourses = [];
  List<Course> jobCourses = [];
  List<Course> certCourses = [];
  var bundles = [];
  dynamic bundleStatus;
  ConfigData configData = ConfigData();
  // var version = 0;
  String version = "0.0.0"; // default value

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<bool> _isLoggedIn() async {
    final token = await SharedPreferenceHelper().getAuthToken();
    return token != null && token.toString().trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    addonStatus();
    initConnectivity();
    getConfigData();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // // showForceUpdatePopup();
    // showForceUpdatePopup().then((_) {
    //   showMaintenancePopup(); // maintenance check yahan call karega
    // });

    checkAppStatus();
    loadConfigAndHandlePopups();
  }

  // put inside _HomeScreenState
  String _serverVersionForThisPlatform() {
    // Android side: configData.android_version
    // iOS side:     configData.ios_version  (← API me yahi key honi chahiye)
    final androidV = configData.android_version?.trim();
    final iosV = configData.ios_version?.trim();
    print('Android Version: $androidV');
    print('Ios Version: $iosV');

    if (Platform.isIOS) {
      return (iosV == null || iosV.isEmpty) ? "0.0.0" : iosV;
    } else {
      // Android or others default to android rules
      return (androidV == null || androidV.isEmpty) ? "0.0.0" : androidV;
    }
  }

  Future<void> loadConfigAndHandlePopups() async {
    await getConfigData(); // wait for configData to load
    if (!mounted) return;

    // ab sequence me popup call karo
    await handleAppStatus();
  }

  Future<void> handleAppStatus() async {
    if (configData == null) return;

    String currentVersion = version.toString().trim();
    final String serverVersion = _serverVersionForThisPlatform(); // 👈 NEW

    print("Current version : $currentVersion");
    print("Server version : $serverVersion");

    int result = compareVersions(currentVersion, serverVersion);

    //  Force update check
    if (result < 0) {
      await CommonFunctions.showForceUpdateDialog(
          configData.whatsnew ?? "", context);

      // Force update ke baad maintenance check
      if (configData.underMaintenance == true) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) await showMaintenancePopup();
      }
      return;
    }

    // 🔵 Maintenance check
    if (configData.underMaintenance == true) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) await showMaintenancePopup();
      return; // maintenance popup ke baad subscription na dikhao
    }

    // ✅ Subscription popup -> ONLY IF LOGGED IN (ANDROID ONLY)
    ////10 min
    // if (!Platform.isIOS && (configData.subscription?.popup ?? false)) {
    //   final loggedIn = await _isLoggedIn();
    //   if (loggedIn) {
    //     int delay =
    //     int.parse(configData.subscription?.popupshowduration ?? "0");
    //     await Future.delayed(Duration(seconds: delay));
    //     if (mounted) SubscriptionDialog.show(context, configData.subscription!);
    //   } else {
    //     debugPrint("🔐 Skip subscription popup: user not logged in");
    //   }
    // } else {
    //   if (Platform.isIOS) {
    //     debugPrint("🍎 iOS detected → subscription popup disabled");
    //   }
    // }
// 10 min

  }

  /// verion 1.2.3

  Future<void> getConfigData() async {
    dynamic data = await SharedPreferenceHelper().getConfigData();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    if (data != null) {
      setState(() {
        configData = ConfigData.fromJson(json.decode(data));
        version = packageInfo.version;
      });
    }
  }

  setData() async {
    if (configData.appname?.isNotEmpty ?? false) {
      await SharedPreferenceHelper().setConfigData(json.encode(configData));
    }

    getConfigData();
  }

  Future<void> checkAppStatus() async {
    String currentVersion = version.toString().trim();
    final String serverVersion = _serverVersionForThisPlatform(); // 👈 NEW

    print(' Current Version : $currentVersion');
    print(" Serververion : $serverVersion");

    int result = compareVersions(currentVersion, serverVersion);

    if (result < 0) {
      //  Force Update required
      await CommonFunctions.showForceUpdateDialog(
        configData.whatsnew ?? "",
        context,
      );

      //  Force Update dialog बंद होने के बाद ही Maintenance popup check होगा
      if (configData.underMaintenance == true) {
        // 1 minute delay डालो ताकि overlap न हो
        await Future.delayed(const Duration(minutes: 1));
        if (mounted) showMaintenancePopup();
      }
    } else {
      //  Version OK -> Maintenance check
      if (configData.underMaintenance == true) {
        await Future.delayed(const Duration(minutes: 3));
        if (mounted) showMaintenancePopup();
      } else {
        //10 min
        // // ✅ normal flow -> subscription popup (ANDROID ONLY)
        // if (!Platform.isIOS && (configData.subscription?.popup ?? false)) {
        //   await Future.delayed(Duration(
        //     seconds:
        //     int.parse(configData.subscription?.popupshowduration ?? "0"),
        //   ));
        //   if (mounted) {
        //     SubscriptionDialog.show(context, configData.subscription!);
        //   }
        // } else if (Platform.isIOS) {
        //   debugPrint("🍎 iOS: subscription popup suppressed");
        // }
        //10min
      }
    }
  }
  //       // ✅ normal flow -> subscription popup
  //       if (configData.subscription?.popup ?? false) {
  //         await Future.delayed(Duration(
  //           seconds: int.parse(configData.subscription?.popupshowduration ?? "0"),
  //         ));
  //         if (mounted) {
  //           SubscriptionDialog.show(context, configData.subscription!);
  //         }
  //       }
  //     }
  //   }
  // }

// helper function to compare semantic versions
  int compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      if (v1Parts[i] < v2Parts[i]) return -1;
      if (v1Parts[i] > v2Parts[i]) return 1;
    }
    return 0;
  }

  showForceUpdatePopup() async {
    await Future.delayed(const Duration(seconds: 5));

    String currentVersion = version.toString().trim(); // app version string
    final String serverVersion = _serverVersionForThisPlatform(); // 👈 NEW

    int result = compareVersions(currentVersion, serverVersion);

    if (result < 0) {
      // app purana hai
      CommonFunctions.showForceUpdateDialog(configData.whatsnew ?? "", context);
    } else if (result == 0) {
      // same version => kuch mat karo
      debugPrint("✅ App up to date hai ($currentVersion)");
    } else {
      // app naya ya barabar hai => subscription popup (ANDROID ONLY)
      // 🔴 HOME SCREEN SE SUBSCRIPTION POPUP DISABLE KAR DIYA
// 10 min
      // if (!Platform.isIOS && (configData.subscription?.popup ?? false)) {
      //   await Future.delayed(Duration(
      //       seconds:
      //       int.parse(configData.subscription?.popupshowduration ?? "0")));
      //   if (mounted) {
      //     SubscriptionDialog.show(context, configData.subscription!);
      //   }
      // } else if (Platform.isIOS) {
      //   debugPrint("🍎 iOS: subscription popup suppressed");
      // }
      //10 min
    }
  }
  //     // app naya ya barabar hai => subscription popup check
  //     if (configData.subscription?.popup ?? false) {
  //       await Future.delayed(Duration(
  //           seconds:
  //               int.parse(configData.subscription?.popupshowduration ?? "0")));
  //       if (mounted) {
  //         SubscriptionDialog.show(context, configData.subscription!);
  //       }
  //     }
  //   }
  // }

  // Under Maintenance pop up
  showMaintenancePopup() async {
    await Future.delayed(const Duration(seconds: 1));

    if (configData.underMaintenance == true) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false, // back press से close न हो
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            titlePadding: const EdgeInsets.all(16),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Row(
              children: const [
                Icon(Icons.build_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  "Under Maintenance",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            content: Text(
              (configData.underMaintenanceMessage ?? '')
                  .replaceAll("<br>", "")
                  .replaceAll("</br>", ""),
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  "Okay",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  SystemNavigator.pop(); // exit app
                },
              ),
            ],
          );
        },
      );
    }
  }

  //
  // Future<void> getConfigData() async {
  //   dynamic data = await SharedPreferenceHelper().getConfigData();
  //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //
  //   if (data != null) {
  //     setState(() {
  //       configData = ConfigData.fromJson(json.decode(data));
  //       version = int.tryParse((packageInfo.buildNumber ?? "")) ?? 0;
  //     });
  //   }
  // }
  // setData() async{
  //   if(configData.appname?.isNotEmpty ?? false) {
  //     await SharedPreferenceHelper().setConfigData(json.encode(configData));
  //   }
  //
  //   getConfigData();
  // }
  //
  // // app version update pop up
  // showForceUpdatePopup() async{
  //   await Future.delayed(const Duration(seconds: 5));
  //   if(version < (configData.version ?? 0)){
  //     CommonFunctions.showForceUpdateDialog(configData.whatsnew ?? "", context);
  //   }else{
  //     if(configData.subscription?.popup ?? false){
  //       await Future.delayed( Duration(seconds: int.parse(configData.subscription?.popupshowduration ?? "0")));
  //       if(mounted) {
  //         SubscriptionDialog.show(context, configData.subscription!);
  //       }
  //     }
  //   }
  // }

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

  Future<void> addonStatus() async {
    var url = '$BASE_URL/api/addon_status?unique_identifier=course_bundle';
    final response = await ApiClient().get(url);
    bundleStatus = json.decode(response.body)['status'];
  }



  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<Courses>(context).fetchTopCourses().then((_) {
        setState(() {
          _isLoading = false;
          topCourses = Provider.of<Courses>(context, listen: false).topItems;
        });
      });
      Provider.of<Courses>(context).fetchJobGuaranteeCourses().then((_) {
        setState(() {
          _isLoading = false;
          jobCourses =
              Provider.of<Courses>(context, listen: false).jCourseItems;
        });
      });
      Provider.of<Courses>(context).fetchCertificateCourses().then((_) {
        setState(() {
          _isLoading = false;
          certCourses =
              Provider.of<Courses>(context, listen: false).cCourseItems;
        });
      });
      Provider.of<Courses>(context)
          .filterCourses('all', 'all', 'all', 'all', 'all');
      // Provider.of<Bundles>(context).fetchBundle(true).then((_) {
      //   setState(() {
      //     bundles = Provider.of<Bundles>(context, listen: false).bundleItems;
      //   });
      // });
      Provider.of<Config>(context).fetchConfigData().then((_) {
        setState(() {
          _isLoading = false;
          configData = Provider.of<Config>(context, listen: false).configItems;
          setData();
        });
      });
    }

    _isInit = false;
    super.didChangeDependencies();
  }

  Future<void> refreshList() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await Provider.of<Courses>(context, listen: false)
          .fetchCertificateCourses();
      await Provider.of<Courses>(context, listen: false)
          .fetchJobGuaranteeCourses();

      setState(() {
        _isLoading = false;
        jobCourses = Provider.of<Courses>(context, listen: false).jCourseItems;
        certCourses = Provider.of<Courses>(context, listen: false).cCourseItems;
      });
    } catch (error) {
      const errorMsg = 'Could not refresh!';
      CommonFunctions.showErrorDialog(errorMsg, context);
    }

    return;
  }

  Future<void> handleBannerTap(
      int index, Home homedata, BuildContext context) async {
    final token = await SharedPreferenceHelper().getAuthToken();
    if (index == 1) {
      LinkNavigator.instance.navigate(
          context,
          homedata.banner1?.link ?? '',
          homedata.banner1?.linktype ?? '',
          homedata.banner1!.link!.contains("https")
              ? 0
              : int.parse(homedata.banner1?.link ?? '0'),
          homedata.banner1?.authentication ?? false,
          token ?? '',
          CourseLandingPage.routeName);
    } else if (index == 2) {
      LinkNavigator.instance.navigate(
          context,
          homedata.banner2?.link ?? '',
          homedata.banner2?.linktype ?? '',
          homedata.banner2!.link!.contains("https")
              ? 0
              : int.parse(homedata.banner2?.link ?? '0'),
          homedata.banner2?.authentication ?? false,
          token ?? '',
          CourseLandingPage.routeName);
    } else if (index == 3) {
      LinkNavigator.instance.navigate(
          context,
          homedata.banner3?.link ?? '',
          homedata.banner3?.linktype ?? '',
          homedata.banner3!.link!.contains("https")
              ? 0
              : int.parse(homedata.banner3?.link ?? '0'),
          homedata.banner3?.authentication ?? false,
          token ?? '',
          CourseLandingPage.routeName);
    } else if (index == 4) {
      LinkNavigator.instance.navigate(
          context,
          homedata.banner4?.link ?? '',
          homedata.banner4?.linktype ?? '',
          homedata.banner4!.link!.contains("https")
              ? 0
              : int.parse(homedata.banner4?.link ?? '0'),
          homedata.banner4?.authentication ?? false,
          token ?? '',
          CourseLandingPage.routeName);
    } else {}
  }

  showBanner1(Home? homedata) {
    return (configData.home?.banner1?.link ?? "").isNotEmpty
        ? SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          handleBannerTap(1, homedata!, context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget(homedata?.banner1?.image ?? "",
                cacheKey: 'home_banner1'),
            // child: FadeInImage.assetNetwork(
            //   placeholder: 'assets/images/loading_animated.gif',
            //   image: homedata.banner1?.image ?? "",
            //   fit: BoxFit.fitWidth,
            // ),
          ),
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  Widget imageWidget(String imageUrl, {required String cacheKey}) {
    return FutureBuilder<ImageProvider>(
      future: SPImageCache.loadProvider(cacheKey, imageUrl),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return Skeletonizer(
            enabled: true,
            child: Container(
              width: double.infinity,
              height: 140, // approx banner height
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );          //   Center(
          //   child: SizedBox(
          //     width: double.infinity,
          //     height: 40,
          //     child: Image.asset('assets/images/loading_animated.gif'),
          //   ),
          // );
        }
        return Image(
          image: snap.data!,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }

  // imageWidget(String imageUrl){
  //   return Image.network(
  //     imageUrl ?? '',
  //     width: double.infinity,
  //     fit: BoxFit.cover,
  //     loadingBuilder: (context, child, progress) {
  //       if (progress == null) return child;
  //       return Center(
  //         child: SizedBox(
  //           width: double.infinity,
  //           height: 40,
  //           child: Image.asset('assets/images/loading_animated.gif'),
  //         ),
  //       );
  //     },
  //   );
  // }
  showBanner4(Home? homedata) {
    return (configData.home?.banner2?.link ?? "").isNotEmpty
        ? SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          handleBannerTap(4, homedata!, context);
        },
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageWidget(homedata?.banner4?.image ?? "",
                cacheKey: 'home_banner4'),
            // child: FadeInImage.assetNetwork(
            //   placeholder: 'assets/images/loading_animated.gif',
            //   image: homedata.banner4?.image ?? "",
            //   fit: BoxFit.fitWidth,
            // ),
          ),
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  showBanner3(Home? homedata) {
    return (configData.home?.banner3?.link ?? "").isNotEmpty ||
        (configData.home?.banner4?.link ?? "").isNotEmpty
        ? SizedBox(
      width: double.infinity,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  handleBannerTap(2, homedata!, context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageWidget(homedata?.banner2?.image ?? "",
                      cacheKey: 'home_banner2'),
                  // child: FadeInImage.assetNetwork(
                  //   placeholder: 'assets/images/loading_animated.gif',
                  //   image: homedata.banner2?.image ?? "",
                  //   fit: BoxFit.fitWidth,
                  // ),
                ),
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Flexible(
              child: GestureDetector(
                onTap: () {
                  handleBannerTap(3, homedata!, context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageWidget(homedata?.banner3?.image ?? "",
                      cacheKey: 'home_banner3'),
                  // child: FadeInImage.assetNetwork(
                  //   placeholder: 'assets/images/loading_animated.gif',
                  //   image: homedata.banner3?.image ?? "",
                  //   fit: BoxFit.fitWidth,
                  // ),
                ),
              ),
            )
          ],
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  navigateToWebView(String gotoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: gotoUrl),
      ),
    );
  }
  //
  // @override
  // Widget build(BuildContext context) {
  //   return RefreshIndicator(
  //     onRefresh: refreshList,
  //     child: SingleChildScrollView(
  //       child: FutureBuilder(
  //         future: Provider.of<Categories>(context, listen: false)
  //             .fetchCategories(),
  //         builder: (ctx, dataSnapshot) {
  //           if (dataSnapshot.connectionState == ConnectionState.waiting) {
  //             // 🔹 Categories load ho rahe hain → full home skeleton
  //             return const _HomeSkeleton();
  //           } else {
  //             if (dataSnapshot.error != null) {
  //               // 🔹 Error case
  //               return _connectionStatus == ConnectivityResult.none
  //                   ? Center(
  //                 child: Column(
  //                   children: [
  //                     SizedBox(
  //                       height:
  //                       MediaQuery.of(context).size.height * .15,
  //                     ),
  //                     Image.asset(
  //                       "assets/images/no_connection.png",
  //                       height:
  //                       MediaQuery.of(context).size.height * .35,
  //                     ),
  //                     const Padding(
  //                       padding: EdgeInsets.all(4.0),
  //                       child: Text('There is no Internet connection'),
  //                     ),
  //                     const Padding(
  //                       padding: EdgeInsets.all(4.0),
  //                       child: Text(
  //                           'Please check your Internet connection'),
  //                     ),
  //                   ],
  //                 ),
  //               )
  //                   : const Center(
  //                 child: Text('Error Occured'),
  //               );
  //             } else {
  //               // ✅ YAHAN REAL / SKELETON HOME CONTENT DECIDE KARNA HAI
  //
  //               // Agar abhi bhi courses nahi aaye ya loading flag ON hai
  //               if (_isLoading ||
  //                   certCourses.isEmpty ||
  //                   jobCourses.isEmpty) {
  //                 // 🔥 Jab tak course data nahi, sirf skeleton dikhayenge
  //                 return const _HomeSkeleton();
  //               }
  //
  //               // ✅ Ab REAL DATA wala UI
  //               return Column(
  //                 children: [
  //                   showBanner1(configData.home),
  //                   showBanner3(configData.home),
  //                   showBanner4(configData.home),
  //
  //                   CourseSection(
  //                     title: 'Certificate Courses',
  //                     courses: certCourses as List<Course>,
  //                     isLoading:
  //                     false, // yahan ab skeleton nahi chahiye, data aa chuka
  //                     onTapAll: () {
  //                       Navigator.of(context).pushNamed(
  //                         CoursesScreen.routeName,
  //                         arguments: {
  //                           'category_id': null,
  //                           'seacrh_query': null,
  //                           'type': CoursesPageData.All,
  //                         },
  //                       );
  //                     },
  //                   ),
  //
  //                   CourseSection(
  //                     title: 'Job Guarantee Courses',
  //                     courses: jobCourses as List<Course>,
  //                     isLoading: false,
  //                     onTapAll: () {
  //                       Navigator.of(context).pushNamed(
  //                         CoursesScreen.routeName,
  //                         arguments: {
  //                           'category_id': null,
  //                           'seacrh_query': null,
  //                           'type': CoursesPageData.All,
  //                         },
  //                       );
  //                     },
  //                   ),
  //                 ],
  //               );
  //             }
  //           }
  //         },
  //       ),
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshList,
      child: SingleChildScrollView(
        child: FutureBuilder(
          future:
          Provider.of<Categories>(context, listen: false).fetchCategories(),
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const _HomeSkeleton();

              // return SizedBox(
              //   height: MediaQuery.of(context).size.height * .5,
              //   child: Center(
              //     child: CircularProgressIndicator(
              //         color: kPrimaryColor.withOpacity(0.7)),
              //   ),
              // );
            } else {
              if (dataSnapshot.error != null) {
                //error
                return _connectionStatus == ConnectivityResult.none
                    ? Center(
                  child: Column(
                    children: [
                      SizedBox(
                          height:
                          MediaQuery.of(context).size.height * .15),
                      Image.asset(
                        "assets/images/no_connection.png",
                        height: MediaQuery.of(context).size.height * .35,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('There is no Internet connection'),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(4.0),
                        child:
                        Text('Please check your Internet connection'),
                      ),
                    ],
                  ),
                )
                    : const Center(
                  child: Text('Error Occured'),
                  // child: Text(dataSnapshot.error.toString()),
                );
              } else {
                // pehle Column ko ek variable me banao
                final homeCoursesContent = Column(
                  children: [
                    showBanner1(configData.home),
                    showBanner3(configData.home),
                    showBanner4(configData.home),

                    CourseSection(
                      title: 'Certificate Courses',
                      courses: certCourses as List<Course>,
                      isLoading: _isLoading, // 👈 ye bhi rakho
                      onTapAll: () {
                        Navigator.of(context).pushNamed(
                          CoursesScreen.routeName,
                          arguments: {
                            'category_id': null,
                            'seacrh_query': null,
                            'type': CoursesPageData.All,
                          },
                        );
                      },
                    ),

                    CourseSection(
                      title: 'Job Guarantee Courses',
                      courses: jobCourses as List<Course>,
                      isLoading: _isLoading,
                      onTapAll: () {
                        Navigator.of(context).pushNamed(
                          CoursesScreen.routeName,
                          arguments: {
                            'category_id': null,
                            'seacrh_query': null,
                            'type': CoursesPageData.All,
                          },
                        );
                      },
                    ),
                  ],
                );

// 🔥 yahi se return karo – _isLoading true hoga to skeletonizer chalega
                return _isLoading
                    ? Skeletonizer(
                  enabled: true,
                  child: homeCoursesContent,
                )
                    : homeCoursesContent;

                // return Column(
                //   children: [
                //     showBanner1(configData.home),
                //     showBanner3(configData.home),
                //     showBanner4(configData.home),
                //     CourseSection(
                //       title: 'Certificate Courses',
                //       courses: certCourses as List<Course>,
                //       isLoading: _isLoading,
                //       onTapAll: () {
                //         Navigator.of(context).pushNamed(
                //           CoursesScreen.routeName,
                //           arguments: {
                //             'category_id': null,
                //             'seacrh_query': null,
                //             'type': CoursesPageData.All,
                //           },
                //         );
                //       },
                //     ),
                //     CourseSection(
                //       title: 'Job Guarantee Courses',
                //       courses: jobCourses as List<Course>,
                //       isLoading: _isLoading,
                //       onTapAll: () {
                //         Navigator.of(context).pushNamed(
                //           CoursesScreen.routeName,
                //           arguments: {
                //             'category_id': null,
                //             'seacrh_query': null,
                //             'type': CoursesPageData.All,
                //           },
                //         );
                //       },
                //     ),
                //   ],
                // );
              }
            }
          },
        ),
      ),
    );
  }
}
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 🔹 Top big banner skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 2 small banner row skeleton (banner2 + banner3)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Bottom banner skeleton (banner4)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // 🔹 Certificate Courses section skeleton (6 cards)
          const _SkeletonCourseSection(title: 'Certificate Courses'),

          // 🔹 Job Guarantee Courses section skeleton (6 cards)
          const _SkeletonCourseSection(title: 'Job Guarantee Courses'),
        ],
      ),
    );
  }
}


/// 6 skeleton course cards wale section ke liye
/// 6 skeleton course cards wale section ke liye
class _SkeletonCourseSection extends StatelessWidget {
  final String title;
  const _SkeletonCourseSection({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Title + "All courses >" row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF003840),
                  ),
                ),
                const Text(
                  'All courses  >',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF005E6A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 🔹 Horizontal list of 6 skeleton cards
          SizedBox(
            height: 260, // approx real card height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              padding: const EdgeInsets.only(right: 4),
              itemBuilder: (_, index) {
                return Container(
                  width: 220, // approx real card width
                  margin: EdgeInsets.only(
                    right: index == 5 ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔸 Top banner (course image placeholder)
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xffe5ebeb),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🔸 Course title
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Course title placeholder',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003840),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 🔸 (optional) small text under title (like duration / tag)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Subtitle / tag',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 🔸 Rating + Price row (⭐ + "Free" right side)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Color(0xFFFFC107),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '5.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF003840),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '(0)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Free',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003840),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
