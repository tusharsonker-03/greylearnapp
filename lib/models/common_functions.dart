import 'dart:io';

import 'package:academy_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class CommonFunctions {
  static void showErrorDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred!'),
        content: Text(message, style: const TextStyle(color: Colors.red)),
        actions: <Widget>[
          MaterialButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  static Future<void> showForceUpdateDialog(String message, BuildContext context) {
    // ✅ apne store links yahan set karo
    const String androidUrl =
        "https://play.google.com/store/apps/details?id=com.greylearn.education";
    const String iosUrl =
        "https://apps.apple.com/app/id0000000000"; // ← apna App Store ID daalo: idXXXXXXXXXX

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: Container(
          color: Colors.red,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'UPDATE AVAILABLE',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        content: Html(data: message, shrinkWrap: true),
        actions: <Widget>[
          MaterialButton(
            child: Container(
              color: Colors.red,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'UPDATE NOW',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();

              final Uri url = Uri.parse(Platform.isIOS ? iosUrl : androidUrl);

              // safely launch
              final ok = await canLaunchUrl(url);
              if (!ok) {
                // optional: fallback—same URL with external mode try karo
                await launchUrl(url, mode: LaunchMode.externalApplication);
                return;
              }
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          )
        ],
      ),
    );
  }
  // static Future<void> showForceUpdateDialog(String message, BuildContext context) {
  //   return showDialog(
  //     barrierDismissible: false,
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: Container(
  //         color: Colors.red,
  //         child: const Padding(
  //           padding: EdgeInsets.all(8.0),
  //           child: Center(
  //             child: Text(
  //               'UPDATE AVAILABLE',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //         ),
  //       ),
  //       content: Html(data: message, shrinkWrap: true),
  //       actions: <Widget>[
  //         MaterialButton(
  //           child: Container(
  //             color: Colors.red,
  //             child: const Padding(
  //               padding: EdgeInsets.all(8.0),
  //               child: Text(
  //                 'UPDATE NOW',
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //             ),
  //           ),
  //           onPressed: () {
  //             Navigator.of(ctx).pop();
  //             launchUrl(
  //               Uri.parse(
  //                   "https://play.google.com/store/apps/details?id=com.greylearn.education"),
  //               mode: LaunchMode.externalApplication,
  //             );
  //           },
  //         )
  //       ],
  //     ),
  //   );
  // }


  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: kToastTextColor,
        fontSize: 16.0);
  }

  static void showWarningToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red.shade300,
        textColor: kToastTextColor,
        fontSize: 16.0);
  }
}
