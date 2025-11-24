// ignore_for_file: use_build_context_synchronously, deprecated_member_use, prefer_const_constructors, unnecessary_string_interpolations

import 'dart:convert';

import 'package:academy_app/models/live_class_model.dart';
import 'package:academy_app/providers/shared_pref_helper.dart';
import 'package:academy_app/widgets/join_meeting_sdk_widget.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import 'custom_text.dart';

class LiveClassTabWidget extends StatefulWidget {
  final int courseId;
  const LiveClassTabWidget({super.key, required this.courseId});

  @override
  // ignore: library_private_types_in_public_api
  _LiveClassTabWidgetState createState() => _LiveClassTabWidgetState();
}

class _LiveClassTabWidgetState extends State<LiveClassTabWidget> {
  dynamic token;

  Future<LiveClassModel>? futureLiveClassModel;

  Future<LiveClassModel> fetchLiveClassModel() async {
    token = await SharedPreferenceHelper().getAuthToken();
    var url =
        '$BASE_URL/api/zoom_live_class?course_id=${widget.courseId}&auth_token=$token';
    try {
      final response = await ApiClient().get(url);

      return LiveClassModel.fromJson(json.decode(response.body));
    } catch (error) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    futureLiveClassModel = fetchLiveClassModel();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LiveClassModel>(
      future: futureLiveClassModel,
      builder: (ctx, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * .50,
            child: Center(
              child: CircularProgressIndicator(
                  color: kPrimaryColor.withOpacity(0.7)),
            ),
          );
        } else {
          if (dataSnapshot.error != null) {
            //error
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 15),
                  child: Container(
                    width: double.infinity,
                    color: kNoteColor,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        'No live class is scheduled to this course yet. Please come back later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          wordSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            var dt = DateTime.fromMillisecondsSinceEpoch(int.parse(
                    dataSnapshot.data!.zoomLiveClassDetails!.time.toString()) *
                1000);
            // 12 Hour format:
            var date = DateFormat('hh:mm a : E, dd MMM yyyy').format(dt);
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 25.0, bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        color: Colors.black45,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: CustomText(
                          text: 'Zoom live class schedule',
                          fontSize: 15,
                          colors: kTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomText(
                  text: date,
                  fontSize: 18,
                  colors: kTextColor,
                  // fontWeight: FontWeight.bold,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 15),
                  child: Container(
                    width: double.infinity,
                    color: kNoteColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        dataSnapshot.data!.zoomLiveClassDetails!.noteToStudents
                            .toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          wordSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    // final token = await SharedPreferenceHelper().getAuthToken();
                    // final url = '$BASE_URL/api/zoom_mobile_web_view/${widget.courseId}/$token';
                    // print(_url);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewScreen(url: url)));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinMeetingWithSdkWidget(
                          meetingId: dataSnapshot
                              .data!.zoomLiveClassDetails!.zoomMeetingId
                              .toString(),
                          meetingPass: dataSnapshot
                              .data!.zoomLiveClassDetails!.zoomMeetingPassword
                              .toString(),
                          meetingClientKey: dataSnapshot
                              .data!.zoomLiveClass!.clientId
                              .toString(),
                          meetingClientSecret: dataSnapshot
                              .data!.zoomLiveClass!.clientSecret
                              .toString(),
                        ),
                      ),
                    );
                    print(dataSnapshot.data!.zoomLiveClassDetails!.zoomMeetingId
                        .toString());
                    print(dataSnapshot.data!.zoomLiveClassDetails!.zoomMeetingPassword
                        .toString());
                    print(dataSnapshot
                              .data!.zoomLiveClass!.clientId
                        .toString());
                    print(dataSnapshot
                              .data!.zoomLiveClass!.clientSecret
                        .toString());
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    backgroundColor: kPrimaryColor,
                  ),
                  icon: const Icon(
                    Icons.videocam_rounded,
                  ),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: CustomText(
                      text: 'Join live web class',
                      fontSize: 17,
                      colors: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // final token = await SharedPreferenceHelper().getAuthToken();
                    // final url = '$BASE_URL/api/zoom_mobile_web_view/${widget.courseId}/$token';
                    // print(_url);
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewScreen(url: url)));
                    final url =
                        "https://us05web.zoom.us/j/${dataSnapshot.data!.zoomLiveClassDetails!.zoomMeetingId}?pwd=${dataSnapshot.data!.zoomLiveClassDetails!.zoomMeetingPassword}";
                    _launchURL(url);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    backgroundColor: kPrimaryColor,
                  ),
                  icon: const Icon(
                    Icons.videocam_rounded,
                  ),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: CustomText(
                      text: 'Join live zoom class',
                      fontSize: 17,
                      colors: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }
        }
      },
    );
  }
  void _launchURL(String lessonUrl) async {
    if (!await launchUrl(Uri.parse(lessonUrl))) {
      throw 'Could not launch $lessonUrl';
    }
  }
}















































