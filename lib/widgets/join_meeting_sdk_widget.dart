// ignore_for_file: unused_element, prefer_interpolation_to_compose_strings, avoid_print, must_be_immutable

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
// import 'package:zoom_allinonesdk/data/util/zoom_error.dart';
// import 'package:zoom_allinonesdk/zoom_allinonesdk.dart';

class JoinMeetingWithSdkWidget extends StatefulWidget {
  String meetingId;
  String meetingPass;
  String meetingClientKey;
  String meetingClientSecret;
  JoinMeetingWithSdkWidget(
      {required this.meetingId,
      required this.meetingPass,
      required this.meetingClientKey,
      required this.meetingClientSecret,
      super.key});

  @override
  State<JoinMeetingWithSdkWidget> createState() =>
      _JoinMeetingWithSdkWidgetState();
}

class _JoinMeetingWithSdkWidgetState extends State<JoinMeetingWithSdkWidget> {
  bool flag = false;

  @override
  void initState() {
    super.initState();
    platformCheck(widget.meetingId, widget.meetingPass);
    print(widget.meetingId);
    print(widget.meetingPass);
    print(widget.meetingClientKey);
    print(widget.meetingClientSecret);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Join Meeting'),
      ),
      body: const SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Please Wait'),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  void platformCheck(String meetingId, String password) {
    if (Platform.isAndroid || Platform.isIOS) {
      //joinMeetingAndroidAndIos(meetingId, password);
    }
  }

  // void joinMeetingAndroidAndIos(String meetingId, String password) async {
  //   ZoomOptions zoomOptions = ZoomOptions(
  //     domain: "zoom.us",
  //     clientId: widget.meetingClientKey,
  //     clientSecert: widget.meetingClientSecret,
  //   );
  //   var meetingOptions = MeetingOptions(
  //       displayName: "", meetingId: meetingId, meetingPassword: password);
  //
  //   var zoom = ZoomAllInOneSdk();
  //   try {
  //     var results = await zoom.initZoom(zoomOptions: zoomOptions);
  //     if (results[0] == 0) {
  //       try {
  //         var loginResult =
  //             await zoom.joinMeting(meetingOptions: meetingOptions);
  //         print("Successfully joined meeting with result: $loginResult");
  //       } catch (error) {
  //         if (error is ZoomError) {
  //           print("[ZoomError during join] : ${error.message}");
  //         } else {
  //           print("[Error Generated during join] : $error");
  //         }
  //       }
  //     } else {
  //       print("Initialization failed with result: ${results[0]}");
  //     }
  //   } catch (error) {
  //     if (error is ZoomError) {
  //       print("[ZoomError during init] : ${error.message}");
  //     } else {
  //       print("[Error Generated during init] : $error");
  //     }
  //   }
  // }

  void _showSnackBar(BuildContext context) {
    final snackBar = SnackBar(
      content: const Text('Please fill all the empty fields'),
      action: SnackBarAction(
        label: 'Close',
        onPressed: () {},
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
