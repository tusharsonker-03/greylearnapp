// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:skeletonizer/skeletonizer.dart';
import '../Utils/link_navigator.dart';
import '../api/api_client.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../models/common_functions.dart';
import '../models/notifications.dart';
import '../providers/auth.dart';
import '../providers/notification_counter.dart';
import '../providers/shared_pref_helper.dart';
import '../widgets/app_bar_two.dart';

class NotificationScreen extends StatefulWidget {
  static const routeName = '/notification_screen';
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  var _isInit = true;
  var _isLoading = false;
  List<Notifications> notificationList = [];

  getNotificationApi() async {
    _isLoading = true;
    final token = await SharedPreferenceHelper().getAuthToken();
    var url = "$BASE_URL/api/notifications?auth_token=$token";
    var response = await ApiClient().get(url);
    final extractedData = json.decode(response.body) as List;
    // ignore: unnecessary_null_comparison
    if (extractedData.isEmpty || extractedData == null) {
      setState(() {
        notificationList = [];
        _isLoading = false;
      });
    }else {
      setState(() {
        notificationList = buildNotificationsList(extractedData);
        _isLoading = false;
      });
      Provider.of<NotificationCounter>(context,listen: false)
          .updateCount(int.parse(("0").toString()));
    }
  }

  @override
  void initState() {
    super.initState();
    getNotificationApi();
  }
  List<Notifications> buildNotificationsList(List extractedData) {
    final List<Notifications> loadData = [];
    for (var notificationData in extractedData) {
      loadData.add(Notifications(id: notificationData['id'],title:notificationData['title'],description:notificationData['description'],createdAt: notificationData['created_at'],redirectType: notificationData['redirect_type'].toString(),redirectSection: notificationData['redirect_section'].toString(),redirectIdOrUrl: notificationData['redirect_id_or_url'].toString(),authentication:notificationData['authentication'].toString() ));
      print(notificationData['title']);
    }
    return loadData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: const CustomAppBarTwo(),
      body:
      _isLoading     ? const _NotificationSkeletonList()

          : notificationList.isNotEmpty ?
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Notification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (ctx, index) {
                  return GestureDetector(
                    onTap: () async {
                      final token = await SharedPreferenceHelper().getAuthToken();
                      LinkNavigator.instance.navigateFromNotification(context, notificationList[index].redirectType, notificationList[index].redirectSection, notificationList[index].redirectIdOrUrl, notificationList[index].authentication,token!);
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0.1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0,right: 16.0,top: 8.0,bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(
                                  size: 18,
                                  Icons.check_box,
                                  color: Colors.green,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    notificationList[index].title ?? "",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),

                            // ListTile(
                            //   leading: const Icon(
                            //     size: 18,
                            //     Icons.check_box,
                            //     color: Colors.green,
                            //   ),
                            //   minTileHeight:26,
                            //   title: Text(
                            //     notificationList[index].title ?? "",
                            //     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            //   ),
                            // ),
                            notificationList[index].description.contains('<') ?
                            Html(data:notificationList[index].description,shrinkWrap: true,) :
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                notificationList[index].description ?? "",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                notificationList[index].createdAt ?? "",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                itemCount: notificationList.length ?? 0,
              ),
            )
          ],
        ),
      ) :  const Center(child: Text('No data found!')),
    );
  }

  // buildPopupDialog(BuildContext context) {
  //   // ignore: no_leading_underscores_for_local_identifiers
  //   StateSetter _setState;
  //   return AlertDialog(
  //     backgroundColor: kBackgroundColor,
  //     titlePadding: EdgeInsets.zero,
  //     title: const Padding(
  //       padding: EdgeInsets.only(left: 15.0, right: 15, top: 10),
  //       child: Text('Notifying',
  //           style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
  //     ),
  //     contentPadding: EdgeInsets.zero,
  //     content: StatefulBuilder(
  //       builder: (BuildContext context, StateSetter setState) {
  //         _setState = setState;
  //         return Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: <Widget>[
  //             const Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
  //               child: Text(
  //                   'To remove your account provide your account password.',
  //                   style: TextStyle(fontSize: 13)),
  //             ),
  //             Padding(
  //               padding:
  //                   const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //               child: TextFormField(
  //                 style: const TextStyle(fontSize: 12),
  //                 obscureText: hidePassword,
  //                 decoration: InputDecoration(
  //                   enabledBorder: kDefaultInputBorder,
  //                   focusedBorder: kDefaultFocusInputBorder,
  //                   focusedErrorBorder: kDefaultFocusErrorBorder,
  //                   errorBorder: kDefaultFocusErrorBorder,
  //                   filled: true,
  //                   hintStyle: const TextStyle(color: kFormInputColor),
  //                   hintText: 'password',
  //                   fillColor: Colors.white70,
  //                   prefixIcon: const Icon(
  //                     Icons.key_outlined,
  //                     color: kFormInputColor,
  //                   ),
  //                   suffixIcon: IconButton(
  //                     onPressed: () {
  //                       _setState(() {
  //                         hidePassword = !hidePassword;
  //                       });
  //                     },
  //                     color: kTextLowBlackColor,
  //                     icon: Icon(hidePassword
  //                         ? Icons.visibility_off_outlined
  //                         : Icons.visibility_outlined),
  //                   ),
  //                   contentPadding: const EdgeInsets.symmetric(vertical: 5),
  //                 ),
  //                 controller: passwordController,
  //                 keyboardType: TextInputType.text,
  //                 validator: (value) {
  //                   if (value!.isEmpty) {
  //                     return 'Pssword cannot be empty';
  //                   }
  //                   return null;
  //                 },
  //                 onChanged: (value) {
  //                   _setState(() {
  //                     passwordController.text = value;
  //                   });
  //                 },
  //               ),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //     actions: <Widget>[
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 10.0),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               flex: 1,
  //               child: MaterialButton(
  //                 elevation: 0,
  //                 color: kRedColor,
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadiusDirectional.circular(6),
  //                   // side: const BorderSide(color: kPrimaryColor),
  //                 ),
  //                 child: const Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'No',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 10),
  //             Expanded(
  //               flex: 1,
  //               child: MaterialButton(
  //                 elevation: 0,
  //                 color: kPrimaryColor,
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //
  //                   accountDelete();
  //                 },
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadiusDirectional.circular(6),
  //                   // side: const BorderSide(color: kPrimaryColor),
  //                 ),
  //                 child: const Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Confirm',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //     ],
  //   );
  // }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Notification",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6, // 6 fake notifications
                itemBuilder: (context, index) =>
                const _NotificationSkeletonItem(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSkeletonItem extends StatelessWidget {
  const _NotificationSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0.1,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // icon + title line
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  size: 18,
                  Icons.check_box,
                  color: Colors.green,
                ),
                SizedBox(width: 4),
                Text(
                  'Notification title placeholder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            SizedBox(height: 4),
            // description
            Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text(
                'This is a short notification description placeholder.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4),
            // date
            Align(
              alignment: Alignment.topRight,
              child: Text(
                'Just now',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

