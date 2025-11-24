// ignore_for_file: unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:academy_app/models/config_data.dart';
import 'package:academy_app/providers/auth.dart';
import 'package:academy_app/screens/account_remove_screen.dart';
import 'package:academy_app/widgets/account_list_tile.dart';
import 'package:academy_app/widgets/custom_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Utils/link_navigator.dart';
import '../Utils/simple_progress_bar.dart';
import '../Utils/subscription_popup.dart';
import '../constants.dart';
import '../providers/database_helper.dart';
import '../providers/shared_pref_helper.dart';
import 'edit_password_screen.dart';
import 'edit_profile_screen.dart';
import '../api/api_client.dart';
import '../api/api_client.dart';
import 'newcoursedetail_landing_page.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  // final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  dynamic courseAccessibility;
  ConfigData configData = ConfigData();

  systemSettings() async {
    var url = "$BASE_URL/api/system_settings";
    var response = await ApiClient().get(url);
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

  List<int> courseArr = [];

  Future<List<Map<String, dynamic>>?> getVideos() async {
    List<Map<String, dynamic>> listMap =
        await DatabaseHelper.instance.queryAllRows('video_list');
    setState(() {
      for (var map in listMap) {
        File checkPath = File("${map['path']}/${map['title']}");
        if (checkPath.existsSync()) {
          courseArr.add(map['course_id']);
        } else {
          DatabaseHelper.instance.removeVideo(map['id']);
        }
      }
    });
    return null;
  }

  Future<void> getConfigData() async {
    dynamic data = await SharedPreferenceHelper().getConfigData();
    if (data != null) {
      setState(() {
        configData = ConfigData.fromJson(json.decode(data));
      });
    }
  }

  Future<List<Map<String, dynamic>>?> getCourse() async {
    List<Map<String, dynamic>> listMap =
        await DatabaseHelper.instance.queryAllRows('course_list');

    for (var map in listMap) {
      if (!courseArr.contains(map['course_id'])) {
        await DatabaseHelper.instance.removeCourse(map['course_id']);
        await DatabaseHelper.instance.removeCourseSection(map['course_id']);
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    // initConnectivity();
    getVideos();
    getCourse();
    systemSettings();
    getConfigData();
    // _connectivitySubscription =
    //     _connectivity.onConnectivityChanged.listen(_updateConnectionStatus as void Function(List<ConnectivityResult> event)?) as StreamSubscription<ConnectivityResult>;
  }

  // Future<void> initConnectivity() async {
  //   late ConnectivityResult result;

  //   try {
  //     result = (await _connectivity.checkConnectivity()) as ConnectivityResult;
  //   } on PlatformException catch (e) {
  //     // ignore: avoid_print
  //     print(e.toString());
  //     return;
  //   }

  //   if (!mounted) {
  //     return Future.value(null);
  //   }

  //   return _updateConnectionStatus(result);
  // }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  Color _getTextColor(Set<WidgetState> states) => states.any(<WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      }.contains)
          ? Colors.green
          : kPrimaryColor;

  @override
  void dispose() {
    // _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Provider.of<Auth>(context, listen: false).getUserInfo(),
        builder: (ctx, dataSnapshot) {
          if (dataSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                  color: kPrimaryColor.withOpacity(0.7)),
            );
          } else {
            if (dataSnapshot.error != null) {
              //error
              return _connectionStatus == ConnectivityResult.none
                  ? Center(
                      child: Column(
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * .15),
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
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: ElevatedButton.icon(
                          //     onPressed: () {
                          //       Navigator.push(context,
                          //           MaterialPageRoute(builder: (context) {
                          //         return const DownloadedCourseList();
                          //       }));
                          //     },
                          //     style: ButtonStyle(
                          //         backgroundColor:
                          //             WidgetStateColor.resolveWith(
                          //                 _getTextColor)),
                          //     icon: const Icon(Icons.download_done_rounded),
                          //     label: const Text(
                          //       'Play offline courses',
                          //       style: TextStyle(color: Colors.white),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: () {
                            Provider.of<Auth>(context, listen: false)
                                .logout()
                                .then((_) => Navigator.pushNamedAndRemoveUntil(
                                    context, '/home', (r) => false));
                          },
                        ),
                        const Center(
                          child: Text('Error Occurred'),
                        ),
                      ],
                    );
            } else {
              return Consumer<Auth>(builder: (context, authData, child) {
                final user = authData.user;
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(
                                height: 10,
                              ),
                              CircleAvatar(
                                radius: 55,
                                backgroundImage:
                                    NetworkImage(user.image.toString()),
                                backgroundColor: kLightBlueColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: CustomText(
                                  text: '${user.firstName} ${user.lastName}',
                                  colors: kTextColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CustomText(
                                      text: '${user.careerNavigatorTitle}',
                                      colors: kSecondaryColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 12.0, right: 12.0),
                                      child: AnimatedSimpleProgressBar(
                                        targetPercent: double.tryParse(
                                                '${user.careerNavigatorProgress}') ??
                                            0, // animate from 0 → 100%
                                        duration: const Duration(seconds: 3),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Card(
                                      color: kPrimaryColor.withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0.1,
                                      child: GestureDetector(
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CustomText(
                                                text: "View Details",
                                                colors: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          final token =
                                              await SharedPreferenceHelper()
                                                  .getAuthToken();
                                          final url =
                                              '$BASE_URL/home/career_navigator';
                                          LinkNavigator.instance.navigate(
                                              context,
                                              url,
                                              'external',
                                              0,
                                              true,
                                              token ?? '',
                                              '');
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              SizedBox(
                                height: 60,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0.1,
                                    child: GestureDetector(
                                      child: const AccountListTile(
                                        titleText: 'Edit Profile',
                                        icon: Icons.account_circle,
                                        actionType: 'edit',
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                            EditProfileScreen.routeName);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              // SizedBox(
                              //   height: 60,
                              //   child: Padding(
                              //     padding: const EdgeInsets.only(left: 10, right: 10),
                              //     child: Card(
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(10),
                              //       ),
                              //       elevation: 0.1,
                              //       child: GestureDetector(
                              //         child: const AccountListTile(
                              //           titleText: 'Downloaded Course',
                              //           icon: Icons.file_download_outlined,
                              //           actionType: 'downloaded_course',
                              //         ),
                              //         onTap: () {
                              //           Navigator.of(context).pushNamed(
                              //               DownloadedCourseList.routeName);
                              //         },
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              SizedBox(
                                height: 60,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0.1,
                                    child: GestureDetector(
                                      child: const AccountListTile(
                                        titleText: 'Change Password',
                                        icon: Icons.vpn_key,
                                        actionType: 'change_password',
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                            EditPasswordScreen.routeName);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 60,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0.1,
                                    child: GestureDetector(
                                      child: const AccountListTile(
                                        titleText: 'Delete Your Account',
                                        icon: Icons.person_remove_outlined,
                                        actionType: 'account_delete',
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                            AccountRemoveScreen.routeName);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 60,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0.1,
                                    child: GestureDetector(
                                      child: AccountListTile(
                                        titleText: 'Log Out',
                                        icon: Icons.exit_to_app,
                                        actionType: 'logout',
                                        courseAccessibility:
                                            courseAccessibility,
                                      ),
                                      onTap: () {
                                        // Show confirmation dialog
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              title:
                                                  const Text("Confirm Logout"),
                                              content: const Text(
                                                  "Are you sure you want to log out?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close dialog
                                                  },
                                                  child: const Text(
                                                    "No",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close dialog first
                                                    // Perform logout
                                                    if (courseAccessibility ==
                                                        'publicly') {
                                                      Provider.of<Auth>(context,
                                                              listen: false)
                                                          .logout()
                                                          .then((_) => Navigator
                                                                  .pushNamedAndRemoveUntil(
                                                                context,
                                                                '/home',
                                                                (r) => false,
                                                              ));
                                                    } else {
                                                      Provider.of<Auth>(context,
                                                              listen: false)
                                                          .logout()
                                                          .then((_) => Navigator
                                                                  .pushNamedAndRemoveUntil(
                                                                context,
                                                                '/auth-private',
                                                                (r) => false,
                                                              ));
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Yes",
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // SizedBox(
                              //   height: 60,
                              //   child: Padding(
                              //     padding: const EdgeInsets.only(left: 10, right: 10),
                              //     child: Card(
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(10),
                              //       ),
                              //       elevation: 0.1,
                              //       child: GestureDetector(
                              //         child: AccountListTile(
                              //           titleText: 'Log Out',
                              //           icon: Icons.exit_to_app,
                              //           actionType: 'logout',
                              //           courseAccessibility: courseAccessibility,
                              //         ),
                              //         onTap: () {
                              //           if (courseAccessibility == 'publicly') {
                              //             Provider.of<Auth>(context, listen: false)
                              //                 .logout()
                              //                 .then((_) =>
                              //                     Navigator.pushNamedAndRemoveUntil(
                              //                         context,
                              //                         '/home',
                              //                         (r) => false));
                              //           } else {
                              //             Provider.of<Auth>(context, listen: false)
                              //                 .logout()
                              //                 .then((_) =>
                              //                     Navigator.pushNamedAndRemoveUntil(
                              //                         context,
                              //                         '/auth-private',
                              //                         (r) => false));
                              //           }
                              //         },
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    showBannerProfile()
                  ],
                );
              });
            }
          }
        });
  }

  showBannerProfile() {
    // iOS → banner hide + no subscription tap
    if (Platform.isIOS) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        SubscriptionDialog.show(context, configData.subscription!);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            configData.profilebanner?.image ?? '',
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.asset('assets/images/loading_animated.gif'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
