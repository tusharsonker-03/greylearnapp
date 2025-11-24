// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:academy_app/constants.dart';
import 'package:academy_app/models/common_functions.dart';
import 'package:academy_app/models/course_db_model.dart';
import 'package:academy_app/models/lesson.dart';
import 'package:academy_app/models/section.dart';
import 'package:academy_app/models/section_db_model.dart';
import 'package:academy_app/models/video_db_model.dart';
import 'package:academy_app/providers/database_helper.dart';
import 'package:academy_app/providers/my_courses.dart';
import 'package:academy_app/screens/file_data_screen.dart';
import 'package:academy_app/screens/vimeo_iframe.dart';
import 'package:academy_app/widgets/app_bar_two.dart';
import 'package:academy_app/widgets/custom_text.dart';
import 'package:academy_app/widgets/forum_tab_widget.dart';
import 'package:academy_app/widgets/from_vimeo_id.dart';
import 'package:academy_app/widgets/live_class_tab_widget.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../Utils/link_navigator.dart';
import '../api/api_client.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
// import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/shared_pref_helper.dart';
import '../widgets/from_network.dart';
import '../widgets/from_youtube.dart';
import 'course_detail_screen.dart';
import 'newcoursedetail_landing_page.dart';
import 'webview_screen.dart';
import 'webview_screen_iframe.dart';

class MyCourseDetailScreen extends StatefulWidget {
  static const routeName = '/my-course-details';
  final int courseId;
  final int len;
  final String enableDripContent;
  const MyCourseDetailScreen(
      {super.key,
      required this.courseId,
      required this.len,
      required this.enableDripContent});

  @override
  // ignore: library_private_types_in_public_api
  _MyCourseDetailScreenState createState() => _MyCourseDetailScreenState();
}

class _MyCourseDetailScreenState extends State<MyCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  var _isInit = true;
  var _isLoading = false;
  int? selected;

  dynamic liveClassStatus;
  dynamic courseForumStatus;
  dynamic data;
  Lesson? _activeLesson;

  String downloadId = "";

  dynamic path;
  dynamic fileName;
  dynamic lessonId;
  dynamic courseId;
  dynamic sectionId;
  dynamic courseTitle;
  dynamic sectionTitle;
  dynamic thumbnail;

  DownloadTask? backgroundDownloadTask;
  TaskStatus? downloadTaskStatus;

  late StreamController<TaskProgressUpdate> progressUpdateStream;
// Initial Selected Value
//   String selectedLanguage = 'English';
//
//   // List of items in our dropdown menu
//   var items = [
//     'English',
//     'Hindi',
//   ];

  List<String> items = [];
  String? selectedLanguage;

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    Provider.of<MyCourses>(context, listen: false)
        .fetchCourseSections(widget.courseId, selectedLanguage!.toLowerCase())
        .then((_) {
      final activeSections =
          Provider.of<MyCourses>(context, listen: false).sectionItems;
      debugPrint("activeSections --${activeSections.length}");
      setState(() {
        _isLoading = false;
        _activeLesson = activeSections.first.mLesson!.first;
      });
    });

    setState(() {
      _isLoading = true;
    });
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _tabController = TabController(length: widget.len, vsync: this);
    _tabController.addListener(_smoothScrollToTop);
    progressUpdateStream = StreamController.broadcast();
    super.initState();
    addonStatus('live-class');
    addonStatus('forum');
    FileDownloader().configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 100)),
    ], androidConfig: [
      (Config.useCacheDir, Config.whenAble),
    ], iOSConfig: [
      (Config.localize, {'Cancel': 'StopIt'}),
    ]).then((result) => debugPrint('Configuration result = $result'));

    // Registering a callback and configure notifications
    FileDownloader()
        .registerCallbacks(
            taskNotificationTapCallback: myNotificationTapCallback)
        .configureNotificationForGroup(FileDownloader.defaultGroup,
            // For the main download button
            // which uses 'enqueue' and a default group
            running: const TaskNotification('Download {filename}',
                'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining'),
            complete: const TaskNotification(
                'Download {filename}', 'Download complete'),
            error: const TaskNotification(
                'Download {filename}', 'Download failed'),
            paused: const TaskNotification(
                'Download {filename}', 'Paused with metadata {metadata}'),
            progressBar: true)
        .configureNotification(
            // for the 'Download & Open' dog picture
            // which uses 'download' which is not the .defaultGroup
            // but the .await group so won't use the above config
            complete: const TaskNotification(
                'Download {filename}', 'Download complete'),
            tapOpensFile: true); // dog can also open directly from tap

    // Listen to updates and process
    FileDownloader().updates.listen((update) async {
      switch (update) {
        case TaskStatusUpdate _:
          if (update.task == backgroundDownloadTask) {
            setState(() {
              downloadTaskStatus = update.status;
            });
          }
          if (downloadTaskStatus == TaskStatus.complete) {
            await DatabaseHelper.instance.addVideo(
              VideoModel(
                  title: fileName,
                  path: path,
                  lessonId: lessonId,
                  courseId: courseId,
                  sectionId: sectionId,
                  courseTitle: courseTitle,
                  sectionTitle: sectionTitle,
                  thumbnail: thumbnail,
                  downloadId: downloadId),
            );
            var val = await DatabaseHelper.instance.courseExists(courseId);
            if (val != true) {
              await DatabaseHelper.instance.addCourse(
                CourseDbModel(
                    courseId: courseId,
                    courseTitle: courseTitle,
                    thumbnail: thumbnail),
              );
            }
            var sec = await DatabaseHelper.instance.sectionExists(sectionId);
            if (sec != true) {
              await DatabaseHelper.instance.addSection(
                SectionDbModel(
                    courseId: courseId,
                    sectionId: sectionId,
                    sectionTitle: sectionTitle),
              );
            }
          }
          break;

        case TaskProgressUpdate _:
          progressUpdateStream.add(update); // pass on to widget for indicator
          break;
      }
    });
  }

  /// Process the user tapping on a notification by printing a message
  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    debugPrint(
        'Tapped notification $notificationType for taskId ${task.directory}');
  }

  Future<void> processButtonPress(
      lesson, myCourseId, coTitle, coThumbnail, secTitle, secId) async {
    print("${BaseDirectory.applicationSupport}/system");
    String fileUrl;

    if (lesson.videoTypeWeb == 'html5' || lesson.videoTypeWeb == 'amazon') {
      fileUrl = lesson.videoUrlWeb.toString();
    } else if (lesson.videoTypeWeb == 'google_drive') {
      final RegExp regExp = RegExp(r'[-\w]{25,}');
      final Match? match = regExp.firstMatch(lesson.videoUrlWeb.toString());

      fileUrl =
          'https://drive.google.com/uc?export=download&id=${match!.group(0)}';
    } else {
      final token = await SharedPreferenceHelper().getAuthToken();
      fileUrl =
          '$BASE_URL/api_files/offline_video_for_mobile_app/${lesson.id}/$token';
    }

    backgroundDownloadTask = DownloadTask(
        url: fileUrl,
        filename: lesson.title.toString(),
        directory: 'system',
        baseDirectory: BaseDirectory.applicationSupport,
        updates: Updates.statusAndProgress,
        allowPause: true,
        metaData: '<video metaData>');
    await FileDownloader().enqueue(backgroundDownloadTask!);
    if (mounted) {
      setState(() {
        path = "/data/user/0/com.greylearn.education/files/system";
        fileName = lesson.title.toString();
        lessonId = lesson.id;
        courseId = myCourseId;
        sectionId = secId;
        courseTitle = coTitle;
        sectionTitle = secTitle;
        thumbnail = coThumbnail;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    progressUpdateStream.close();
    FileDownloader().resetUpdates();
    super.dispose();
  }

  _scrollListener() {
    // if (fixedScroll) {
    //   _scrollController.jumpTo(0);
    // }
  }

  _smoothScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(microseconds: 300),
      curve: Curves.ease,
    );

    // setState(() {
    //   fixedScroll = _tabController.index == 1;
    // });
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        final myLoadedCourse = Provider.of<MyCourses>(context, listen: false)
            .findById(widget.courseId);

        if (myLoadedCourse.language != null &&
            myLoadedCourse.language!.isNotEmpty) {
          items = myLoadedCourse.language!.split(","); // ['english','hindi']
          selectedLanguage = items.first;
        }
        _isLoading = true;
      });

      Provider.of<MyCourses>(context, listen: false)
          .fetchCourseSections(widget.courseId, selectedLanguage!.toLowerCase())
          .then((_) {
        final activeSections =
            Provider.of<MyCourses>(context, listen: false).sectionItems;
        debugPrint("activeSections2 --${activeSections.length}");
        setState(() {
          _isLoading = false;
          if (activeSections.isNotEmpty) {
            _activeLesson = activeSections.first.mLesson!.first;
          }
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _initDownload(
      Lesson lesson, myCourseId, coTitle, coThumbnail, secTitle, secId) async {
    print(lesson.toString());
    if (lesson.videoTypeWeb == 'YouTube') {
      CommonFunctions.showSuccessToast(
          'This video format is not supported for download.');
    } else if (lesson.videoTypeWeb == 'Vimeo' ||
        lesson.videoTypeWeb == 'vimeo') {
      CommonFunctions.showSuccessToast(
          'This video format is not supported for download.');
    } else {
      var les = await DatabaseHelper.instance.lessonExists(lesson.id);
      if (les == true) {
        var check = await DatabaseHelper.instance.lessonDetails(lesson.id);
        File checkPath = File("${check['path']}/${check['title']}");
        print(checkPath.existsSync());
        if (!checkPath.existsSync()) {
          await DatabaseHelper.instance.removeVideo(check['id']);
          processButtonPress(
              lesson, myCourseId, coTitle, coThumbnail, secTitle, secId);
        } else {
          CommonFunctions.showSuccessToast('Video was downloaded already.');
        }
      } else {
        processButtonPress(
            lesson, myCourseId, coTitle, coThumbnail, secTitle, secId);
      }
    }
  }

  Future<void> addonStatus(String identifier) async {
    var url = '$BASE_URL/api/addon_status?unique_identifier=$identifier';
    final response = await ApiClient().get(url);
    if (identifier == 'live-class') {
      setState(() {
        liveClassStatus = json.decode(response.body)['status'];
      });
    } else if (identifier == 'forum') {
      setState(() {
        courseForumStatus = json.decode(response.body)['status'];
      });
    }
  }

  void lessonAction(Lesson lesson) async {
    print(lesson.toString());
    if (lesson.lessonType == 'video') {
      if (lesson.videoTypeWeb == 'html5' || lesson.videoTypeWeb == 'amazon') {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                    courseId: widget.courseId,
                    lessonId: lesson.id!,
                    videoUrl: lesson.videoUrlWeb!,
                    language: selectedLanguage!.toLowerCase(),
                  )),
        );
        // ⬇️ ADD THIS: always refresh after coming back
        await _refresh();
        print('👀 Navigator se wapas aaya result: $res');
        print('📘 Lesson ID: ${lesson.id}');
        if (res is Map && (res['completed'] == true)) {
          // 1) server se fresh sections fetch
          await Future.delayed(const Duration(seconds: 1));

          await Provider.of<MyCourses>(context, listen: false)
              .fetchCourseSections(
                  widget.courseId, selectedLanguage!.toLowerCase());

          if (!mounted) return;
          setState(
              () {}); // ✅ UI ko abhi ke abhi latest server flags se rebuild karao

          // ⬇️ ADD THIS
          if (res['next_is_quiz'] == true) {
            CommonFunctions.showWarningToast(
                'Next item is a Quiz — please open manually.');
            return;
          }
          // ✅ frame paint hone do, phir next khol do (agar server ne unlock kiya)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeAutoOpenNextServerStrict(lesson);
          });
        }
      } else if (lesson.videoTypeWeb == 'system') {
        final token = await SharedPreferenceHelper().getAuthToken();
        var url =
            '$BASE_URL/api_files/file_content?course_id=${widget.courseId}&lesson_id=${lesson.id}&auth_token=$token';
        // print(url);
        final res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                    courseId: widget.courseId,
                    lessonId: lesson.id!,
                    videoUrl: url,
                    language: selectedLanguage!.toLowerCase(),
                  )),
        );
        // ⬇️ ADD THIS: always refresh after coming back
        await _refresh();
        print('👀 Navigator se wapas aaya result: $res');
        print('📘 Lesson ID: ${lesson.id}');
        if (res is Map && (res['completed'] == true)) {
          // 1) server se fresh sections fetch
          await Future.delayed(const Duration(seconds: 1));

          await Provider.of<MyCourses>(context, listen: false)
              .fetchCourseSections(
                  widget.courseId, selectedLanguage!.toLowerCase());

          if (!mounted) return;
          setState(
              () {}); // ✅ UI ko abhi ke abhi latest server flags se rebuild karao
          // ⬇️ ADD THIS
          if (res['next_is_quiz'] == true) {
            CommonFunctions.showWarningToast(
                'Next item is a Quiz — please open manually.');
            return;
          }
          // ✅ frame paint hone do, phir next khol do (agar server ne unlock kiya)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeAutoOpenNextServerStrict(lesson);
          });
        }
      } else if (lesson.videoTypeWeb == 'google_drive') {
        final RegExp regExp = RegExp(r'[-\w]{25,}');
        final Match? match = regExp.firstMatch(lesson.videoUrlWeb.toString());

        String url =
            'https://drive.google.com/uc?export=download&id=${match!.group(0)}';

        final res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayVideoFromNetwork(
                    courseId: widget.courseId,
                    lessonId: lesson.id!,
                    videoUrl: url,
                    language: selectedLanguage!.toLowerCase(),
                  )),
        );
        // ⬇️ ADD THIS: always refresh after coming back
        await _refresh();
        print('👀 Navigator se wapas aaya result: $res');
        print('📘 Lesson ID: ${lesson.id}');
        if (res is Map && (res['completed'] == true)) {
          // 1) server se fresh sections fetch
          await Future.delayed(const Duration(seconds: 1));

          await Provider.of<MyCourses>(context, listen: false)
              .fetchCourseSections(
                  widget.courseId, selectedLanguage!.toLowerCase());

          if (!mounted) return;
          setState(
              () {}); // ✅ UI ko abhi ke abhi latest server flags se rebuild karao
          // ⬇️ ADD THIS
          if (res['next_is_quiz'] == true) {
            CommonFunctions.showWarningToast(
                'Next item is a Quiz — please open manually.');
            return;
          }
          // ✅ frame paint hone do, phir next khol do (agar server ne unlock kiya)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeAutoOpenNextServerStrict(lesson);
          });
        }
      } else if (lesson.videoTypeWeb!.toLowerCase() == 'vimeo') {
        print(lesson.videoUrlWeb);
        String vimeoVideoId = lesson.videoUrlWeb!.split('/').last;
        print("vimeoVideoId");
        print(vimeoVideoId);
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => PlayVideoFromVimeoId(
        //           courseId: widget.courseId,
        //           lessonId: lesson.id!,
        //           vimeoVideoId: vimeoVideoId),
        //     ));
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: kBackgroundColor,
              titlePadding: EdgeInsets.zero,
              title: const Padding(
                padding: EdgeInsets.only(left: 15.0, right: 15, top: 20),
                child: Center(
                  child: Text('Choose Video player',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
              ),
              actions: <Widget>[
                const SizedBox(
                  height: 20,
                ),
                MaterialButton(
                  elevation: 0,
                  color: kPrimaryColor,
                  onPressed: () async {
                    debugPrint('PlayVideoFromVimeoId --> ${vimeoVideoId}');
                    Navigator.pop(context); // close dialog
                    final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayVideoFromVimeoId(
                              courseId: widget.courseId,
                              lessonId: lesson.id!,
                              vimeoVideoId: vimeoVideoId),
                        ));
                    if (res is Map && (res['completed'] == true)) {
                      // 1) server se fresh sections fetch
                      await Future.delayed(const Duration(seconds: 1));

                      await Provider.of<MyCourses>(context, listen: false)
                          .fetchCourseSections(
                              widget.courseId, selectedLanguage!.toLowerCase());

                      if (!mounted) return;
                      setState(
                          () {}); // ✅ UI ko abhi ke abhi latest server flags se rebuild karao
                      // ⬇️ ADD THIS
                      if (res['next_is_quiz'] == true) {
                        CommonFunctions.showWarningToast(
                            'Next item is a Quiz — please open manually.');
                        return;
                      }
                      // ✅ frame paint hone do, phir next khol do (agar server ne unlock kiya)
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _maybeAutoOpenNextServerStrict(lesson);
                      });
                    }
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusDirectional.circular(6),
                    // side: const BorderSide(color: kPrimaryColor),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vimeo',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                MaterialButton(
                  elevation: 0,
                  color: kPrimaryColor,
                  onPressed: () async {
                    String vimUrl =
                        'https://player.vimeo.com/video/$vimeoVideoId';
                    debugPrint(vimUrl);
                    Navigator.pop(context); // 🔒 dialog close
                    final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VimeoIframe(url: vimUrl)));

                    if (res is Map && (res['completed'] == true)) {
                      // 1) server se fresh sections fetch
                      await Future.delayed(const Duration(seconds: 1));

                      await Provider.of<MyCourses>(context, listen: false)
                          .fetchCourseSections(
                              widget.courseId, selectedLanguage!.toLowerCase());

                      if (!mounted) return;
                      setState(
                          () {}); // ✅ UI ko abhi ke abhi latest server flags se rebuild karao
                      // ⬇️ ADD THIS
                      if (res['next_is_quiz'] == true) {
                        CommonFunctions.showWarningToast(
                            'Next item is a Quiz — please open manually.');
                        return;
                      }
                      // ✅ frame paint hone do, phir next khol do (agar server ne unlock kiya)
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _maybeAutoOpenNextServerStrict(lesson);
                      });
                    }
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusDirectional.circular(6),
                    // side: const BorderSide(color: kPrimaryColor),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vimeo Iframe',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        );
      } else {
        final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayVideoFromYoutube(
                  courseId: widget.courseId,
                  lessonId: lesson.id!,
                  videoUrl: lesson.videoUrlWeb!),
            ));
        if (res is Map && (res['completed'] == true)) {
          // 1) server se fresh sections fetch
          await Future.delayed(const Duration(seconds: 1));

          await Provider.of<MyCourses>(context, listen: false)
              .fetchCourseSections(
                  widget.courseId, selectedLanguage!.toLowerCase());

          if (!mounted) return;
          setState(
              () {}); // ✅ UI ko abhi ke abhi latest server flags se rebuild karao
          // ⬇️ ADD THIS
          if (res['next_is_quiz'] == true) {
            CommonFunctions.showWarningToast(
                'Next item is a Quiz — please open manually.');
            return;
          }
          // ✅ frame paint hone do, phir next khol do (agar server ne unlock kiya)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeAutoOpenNextServerStrict(lesson);
          });
        }
      }
    } else if (lesson.lessonType == 'quiz') {
      Lesson? prev = _findPreviousLesson(lesson);
      if (prev != null && prev.isCompleted != '1') {
        CommonFunctions.showWarningToast(
            'Please complete the previous lesson before attempting the quiz.');
        return;
      }

      // print(lesson.id);
      final token = await SharedPreferenceHelper().getAuthToken();
      // final url = '$BASE_URL/api/quiz_mobile_web_view/${lesson.id}/$token';
      final url = '$BASE_URL/api/quiz_mobile_web_view'
          '?lesson_id=${lesson.id}&auth_token=$token';
      print("🔗 Quiz URL: $url");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: url),
        ),
      ).then((result) {
        print("✅ Quiz closed, refreshing course data...");

        _refresh();
      });
    } else {
      if (lesson.attachmentType == 'iframe') {
        final url = lesson.attachment;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WebViewScreenIframe(url: url)));
      } else if (lesson.attachmentType == 'description') {
        // data = lesson.attachment;
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) =>
        //             FileDataScreen(textData: data, note: lesson.summary!)));
        final token = await SharedPreferenceHelper().getAuthToken();
        final url = '$BASE_URL/api/lesson_mobile_web_view/${lesson.id}/$token';
        // print(_url);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => WebViewScreen(url: url)));
      } else if (lesson.attachmentType == 'txt') {
        final url = '$BASE_URL/uploads/lesson_files/${lesson.attachment}';
        data = await http.read(Uri.parse(url));
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    FileDataScreen(textData: data, note: lesson.summary!)));
      } else {
        final token = await SharedPreferenceHelper().getAuthToken();
        final url =
            '$BASE_URL/api_files/file_content?course_id=${widget.courseId}&lesson_id=${lesson.id}&auth_token=$token';
        // print(url);
        _launchURL(url);
      }
    }
  }

  void _launchURL(String lessonUrl) async {
    if (!await launchUrl(Uri.parse(lessonUrl))) {
      throw 'Could not launch $lessonUrl';
    }
  }

  Widget getLessonSubtitle(Lesson lesson) {
    if (lesson.lessonType == 'video') {
      return CustomText(
        text: lesson.duration,
        fontSize: 12,
      );
    } else if (lesson.lessonType == 'quiz') {
      return RichText(
        text: const TextSpan(
          children: [
            WidgetSpan(
              child: Icon(
                Icons.event_note,
                size: 12,
                color: kSecondaryColor,
              ),
            ),
            TextSpan(
                text: 'Quiz',
                style: TextStyle(fontSize: 12, color: kSecondaryColor)),
          ],
        ),
      );
    } else {
      return RichText(
        text: const TextSpan(
          children: [
            WidgetSpan(
              child: Icon(
                Icons.attach_file,
                size: 12,
                color: kSecondaryColor,
              ),
            ),
            TextSpan(
                text: 'Attachment',
                style: TextStyle(fontSize: 12, color: kSecondaryColor)),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final myCourseId = ModalRoute.of(context)!.settings.arguments as int;
    debugPrint(widget.courseId.toString());
    final myLoadedCourse = Provider.of<MyCourses>(context, listen: false)
        .findById(widget.courseId);
    final sections =
        Provider.of<MyCourses>(context, listen: false).sectionItems;
    debugPrint("sectionItems --${sections.length}");
    myCourseBody() {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Card(
                elevation: 0.3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  text: myLoadedCourse.title,
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.black),
                                ),
                              ),
                            ),
                            if (items.length > 1)
                              Center(
                                child: DropdownButton(
                                  // Initial Value
                                  value: selectedLanguage,
                                  // Down Arrow Icon
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  // Array list of items
                                  items: items.map((lang) {
                                    return DropdownMenuItem(
                                        value: lang,
                                        child: Text(
                                          lang[0].toUpperCase() +
                                              lang.substring(1), // capitalize
                                        ));
                                  }).toList(),
                                  // After selecting the desired option,it will
                                  // change button value to selected value
                                  onChanged: (newValue) {
                                    setState(() {
                                      selectedLanguage = newValue!;
                                    });
                                    _refresh();
                                  },
                                ),
                              )
                            else
                              const SizedBox
                                  .shrink(), // 👈 ek hi language hai to dropdown hide

                            PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'details') {
                                  Navigator.of(context).pushNamed(
                                      CourseLandingPage.routeName,
                                      arguments: myLoadedCourse.id);
                                }
                                // else if(value == 'change'){
                                //   showDialog(
                                //     context: context,
                                //     builder: (BuildContext context) {
                                //       return AlertDialog(
                                //         backgroundColor: kBackgroundColor,
                                //         titlePadding: EdgeInsets.zero,
                                //         title: const Padding(
                                //           padding: EdgeInsets.only(left: 15.0, right: 15, top: 20),
                                //           child: Center(
                                //             child: Text('Choose Language',
                                //                 style:
                                //                 TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                //           ),
                                //         ),
                                //
                                //         actions: <Widget>[
                                //           const SizedBox(
                                //             height: 20,
                                //           ),
                                //           MaterialButton(
                                //             elevation: 0,
                                //             color: kPrimaryColor,
                                //             onPressed: () {
                                //               debugPrint('PlayVideoFromVimeoId --> }');
                                //
                                //             },
                                //             padding:
                                //             const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                //             shape: RoundedRectangleBorder(
                                //               borderRadius: BorderRadiusDirectional.circular(6),
                                //               // side: const BorderSide(color: kPrimaryColor),
                                //             ),
                                //             child: const Row(
                                //               mainAxisAlignment: MainAxisAlignment.center,
                                //               children: [
                                //                 Text(
                                //                   'English',
                                //                   style: TextStyle(
                                //                     fontSize: 16,
                                //                     color: Colors.white,
                                //                     fontWeight: FontWeight.w500,
                                //                   ),
                                //                 ),
                                //               ],
                                //             ),
                                //           ),
                                //           const SizedBox(
                                //             height: 10,
                                //           ),
                                //           MaterialButton(
                                //             elevation: 0,
                                //             color: kPrimaryColor,
                                //             onPressed: () {
                                //
                                //                },
                                //             padding:
                                //             const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                //             shape: RoundedRectangleBorder(
                                //               borderRadius: BorderRadiusDirectional.circular(6),
                                //               // side: const BorderSide(color: kPrimaryColor),
                                //             ),
                                //             child: const Row(
                                //               mainAxisAlignment: MainAxisAlignment.center,
                                //               children: [
                                //                 Text(
                                //                   'Hindi',
                                //                   style: TextStyle(
                                //                     fontSize: 16,
                                //                     color: Colors.white,
                                //                     fontWeight: FontWeight.w500,
                                //                   ),
                                //                 ),
                                //               ],
                                //             ),
                                //           ),
                                //           const SizedBox(height: 10),
                                //         ],
                                //       );
                                //     },
                                //   );
                                // }
                                else {
                                  Share.share(
                                      myLoadedCourse.shareableLink.toString());
                                }
                              },
                              icon: const Icon(
                                Icons.more_vert,
                              ),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'details',
                                  child: Text('Course Details'),
                                ),
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Text('Share this Course'),
                                ),
                                // const PopupMenuItem(
                                //   value: 'change',
                                //   child: Text('Change Language'),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: LinearPercentIndicator(
                          lineHeight: 8.0,
                          backgroundColor: kBackgroundColor,
                          percent: myLoadedCourse.courseCompletion! / 100,
                          // percent: 1.0,
                          progressColor: kPrimaryColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: CustomText(
                                  text:
                                      '${myLoadedCourse.courseCompletion}% Complete',
                                  fontSize: 12,
                                  colors: Colors.black54,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: CustomText(
                                text:
                                    '${myLoadedCourse.totalNumberOfCompletedLessons}/${myLoadedCourse.totalNumberOfLessons}',
                                fontSize: 14,
                                colors: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      (myLoadedCourse.courseCompletion! >= 100)
                          ? Column(
                              children: [
                                // ✅ अगर expire है तो "Download Certificate" से पहले expired दिखाना है
                                if (sections.length == 0) ...[
                                  const Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 5.0),
                                      child: CustomText(
                                        text: 'This course is expired',
                                        colors: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // ✅ Certificate button
                                Card(
                                  color: kGreenColorColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0.1,
                                  child: GestureDetector(
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black54,
                                            radius: 10,
                                            child: Padding(
                                              padding: EdgeInsets.all(2),
                                              child: FittedBox(
                                                child: Icon(
                                                  Icons.file_download,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CustomText(
                                            text: "Download Certificate",
                                            colors: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      final token =
                                          await SharedPreferenceHelper()
                                              .getAuthToken();
                                      final link = widget.courseId.toString();
                                      final url =
                                          '$BASE_URL/api/download_certificate_mobile_web_view/$link/$token';
                                      await launchUrl(Uri.parse(url),
                                          mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                ),
                              ],
                            )
                          : (sections.length == 0)
                              ? Column(
                                  children: [
                                    const Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 5.0),
                                        child: CustomText(
                                          text: 'This course is expired',
                                          colors: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Card(
                                      color: kPrimaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0.1,
                                      child: GestureDetector(
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              child: CircleAvatar(
                                                backgroundColor: Colors.black54,
                                                radius: 10,
                                                child: Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: FittedBox(
                                                    child: Icon(
                                                      Icons.replay,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CustomText(
                                                text: "Purchase Again",
                                                colors: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            CourseLandingPage.routeName,
                                            arguments: myLoadedCourse.id,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),

                      // myLoadedCourse.courseCompletion! >= 100 ? Card(
                      //   color: kGreenColorColor,
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(10),
                      //   ),
                      //   elevation: 0.1,
                      //   child: GestureDetector(
                      //     child: const Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       crossAxisAlignment: CrossAxisAlignment.center,
                      //       children: [
                      //         SizedBox(
                      //           height:20,
                      //           child: CircleAvatar(
                      //             backgroundColor: Colors.black54,
                      //             radius: 10,
                      //             child: Padding(
                      //               padding: const EdgeInsets.all(2),
                      //               child: FittedBox(
                      //                 child: Icon(
                      //                   Icons.file_download,
                      //                   color: Colors.white,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //         Padding(
                      //           padding: EdgeInsets.all(8.0),
                      //           child: CustomText(
                      //             text: "Download Certificate",
                      //             colors: Colors.white,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //     onTap: () async {
                      //       final token = await SharedPreferenceHelper().getAuthToken();
                      //       final link = widget.courseId.toString();
                      //       final url = '$BASE_URL/api/download_certificate_mobile_web_view/$link/$token';
                      //       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      //       // LinkNavigator.instance.navigate(context,widget.courseId.toString(), 'certificate', 0,false, token ?? '','');
                      //     },
                      //   ),
                      // ) : sections.length == 0 ? const Align(
                      //   alignment: Alignment.center,
                      //   child: Padding(
                      //     padding: EdgeInsets.symmetric(
                      //       vertical: 5.0,
                      //     ),
                      //     child: CustomText(
                      //       text: 'This course is expired',
                      //       colors: Colors.red,
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.w400,
                      //     ),
                      //   ),
                      // )  : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                key: Key('builder ${selected.toString()}'), //attention
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                itemBuilder: (ctx, index) {
                  final section = sections[index];
                  return Card(
                    elevation: 0.3,
                    color: kBackgroundColor,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        unselectedWidgetColor: Colors.transparent,
                        colorScheme: const ColorScheme.light(
                          primary: Colors.black,
                        ),
                      ),
                      child: ExpansionTile(
                        key: Key(index.toString()),
                        initiallyExpanded: index == selected,
                        onExpansionChanged: (newState) {
                          if (newState) {
                            if (widget.enableDripContent == '1') {
                            if (!_isSectionUnlocked(index, sections)) {
                              CommonFunctions.showWarningToast(
                                'Please complete the previous section first',
                              );
                              return;
                            }    }
                            setState(() => selected = index);
                          } else {
                            setState(() => selected = -1);
                          }
                        },
                        trailing: const Icon(Icons.expand_more),

                        // trailing: !_isSectionUnlocked(index, sections)
                        //     ? const Icon(Icons.lock_outline, )
                        //     : const Icon(Icons.expand_more),
                        // collapsedShape: RoundedRectangleBorder(
                        //   borderRadius: BorderRadius.circular(0),
                        //   side: BorderSide.none,
                        // ),
                        // shape: RoundedRectangleBorder(
                        //   borderRadius: BorderRadius.circular(0),
                        //   side: BorderSide.none,
                        // ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5.0,
                                ),
                                child: CustomText(
                                  text: HtmlUnescape()
                                      .convert(section.title.toString()),
                                  colors: kDarkGreyColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: kTimeBackColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: CustomText(
                                          text: section.totalDuration,
                                          fontSize: 10,
                                          colors: kTimeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10.0,
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: kLessonBackColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: kLessonBackColor,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: CustomText(
                                            text:
                                                '${section.mLesson!.length} Lessons',
                                            fontSize: 10,
                                            colors: kDarkGreyColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Expanded(flex: 2, child: Text("")),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          widget.enableDripContent == '1'
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: section.mLesson!.length,
                                  itemBuilder: (ctx, indexLess) {
                                    // return LessonListItem(
                                    //   lesson: section.mLesson[index],
                                    // );
                                    final lesson = section.mLesson![indexLess];
                                    final bool sectionLocked =
                                        widget.enableDripContent == '1' &&
                                            index > 0 &&
                                            !_isSectionCompleted(
                                                sections[index - 1]);
                                    final bool locked = sectionLocked ||
                                        _isLessonLocked(
                                            sections, index, indexLess);

                                    return InkWell(
                                      onTap: () async {
                                        // Check previous lesson
                                        if (locked) {
                                          CommonFunctions.showWarningToast(
                                              'Please complete the previous lesson first.');
                                          return;
                                        }

                                        Lesson? prevLesson;
                                        if (indexLess > 0) {
                                          prevLesson =
                                              section.mLesson![indexLess - 1];
                                        } else if (index > 0 &&
                                            sections[index - 1]
                                                .mLesson!
                                                .isNotEmpty) {
                                          prevLesson =
                                              sections[index - 1].mLesson!.last;
                                        }

                                        if (prevLesson != null &&
                                            prevLesson.isCompleted != '1') {
                                          CommonFunctions.showWarningToast(
                                            'Please complete the previous lesson first.',
                                          );
                                          return;
                                        }

                                        // ✅ Allow only unlocked lessons to open
                                        final lessons =
                                            await Provider.of<MyCourses>(
                                                    context,
                                                    listen: false)
                                                .fetchLessonDetails(
                                                    lesson.id!,
                                                    selectedLanguage!
                                                        .toLowerCase());

                                        if (lessons.isNotEmpty) {
                                          setState(() {
                                            _activeLesson = lessons.first;
                                          });
                                          lessonAction(_activeLesson!);
                                        } else {
                                          CommonFunctions.showWarningToast(
                                              "Lesson details not found");
                                        }
                                      },
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                            color: Colors.white60,
                                            width: double.infinity,
                                            child: Row(
                                              children: <Widget>[
                                                // 🔐 Lock or Checkbox (same logic sab section ke liye)
                                                Expanded(
                                                  flex: 1,
                                                  child: locked
                                                      // 🔒 locked (section ya lesson): hamesha lock icon
                                                      ? const Icon(
                                                          Icons.lock_outline,
                                                        )
                                                      // 🔓 unlocked -> checkbox (videos ke liye manual tick block)
                                                      : (lesson.lessonType ==
                                                              'video'
                                                          ? Checkbox(
                                                              activeColor:
                                                                  kPrimaryColor,
                                                              value: _isCompleted(
                                                                  lesson
                                                                      .isCompleted),
                                                              onChanged:
                                                                  (bool? _) {
                                                                CommonFunctions
                                                                    .showWarningToast(
                                                                  'Watch lessons to update course progress.',
                                                                );
                                                              },
                                                            )
                                                          : Checkbox(
                                                              activeColor:
                                                                  kPrimaryColor,
                                                              value: _isCompleted(
                                                                  lesson
                                                                      .isCompleted),
                                                              onChanged: (bool?
                                                                  value) {
                                                                setState(() {
                                                                  lesson.isCompleted =
                                                                      value!
                                                                          ? '1'
                                                                          : '0';
                                                                  myLoadedCourse
                                                                      .totalNumberOfCompletedLessons = myLoadedCourse
                                                                          .totalNumberOfCompletedLessons! +
                                                                      (value
                                                                          ? 1
                                                                          : -1);
                                                                  final completePerc =
                                                                      (myLoadedCourse.totalNumberOfCompletedLessons! /
                                                                              myLoadedCourse.totalNumberOfLessons!) *
                                                                          100;
                                                                  myLoadedCourse
                                                                          .courseCompletion =
                                                                      completePerc
                                                                          .round();
                                                                });
                                                                Provider.of<MyCourses>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .toggleLessonCompleted(
                                                                        lesson
                                                                            .id!
                                                                            .toInt(),
                                                                        value!
                                                                            ? 1
                                                                            : 0)
                                                                    .then((_) =>
                                                                        CommonFunctions.showSuccessToast(
                                                                            'Course Progress Updated'));
                                                              },
                                                            )),
                                                ),

                                                // 🔤 Lesson title & subtitle
                                                Expanded(
                                                  flex: 8,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      CustomText(
                                                        text: lesson.title,
                                                        fontSize: 14,
                                                        colors: kTextColor,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                      getLessonSubtitle(lesson),
                                                    ],
                                                  ),
                                                ),

                                                // 🕓 Download icon space (agar chahiye to)
                                                if (lesson.lessonType ==
                                                    'video')
                                                  const Expanded(
                                                      flex: 2,
                                                      child: SizedBox.shrink()),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    );
                                    // return Text(section.mLesson[index].title);
                                  },
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (ctx, index) {
                                    // return LessonListItem(
                                    //   lesson: section.mLesson[index],
                                    // );
                                    final lesson = section.mLesson![index];
                                    return InkWell(
                                      onTap: () async {
                                        final lessons =
                                            await Provider.of<MyCourses>(
                                                    context,
                                                    listen: false)
                                                .fetchLessonDetails(
                                                    lesson.id!,
                                                    selectedLanguage!
                                                        .toLowerCase());

                                        if (lessons.isNotEmpty) {
                                          setState(() {
                                            _activeLesson = lessons.first;
                                          });
                                          lessonAction(_activeLesson!);
                                        } else {
                                          CommonFunctions.showWarningToast(
                                              "Lesson details not found");
                                        }
                                      },
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                            color: Colors.white60,
                                            width: double.infinity,
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 1,
                                                  child: Checkbox(
                                                      activeColor:
                                                          kPrimaryColor,
                                                      value:
                                                          lesson.isCompleted ==
                                                                  '1'
                                                              ? true
                                                              : false,
                                                      onChanged: (bool? value) {
                                                        // print(value);

                                                        setState(() {
                                                          lesson.isCompleted =
                                                              value!
                                                                  ? '1'
                                                                  : '0';
                                                          if (value) {
                                                            myLoadedCourse
                                                                    .totalNumberOfCompletedLessons =
                                                                myLoadedCourse
                                                                        .totalNumberOfCompletedLessons! +
                                                                    1;
                                                          } else {
                                                            myLoadedCourse
                                                                    .totalNumberOfCompletedLessons =
                                                                myLoadedCourse
                                                                        .totalNumberOfCompletedLessons! -
                                                                    1;
                                                          }
                                                          var completePerc = (myLoadedCourse
                                                                      .totalNumberOfCompletedLessons! /
                                                                  myLoadedCourse
                                                                      .totalNumberOfLessons!) *
                                                              100;
                                                          myLoadedCourse
                                                                  .courseCompletion =
                                                              completePerc
                                                                  .round();
                                                        });
                                                        Provider.of<MyCourses>(
                                                                context,
                                                                listen: false)
                                                            .toggleLessonCompleted(
                                                                lesson.id!
                                                                    .toInt(),
                                                                value! ? 1 : 0)
                                                            .then((_) => CommonFunctions
                                                                .showSuccessToast(
                                                                    'Course Progress Updated'));
                                                      }),
                                                ),
                                                Expanded(
                                                  flex: 8,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      CustomText(
                                                        text: lesson.title,
                                                        fontSize: 14,
                                                        colors: kTextColor,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                      getLessonSubtitle(lesson),
                                                    ],
                                                  ),
                                                ),
                                                if (lesson.lessonType ==
                                                    'video')
                                                  Expanded(
                                                    flex: 2,
                                                    child: SizedBox.shrink(),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                    );
                                    // return Text(section.mLesson[index].title);
                                  },
                                  itemCount: section.mLesson!.length,
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    myCourseBodyTwo() {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ListView.builder(
            key: Key('builder ${selected.toString()}'), //attention
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            itemBuilder: (ctx, index) {
              final section = sections[index];
              return Card(
                elevation: 0.3,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    unselectedWidgetColor: Colors.transparent,
                    colorScheme: const ColorScheme.light(
                      primary: Colors.black,
                    ),
                  ),
                  child: ExpansionTile(
                    key: Key(index.toString()),
                    initiallyExpanded: index == selected,
                    onExpansionChanged: (newState) {

                      if (newState) {
                        if (widget.enableDripContent == '1') {
                        if (!_isSectionUnlocked(index, sections)) {
                          CommonFunctions.showWarningToast(
                            'Please complete the previous section first',
                          );
                          return;
                        }
                        setState(() => selected = index);
                      } else {
                        setState(() => selected = -1);
                      }  }
                    },
                    trailing: const Icon(Icons.expand_more),

                    // trailing: !_isSectionUnlocked(index, sections)
                    //     ? const Icon(Icons.lock_outline,)
                    //     : const Icon(Icons.expand_more),

                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5.0,
                            ),
                            child: CustomText(
                              text: HtmlUnescape()
                                  .convert(section.title.toString()),
                              colors: kDarkGreyColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kTimeBackColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: CustomText(
                                      text: section.totalDuration,
                                      fontSize: 10,
                                      colors: kTimeColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10.0,
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kLessonBackColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: kLessonBackColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: CustomText(
                                        text:
                                            '${section.mLesson!.length} Lessons',
                                        fontSize: 10,
                                        colors: kDarkGreyColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(flex: 2, child: Text("")),
                            ],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      widget.enableDripContent == '1'
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: section.mLesson!.length,
                              itemBuilder: (ctx, indexLess) {
                                final lesson = section.mLesson![indexLess];

// indexes tumhare code ke hisaab se hon (section index = index, lesson index = indexLess)
                                final bool sectionLocked = widget
                                            .enableDripContent ==
                                        '1' &&
                                    index > 0 &&
                                    !_isSectionCompleted(sections[index - 1]);
                                final bool locked = sectionLocked ||
                                    _isLessonLocked(sections, index, indexLess);

                                return InkWell(
                                  onTap: () async {
                                    if (locked) {
                                      CommonFunctions.showWarningToast(
                                          'Please complete the previous lesson first.');
                                      return;
                                    }

                                    final lessons = await Provider.of<
                                            MyCourses>(context, listen: false)
                                        .fetchLessonDetails(lesson.id!,
                                            selectedLanguage!.toLowerCase());

                                    if (lessons.isNotEmpty) {
                                      setState(() {
                                        _activeLesson = lessons.first;
                                      });
                                      lessonAction(_activeLesson!);
                                    } else {
                                      CommonFunctions.showWarningToast(
                                          "Lesson details not found");
                                    }
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 10),
                                        color: Colors.white60,
                                        width: double.infinity,
                                        child: Row(
                                          children: <Widget>[
                                            // 🔐 Lock or Checkbox (same logic sab section ke liye)
                                            Expanded(
                                              flex: 1,
                                              child: locked
                                                  // 🔒 locked (section ya lesson): hamesha lock icon
                                                  ? const Icon(
                                                      Icons.lock_outline,
                                                    )
                                                  // 🔓 unlocked -> checkbox (videos ke liye manual tick block)
                                                  : (lesson.lessonType ==
                                                          'video'
                                                      ? Checkbox(
                                                          activeColor:
                                                              kPrimaryColor,
                                                          value: _isCompleted(
                                                              lesson
                                                                  .isCompleted),
                                                          onChanged: (bool? _) {
                                                            CommonFunctions
                                                                .showWarningToast(
                                                              'Watch lessons to update course progress.',
                                                            );
                                                          },
                                                        )
                                                      : Checkbox(
                                                          activeColor:
                                                              kPrimaryColor,
                                                          value: _isCompleted(
                                                              lesson
                                                                  .isCompleted),
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              lesson.isCompleted =
                                                                  value!
                                                                      ? '1'
                                                                      : '0';
                                                              myLoadedCourse
                                                                      .totalNumberOfCompletedLessons =
                                                                  myLoadedCourse
                                                                          .totalNumberOfCompletedLessons! +
                                                                      (value
                                                                          ? 1
                                                                          : -1);
                                                              final completePerc =
                                                                  (myLoadedCourse
                                                                              .totalNumberOfCompletedLessons! /
                                                                          myLoadedCourse
                                                                              .totalNumberOfLessons!) *
                                                                      100;
                                                              myLoadedCourse
                                                                      .courseCompletion =
                                                                  completePerc
                                                                      .round();
                                                            });
                                                            Provider.of<MyCourses>(
                                                                    context,
                                                                    listen:
                                                                        false)
                                                                .toggleLessonCompleted(
                                                                    lesson.id!
                                                                        .toInt(),
                                                                    value!
                                                                        ? 1
                                                                        : 0)
                                                                .then((_) =>
                                                                    CommonFunctions
                                                                        .showSuccessToast(
                                                                            'Course Progress Updated'));
                                                          },
                                                        )),
                                            ),

                                            // 🔤 Lesson title & subtitle
                                            Expanded(
                                              flex: 8,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  CustomText(
                                                    text: lesson.title,
                                                    fontSize: 14,
                                                    colors: kTextColor,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  getLessonSubtitle(lesson),
                                                ],
                                              ),
                                            ),

                                            // 🕓 Download icon space (agar chahiye to)
                                            if (lesson.lessonType == 'video')
                                              const Expanded(
                                                  flex: 2,
                                                  child: SizedBox.shrink()),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: section.mLesson!.length,
                              itemBuilder: (ctx, indexLess) {
                                final lesson = section.mLesson![indexLess];
                                return InkWell(
                                  onTap: () async {
                                    final lessons = await Provider.of<
                                            MyCourses>(context, listen: false)
                                        .fetchLessonDetails(lesson.id!,
                                            selectedLanguage!.toLowerCase());

                                    if (lessons.isNotEmpty) {
                                      setState(() {
                                        _activeLesson = lessons.first;
                                      });
                                      lessonAction(_activeLesson!);
                                    } else {
                                      CommonFunctions.showWarningToast(
                                          "Lesson details not found");
                                    }
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 10),
                                        color: Colors.white60,
                                        width: double.infinity,
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              flex: 1,
                                              child: Checkbox(
                                                activeColor: kPrimaryColor,
                                                value: _isCompleted(
                                                    lesson.isCompleted),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    lesson.isCompleted =
                                                        value! ? '1' : '0';
                                                    myLoadedCourse
                                                            .totalNumberOfCompletedLessons =
                                                        myLoadedCourse
                                                                .totalNumberOfCompletedLessons! +
                                                            (value ? 1 : -1);
                                                    var completePerc = (myLoadedCourse
                                                                .totalNumberOfCompletedLessons! /
                                                            myLoadedCourse
                                                                .totalNumberOfLessons!) *
                                                        100;
                                                    myLoadedCourse
                                                            .courseCompletion =
                                                        completePerc.round();
                                                  });
                                                  Provider.of<MyCourses>(
                                                          context,
                                                          listen: false)
                                                      .toggleLessonCompleted(
                                                          lesson.id!.toInt(),
                                                          value! ? 1 : 0)
                                                      .then((_) => CommonFunctions
                                                          .showSuccessToast(
                                                              'Course Progress Updated'));
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              flex: 8,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  CustomText(
                                                    text: lesson.title,
                                                    fontSize: 14,
                                                    colors: kTextColor,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  getLessonSubtitle(lesson),
                                                ],
                                              ),
                                            ),
                                            if (lesson.lessonType == 'video')
                                              const Expanded(
                                                  flex: 2,
                                                  child: SizedBox.shrink()),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    addonBody() {
      return NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, value) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  elevation: 0.3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: RichText(
                                  textAlign: TextAlign.left,
                                  text: TextSpan(
                                    text: myLoadedCourse.title,
                                    style: const TextStyle(
                                        fontSize: 20, color: Colors.black),
                                  ),
                                ),
                              ),
                              PopupMenuButton(
                                onSelected: (value) {
                                  if (value == 'details') {
                                    Navigator.of(context).pushNamed(
                                        CourseLandingPage.routeName,
                                        arguments: myLoadedCourse.id);
                                  } else {
                                    Share.share(myLoadedCourse.shareableLink
                                        .toString());
                                  }
                                },
                                icon: const Icon(
                                  Icons.more_vert,
                                ),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Text('Course Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Text('Share this Course'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: LinearPercentIndicator(
                            lineHeight: 8.0,
                            backgroundColor: kBackgroundColor,
                            percent: myLoadedCourse.courseCompletion! / 100,
                            // percent: 1.0,
                            progressColor: kPrimaryColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: CustomText(
                                    text:
                                        '${myLoadedCourse.courseCompletion}% Complete',
                                    fontSize: 12,
                                    colors: Colors.black54,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: CustomText(
                                  text:
                                      '${myLoadedCourse.totalNumberOfCompletedLessons}/${myLoadedCourse.totalNumberOfLessons}',
                                  fontSize: 14,
                                  colors: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // SliverToBoxAdapter(
            //   child: SizedBox(
            //     height: 60,
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(
            //           horizontal: 15.0, vertical: 10),
            //       child: TabBar(
            //         dividerHeight: 0,
            //         controller: _tabController,
            //         isScrollable: false,
            //         indicatorColor: kPrimaryColor,
            //         padding: EdgeInsets.zero,
            //         indicatorPadding: EdgeInsets.zero,
            //         labelPadding: EdgeInsets.zero,
            //         indicatorSize: TabBarIndicatorSize.tab,
            //         indicator: BoxDecoration(
            //             borderRadius: BorderRadius.circular(8),
            //             color: kPrimaryColor),
            //         unselectedLabelColor: Colors.black87,
            //         labelColor: Colors.white,
            //         tabs: [
            //           const Tab(
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Icon(
            //                   Icons.play_lesson,
            //                   size: 15,
            //                 ),
            //                 Text(
            //                   'Lessons',
            //                   style: TextStyle(
            //                     // fontWeight: FontWeight.bold,
            //                     fontSize: 14,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //           if (liveClassStatus == true)
            //             const Tab(
            //               child: Row(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   Icon(Icons.video_call),
            //                   Text(
            //                     'Live Class',
            //                     style: TextStyle(
            //                       // fontWeight: FontWeight.bold,
            //                       fontSize: 14,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           if (courseForumStatus == true)
            //             const Tab(
            //               child: Row(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   Icon(Icons.question_answer_outlined),
            //                   Text(
            //                     'Forum',
            //                     style: TextStyle(
            //                       // fontWeight: FontWeight.bold,
            //                       fontSize: 14,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            myCourseBodyTwo(),
            if (liveClassStatus == true)
              LiveClassTabWidget(courseId: widget.courseId),
            if (courseForumStatus == true)
              ForumTabWidget(courseId: widget.courseId),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBarTwo(),
      backgroundColor: kBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: kPrimaryColor.withOpacity(0.7)),
            )
          : liveClassStatus == false && courseForumStatus == false
              ? myCourseBody()
              : addonBody(),
    );
  }

  // Auto Navigate Video
  void _setLessonCompletedLocal(int lessonId) {
    final sections =
        Provider.of<MyCourses>(context, listen: false).sectionItems;
    for (final sec in sections) {
      for (final l in sec.mLesson!) {
        if (l.id == lessonId) {
          l.isCompleted = '1';
          return;
        }
      }
    }
  }

  // Next lesson nikaalo

  Lesson? _findNextLesson(Lesson current) {
    final sections =
        Provider.of<MyCourses>(context, listen: false).sectionItems;
    for (int si = 0; si < sections.length; si++) {
      final sec = sections[si];
      for (int li = 0; li < sec.mLesson!.length; li++) {
        if (sec.mLesson![li].id == current.id) {
          if (li + 1 < sec.mLesson!.length) return sec.mLesson![li + 1];
          if (si + 1 < sections.length &&
              sections[si + 1].mLesson!.isNotEmpty) {
            return sections[si + 1].mLesson!.first;
          }
        }
      }
    }
    return null;
  }

  bool _autoOpeningNext = false; // re-entry guard

  String _derivePlayableUrl(Lesson l) {
    return l.videoUrlWeb ?? l.videoUrl ?? '';
  }

  Widget _buildPlayerFor(Lesson l, String url) {
    final vt = (l.videoTypeWeb ?? '').toLowerCase();
    if (vt == 'youtube') {
      return PlayVideoFromYoutube(
          courseId: widget.courseId, lessonId: l.id!, videoUrl: url);
    }
    return PlayVideoFromNetwork(
      courseId: widget.courseId,
      lessonId: l.id!,
      videoUrl: url,
      language: selectedLanguage!.toLowerCase(),
    );
  }

  // Widget _buildPlayerFor(Lesson l, String url) {
  //   final t = (l.lessonType ?? '').toLowerCase();
  //   if (t == 'youtube') {
  //     return PlayVideoFromYoutube(courseId: widget.courseId, lessonId: l.id!, videoUrl: url);
  //   }
  //   return PlayVideoFromNetwork(courseId: widget.courseId, lessonId: l.id!, videoUrl: url);
  // }

  bool _isCompleted(dynamic v) {
    if (v is int) return v == 1;
    if (v is String) return v.trim() == '1';
    return false;
  }

  Future<void> _openLesson(Lesson lesson) async {
    final url = _derivePlayableUrl(lesson);

    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _buildPlayerFor(lesson, url)),
    );

    if (res is Map && res['completed'] == true) {
      // 1) server-sections refresh
      await Future.delayed(const Duration(seconds: 1));
      await Provider.of<MyCourses>(context, listen: false).fetchCourseSections(
          widget.courseId, selectedLanguage!.toLowerCase());
      if (!mounted) return;

      // 2) tick turant
      setState(() {});
      // ⬇️ ADD THIS
      if (res['next_is_quiz'] == true) {
        CommonFunctions.showWarningToast(
            'Next item is a Quiz — please open manually.');
        return;
      }
      // 3) cool-down + auto-next (server-verified)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 350));
        await _maybeAutoOpenNextServerStrict(lesson);
      });
    }
  }

  Future<void> _maybeAutoOpenNextServerStrict(Lesson current) async {
    if (!mounted) return;
    if (_autoOpeningNext) return;

    final sections =
        Provider.of<MyCourses>(context, listen: false).sectionItems;

    Lesson? cur;
    Lesson? next;
    outer:
    for (int si = 0; si < sections.length; si++) {
      final sec = sections[si];
      for (int li = 0; li < (sec.mLesson?.length ?? 0); li++) {
        final l = sec.mLesson![li];
        if (l.id == current.id) {
          cur = l;
          if (li + 1 < sec.mLesson!.length) {
            next = sec.mLesson![li + 1];
          } else if (si + 1 < sections.length &&
              (sections[si + 1].mLesson?.isNotEmpty ?? false)) {
            next = sections[si + 1].mLesson!.first;
          }
          break outer;
        }
      }
    }
    if (cur == null) return;

    final completedNow = _isCompleted(cur.isCompleted);
    final isQuiz = (next?.lessonType ?? '').toLowerCase() == 'quiz';

    // if next is quiz → just toast and stop
    if (isQuiz) {
      CommonFunctions.showWarningToast(
          'Next item is a Quiz — please open manually.');
      return;
    }

    if (completedNow && next != null && !isQuiz) {
      _autoOpeningNext = true;
      try {
        debugPrint('[AutoNext] Opening ${next.id} …');
        await _openLesson(next); // chain recursively
      } finally {
        _autoOpeningNext = false;
      }
    }
  }

// 🔍 Find previous lesson globally
  Lesson? _findPreviousLesson(Lesson current) {
    final sections =
        Provider.of<MyCourses>(context, listen: false).sectionItems;
    for (int si = 0; si < sections.length; si++) {
      final sec = sections[si];
      for (int li = 0; li < sec.mLesson!.length; li++) {
        if (sec.mLesson![li].id == current.id) {
          if (li > 0) return sec.mLesson![li - 1];
          if (si > 0 && sections[si - 1].mLesson!.isNotEmpty) {
            return sections[si - 1].mLesson!.last;
          }
        }
      }
    }
    return null;
  }

// 🔒 Lock full section until previous one complete
  bool _isSectionUnlocked(int sectionIndex, List sections) {
    if (sectionIndex == 0) return true;
    final prevSection = sections[sectionIndex - 1];
    for (final l in prevSection.mLesson!) {
      if (l.isCompleted != '1') return false;
    }
    return true;
  }

  bool _isSectionCompleted(dynamic section) {
    final ls = section.mLesson ?? [];
    for (final l in ls) {
      if ((l.isCompleted ?? '0') != '1') return false;
    }
    return true;
  }

// ✅ Drip lock check: true => lesson locked
  bool _isLessonLocked(List sections, int sectionIndex, int lessonIndex) {
    if (widget.enableDripContent != '1') return false;

    // first lesson of first section is always unlocked
    if (sectionIndex == 0 && lessonIndex == 0) return false;

    // previous in same section
    if (lessonIndex > 0) {
      final prev = sections[sectionIndex].mLesson![lessonIndex - 1];
      return (prev.isCompleted != '1');
    }

    // first of this section -> depends on last of previous section
    final prevSection = sections[sectionIndex - 1];
    if ((prevSection.mLesson?.isNotEmpty ?? false)) {
      return (prevSection.mLesson!.last.isCompleted != '1');
    }

    // safety: no previous lesson found -> keep locked
    return true;
  }
}

/// old code
// ignore_for_file: use_build_context_synchronously, deprecated_member_use
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:academy_app/constants.dart';
// import 'package:academy_app/models/common_functions.dart';
// import 'package:academy_app/models/course_db_model.dart';
// import 'package:academy_app/models/lesson.dart';
// import 'package:academy_app/models/section_db_model.dart';
// import 'package:academy_app/models/video_db_model.dart';
// import 'package:academy_app/providers/database_helper.dart';
// import 'package:academy_app/providers/my_courses.dart';
// import 'package:academy_app/screens/file_data_screen.dart';
// import 'package:academy_app/screens/vimeo_iframe.dart';
// import 'package:academy_app/widgets/app_bar_two.dart';
// import 'package:academy_app/widgets/custom_text.dart';
// import 'package:academy_app/widgets/forum_tab_widget.dart';
// import 'package:academy_app/widgets/from_vimeo_id.dart';
// import 'package:academy_app/widgets/live_class_tab_widget.dart';
// import 'package:background_downloader/background_downloader.dart';
// import 'package:flutter/material.dart';
// import 'package:html_unescape/html_unescape.dart';
// import 'package:http/http.dart' as http;
// import 'package:share_plus/share_plus.dart';
// import '../Utils/link_navigator.dart';
// import '../api/api_client.dart';
// import 'package:percent_indicator/percent_indicator.dart';
// import 'package:provider/provider.dart';
// // import 'package:share/share.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../providers/shared_pref_helper.dart';
// import '../widgets/from_network.dart';
// import '../widgets/from_youtube.dart';
// import 'course_detail_screen.dart';
// import 'webview_screen.dart';
// import 'webview_screen_iframe.dart';
//
// class MyCourseDetailScreen extends StatefulWidget {
//   static const routeName = '/my-course-details';
//   final int courseId;
//   final int len;
//   final String enableDripContent;
//   const MyCourseDetailScreen(
//       {super.key,
//         required this.courseId,
//         required this.len,
//         required this.enableDripContent});
//
//   @override
//   // ignore: library_private_types_in_public_api
//   _MyCourseDetailScreenState createState() => _MyCourseDetailScreenState();
// }
//
// class _MyCourseDetailScreenState extends State<MyCourseDetailScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late ScrollController _scrollController;
//
//   var _isInit = true;
//   var _isLoading = false;
//   int? selected;
//
//   dynamic liveClassStatus;
//   dynamic courseForumStatus;
//   dynamic data;
//   Lesson? _activeLesson;
//
//   String downloadId = "";
//
//   dynamic path;
//   dynamic fileName;
//   dynamic lessonId;
//   dynamic courseId;
//   dynamic sectionId;
//   dynamic courseTitle;
//   dynamic sectionTitle;
//   dynamic thumbnail;
//
//   DownloadTask? backgroundDownloadTask;
//   TaskStatus? downloadTaskStatus;
//
//   late StreamController<TaskProgressUpdate> progressUpdateStream;
// // Initial Selected Value
// //   String selectedLanguage = 'English';
// //
// //   // List of items in our dropdown menu
// //   var items = [
// //     'English',
// //     'Hindi',
// //   ];
//
//   List<String> items = [];
//   String? selectedLanguage;
//
//
//
//   Future<void> _refresh() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     Provider.of<MyCourses>(context, listen: false)
//         .fetchCourseSections(widget.courseId,selectedLanguage!.toLowerCase())
//         .then((_) {
//       final activeSections =
//           Provider.of<MyCourses>(context, listen: false).sectionItems;
//       debugPrint("activeSections --${activeSections.length}");
//       setState(() {
//         _isLoading = false;
//         _activeLesson = activeSections.first.mLesson!.first;
//       });
//     });
//
//
//     setState(() {
//       _isLoading = true;
//     });
//   }
//
//
//
//   @override
//   void initState() {
//     _scrollController = ScrollController();
//     _scrollController.addListener(_scrollListener);
//     _tabController = TabController(length: widget.len, vsync: this);
//     _tabController.addListener(_smoothScrollToTop);
//     progressUpdateStream = StreamController.broadcast();
//     super.initState();
//     addonStatus('live-class');
//     addonStatus('forum');
//     FileDownloader().configure(globalConfig: [
//       (Config.requestTimeout, const Duration(seconds: 100)),
//     ], androidConfig: [
//       (Config.useCacheDir, Config.whenAble),
//     ], iOSConfig: [
//       (Config.localize, {'Cancel': 'StopIt'}),
//     ]).then((result) => debugPrint('Configuration result = $result'));
//
//     // Registering a callback and configure notifications
//     FileDownloader()
//         .registerCallbacks(
//         taskNotificationTapCallback: myNotificationTapCallback)
//         .configureNotificationForGroup(FileDownloader.defaultGroup,
//         // For the main download button
//         // which uses 'enqueue' and a default group
//         running: const TaskNotification('Download {filename}',
//             'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining'),
//         complete: const TaskNotification(
//             'Download {filename}', 'Download complete'),
//         error: const TaskNotification(
//             'Download {filename}', 'Download failed'),
//         paused: const TaskNotification(
//             'Download {filename}', 'Paused with metadata {metadata}'),
//         progressBar: true)
//         .configureNotification(
//       // for the 'Download & Open' dog picture
//       // which uses 'download' which is not the .defaultGroup
//       // but the .await group so won't use the above config
//         complete: const TaskNotification(
//             'Download {filename}', 'Download complete'),
//         tapOpensFile: true); // dog can also open directly from tap
//
//     // Listen to updates and process
//     FileDownloader().updates.listen((update) async {
//       switch (update) {
//         case TaskStatusUpdate _:
//           if (update.task == backgroundDownloadTask) {
//             setState(() {
//               downloadTaskStatus = update.status;
//             });
//           }
//           if (downloadTaskStatus == TaskStatus.complete) {
//             await DatabaseHelper.instance.addVideo(
//               VideoModel(
//                   title: fileName,
//                   path: path,
//                   lessonId: lessonId,
//                   courseId: courseId,
//                   sectionId: sectionId,
//                   courseTitle: courseTitle,
//                   sectionTitle: sectionTitle,
//                   thumbnail: thumbnail,
//                   downloadId: downloadId),
//             );
//             var val = await DatabaseHelper.instance.courseExists(courseId);
//             if (val != true) {
//               await DatabaseHelper.instance.addCourse(
//                 CourseDbModel(
//                     courseId: courseId,
//                     courseTitle: courseTitle,
//                     thumbnail: thumbnail),
//               );
//             }
//             var sec = await DatabaseHelper.instance.sectionExists(sectionId);
//             if (sec != true) {
//               await DatabaseHelper.instance.addSection(
//                 SectionDbModel(
//                     courseId: courseId,
//                     sectionId: sectionId,
//                     sectionTitle: sectionTitle),
//               );
//             }
//           }
//           break;
//
//         case TaskProgressUpdate _:
//           progressUpdateStream.add(update); // pass on to widget for indicator
//           break;
//       }
//     });
//   }
//
//   /// Process the user tapping on a notification by printing a message
//   void myNotificationTapCallback(Task task, NotificationType notificationType) {
//     debugPrint(
//         'Tapped notification $notificationType for taskId ${task.directory}');
//   }
//
//   Future<void> processButtonPress(
//       lesson, myCourseId, coTitle, coThumbnail, secTitle, secId) async {
//     print("${BaseDirectory.applicationSupport}/system");
//     String fileUrl;
//
//     if (lesson.videoTypeWeb == 'html5' || lesson.videoTypeWeb == 'amazon') {
//       fileUrl = lesson.videoUrlWeb.toString();
//     } else if (lesson.videoTypeWeb == 'google_drive') {
//       final RegExp regExp = RegExp(r'[-\w]{25,}');
//       final Match? match = regExp.firstMatch(lesson.videoUrlWeb.toString());
//
//       fileUrl =
//       'https://drive.google.com/uc?export=download&id=${match!.group(0)}';
//     } else {
//       final token = await SharedPreferenceHelper().getAuthToken();
//       fileUrl =
//       '$BASE_URL/api_files/offline_video_for_mobile_app/${lesson.id}/$token';
//     }
//
//     backgroundDownloadTask = DownloadTask(
//         url: fileUrl,
//         filename: lesson.title.toString(),
//         directory: 'system',
//         baseDirectory: BaseDirectory.applicationSupport,
//         updates: Updates.statusAndProgress,
//         allowPause: true,
//         metaData: '<video metaData>');
//     await FileDownloader().enqueue(backgroundDownloadTask!);
//     if (mounted) {
//       setState(() {
//         path = "/data/user/0/com.greylearn.education/files/system";
//         fileName = lesson.title.toString();
//         lessonId = lesson.id;
//         courseId = myCourseId;
//         sectionId = secId;
//         courseTitle = coTitle;
//         sectionTitle = secTitle;
//         thumbnail = coThumbnail;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _scrollController.dispose();
//     progressUpdateStream.close();
//     FileDownloader().resetUpdates();
//     super.dispose();
//   }
//
//   _scrollListener() {
//     // if (fixedScroll) {
//     //   _scrollController.jumpTo(0);
//     // }
//   }
//
//   _smoothScrollToTop() {
//     _scrollController.animateTo(
//       0,
//       duration: const Duration(microseconds: 300),
//       curve: Curves.ease,
//     );
//
//     // setState(() {
//     //   fixedScroll = _tabController.index == 1;
//     // });
//   }
//
//   @override
//   void didChangeDependencies() {
//     if (_isInit) {
//       setState(() {
//         final myLoadedCourse =
//         Provider.of<MyCourses>(context, listen: false).findById(widget.courseId);
//
//         if (myLoadedCourse.language != null && myLoadedCourse.language!.isNotEmpty) {
//           items = myLoadedCourse.language!.split(","); // ['english','hindi']
//           selectedLanguage = items.first;
//         }
//         _isLoading = true;
//       });
//
//
//       Provider.of<MyCourses>(context, listen: false)
//           .fetchCourseSections(widget.courseId,selectedLanguage!.toLowerCase())
//           .then((_) {
//         final activeSections =
//             Provider.of<MyCourses>(context, listen: false).sectionItems;
//         debugPrint("activeSections2 --${activeSections.length}");
//         setState(() {
//           _isLoading = false;
//           if(activeSections.isNotEmpty){
//             _activeLesson = activeSections.first.mLesson!.first;
//           }
//         });
//       });
//     }
//     _isInit = false;
//     super.didChangeDependencies();
//   }
//
//   void _initDownload(
//       Lesson lesson, myCourseId, coTitle, coThumbnail, secTitle, secId) async {
//     print(lesson.toString());
//     if (lesson.videoTypeWeb == 'YouTube') {
//       CommonFunctions.showSuccessToast(
//           'This video format is not supported for download.');
//     } else if (lesson.videoTypeWeb == 'Vimeo' ||
//         lesson.videoTypeWeb == 'vimeo') {
//       CommonFunctions.showSuccessToast(
//           'This video format is not supported for download.');
//     } else {
//       var les = await DatabaseHelper.instance.lessonExists(lesson.id);
//       if (les == true) {
//         var check = await DatabaseHelper.instance.lessonDetails(lesson.id);
//         File checkPath = File("${check['path']}/${check['title']}");
//         print(checkPath.existsSync());
//         if (!checkPath.existsSync()) {
//           await DatabaseHelper.instance.removeVideo(check['id']);
//           processButtonPress(
//               lesson, myCourseId, coTitle, coThumbnail, secTitle, secId);
//         } else {
//           CommonFunctions.showSuccessToast('Video was downloaded already.');
//         }
//       } else {
//         processButtonPress(
//             lesson, myCourseId, coTitle, coThumbnail, secTitle, secId);
//       }
//     }
//   }
//
//   Future<void> addonStatus(String identifier) async {
//     var url = '$BASE_URL/api/addon_status?unique_identifier=$identifier';
//     final response = await ApiClient().get(url);
//     if (identifier == 'live-class') {
//       setState(() {
//         liveClassStatus = json.decode(response.body)['status'];
//       });
//     } else if (identifier == 'forum') {
//       setState(() {
//         courseForumStatus = json.decode(response.body)['status'];
//       });
//     }
//   }
//
//   void lessonAction(Lesson lesson) async {
//     print(lesson.toString());
//     if (lesson.lessonType == 'video') {
//       if (lesson.videoTypeWeb == 'html5' || lesson.videoTypeWeb == 'amazon') {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => PlayVideoFromNetwork(
//                   courseId: widget.courseId,
//                   lessonId: lesson.id!,
//                   videoUrl: lesson.videoUrlWeb!)),
//         );
//       } else if (lesson.videoTypeWeb == 'system') {
//         final token = await SharedPreferenceHelper().getAuthToken();
//         var url =
//             '$BASE_URL/api_files/file_content?course_id=${widget.courseId}&lesson_id=${lesson.id}&auth_token=$token';
//         // print(url);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => PlayVideoFromNetwork(
//                   courseId: widget.courseId,
//                   lessonId: lesson.id!,
//                   videoUrl: url)),
//         );
//       } else if (lesson.videoTypeWeb == 'google_drive') {
//         final RegExp regExp = RegExp(r'[-\w]{25,}');
//         final Match? match = regExp.firstMatch(lesson.videoUrlWeb.toString());
//
//         String url =
//             'https://drive.google.com/uc?export=download&id=${match!.group(0)}';
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//               builder: (context) => PlayVideoFromNetwork(
//                   courseId: widget.courseId,
//                   lessonId: lesson.id!,
//                   videoUrl: url)),
//         );
//       } else if (lesson.videoTypeWeb!.toLowerCase() == 'vimeo') {
//         print(lesson.videoUrlWeb);
//         String vimeoVideoId = lesson.videoUrlWeb!.split('/').last;
//         print("vimeoVideoId");
//         print(vimeoVideoId);
//         // Navigator.push(
//         //     context,
//         //     MaterialPageRoute(
//         //       builder: (context) => PlayVideoFromVimeoId(
//         //           courseId: widget.courseId,
//         //           lessonId: lesson.id!,
//         //           vimeoVideoId: vimeoVideoId),
//         //     ));
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               backgroundColor: kBackgroundColor,
//               titlePadding: EdgeInsets.zero,
//               title: const Padding(
//                 padding: EdgeInsets.only(left: 15.0, right: 15, top: 20),
//                 child: Center(
//                   child: Text('Choose Video player',
//                       style:
//                       TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
//                 ),
//               ),
//
//               actions: <Widget>[
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 MaterialButton(
//                   elevation: 0,
//                   color: kPrimaryColor,
//                   onPressed: () {
//                     debugPrint('PlayVideoFromVimeoId --> ${vimeoVideoId}');
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PlayVideoFromVimeoId(
//                               courseId: widget.courseId,
//                               lessonId: lesson.id!,
//                               vimeoVideoId: vimeoVideoId),
//                         ));
//                   },
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadiusDirectional.circular(6),
//                     // side: const BorderSide(color: kPrimaryColor),
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Vimeo',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 10,
//                 ),
//                 MaterialButton(
//                   elevation: 0,
//                   color: kPrimaryColor,
//                   onPressed: () {
//                     String vimUrl =
//                         'https://player.vimeo.com/video/$vimeoVideoId';
//                     debugPrint(vimUrl);
//                     Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => VimeoIframe(url: vimUrl)));
//                   },
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadiusDirectional.circular(6),
//                     // side: const BorderSide(color: kPrimaryColor),
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Vimeo Iframe',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//               ],
//             );
//           },
//         );
//       } else {
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlayVideoFromYoutube(
//                   courseId: widget.courseId,
//                   lessonId: lesson.id!,
//                   videoUrl: lesson.videoUrlWeb!),
//             ));
//       }
//     } else if (lesson.lessonType == 'quiz') {
//       // print(lesson.id);
//       final token = await SharedPreferenceHelper().getAuthToken();
//       final url = '$BASE_URL/api/quiz_mobile_web_view/${lesson.id}/$token';
//       print(url);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => WebViewScreen(url: url),
//         ),
//       ).then((result) {
//         _refresh();
//       });
//     } else {
//       if (lesson.attachmentType == 'iframe') {
//         final url = lesson.attachment;
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => WebViewScreenIframe(url: url)));
//       } else if (lesson.attachmentType == 'description') {
//         // data = lesson.attachment;
//         // Navigator.push(
//         //     context,
//         //     MaterialPageRoute(
//         //         builder: (context) =>
//         //             FileDataScreen(textData: data, note: lesson.summary!)));
//         final token = await SharedPreferenceHelper().getAuthToken();
//         final url = '$BASE_URL/api/lesson_mobile_web_view/${lesson.id}/$token';
//         // print(_url);
//         Navigator.push(context,
//             MaterialPageRoute(builder: (context) => WebViewScreen(url: url)));
//       } else if (lesson.attachmentType == 'txt') {
//         final url = '$BASE_URL/uploads/lesson_files/${lesson.attachment}';
//         data = await http.read(Uri.parse(url));
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) =>
//                     FileDataScreen(textData: data, note: lesson.summary!)));
//       } else {
//         final token = await SharedPreferenceHelper().getAuthToken();
//         final url =
//             '$BASE_URL/api_files/file_content?course_id=${widget.courseId}&lesson_id=${lesson.id}&auth_token=$token';
//         // print(url);
//         _launchURL(url);
//       }
//     }
//   }
//
//   void _launchURL(String lessonUrl) async {
//     if (!await launchUrl(Uri.parse(lessonUrl))) {
//       throw 'Could not launch $lessonUrl';
//     }
//   }
//
//   Widget getLessonSubtitle(Lesson lesson) {
//     if (lesson.lessonType == 'video') {
//       return CustomText(
//         text: lesson.duration,
//         fontSize: 12,
//       );
//     } else if (lesson.lessonType == 'quiz') {
//       return RichText(
//         text: const TextSpan(
//           children: [
//             WidgetSpan(
//               child: Icon(
//                 Icons.event_note,
//                 size: 12,
//                 color: kSecondaryColor,
//               ),
//             ),
//             TextSpan(
//                 text: 'Quiz',
//                 style: TextStyle(fontSize: 12, color: kSecondaryColor)),
//           ],
//         ),
//       );
//     } else {
//       return RichText(
//         text: const TextSpan(
//           children: [
//             WidgetSpan(
//               child: Icon(
//                 Icons.attach_file,
//                 size: 12,
//                 color: kSecondaryColor,
//               ),
//             ),
//             TextSpan(
//                 text: 'Attachment',
//                 style: TextStyle(fontSize: 12, color: kSecondaryColor)),
//           ],
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // final myCourseId = ModalRoute.of(context)!.settings.arguments as int;
//     debugPrint(widget.courseId.toString());
//     final myLoadedCourse = Provider.of<MyCourses>(context, listen: false)
//         .findById(widget.courseId);
//     final sections =
//         Provider.of<MyCourses>(context, listen: false).sectionItems;
//     debugPrint("sectionItems --${sections.length}");
//     myCourseBody() {
//       return SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           child: Column(
//             children: [
//               Card(
//                 elevation: 0.3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                   child: Column(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 10,
//                         ),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               flex: 1,
//                               child: RichText(
//                                 textAlign: TextAlign.left,
//                                 text: TextSpan(
//                                   text: myLoadedCourse.title,
//                                   style: const TextStyle(
//                                       fontSize: 20, color: Colors.black),
//                                 ),
//                               ),
//                             ),
//                             if (items.length > 1)
//                               Center(
//                                 child: DropdownButton(
//                                   // Initial Value
//                                   value: selectedLanguage,
//                                   // Down Arrow Icon
//                                   icon: const Icon(Icons.keyboard_arrow_down),
//                                   // Array list of items
//                                   items: items.map((lang) {
//                                     return DropdownMenuItem(value: lang, child: Text(
//                                       lang[0].toUpperCase() + lang.substring(1), // capitalize
//                                     ));
//                                   }).toList(),
//                                   // After selecting the desired option,it will
//                                   // change button value to selected value
//                                   onChanged: (newValue) {
//                                     setState(() {
//                                       selectedLanguage = newValue!;
//                                     });
//                                     _refresh();
//                                   },
//                                 ),
//                               )
//                             else
//                               const SizedBox.shrink(), // 👈 ek hi language hai to dropdown hide
//
//                             PopupMenuButton(
//                               onSelected: (value) {
//                                 if (value == 'details') {
//                                   Navigator.of(context).pushNamed(
//                                       CourseDetailScreen.routeName,
//                                       arguments: myLoadedCourse.id);
//                                 }
//                                 // else if(value == 'change'){
//                                 //   showDialog(
//                                 //     context: context,
//                                 //     builder: (BuildContext context) {
//                                 //       return AlertDialog(
//                                 //         backgroundColor: kBackgroundColor,
//                                 //         titlePadding: EdgeInsets.zero,
//                                 //         title: const Padding(
//                                 //           padding: EdgeInsets.only(left: 15.0, right: 15, top: 20),
//                                 //           child: Center(
//                                 //             child: Text('Choose Language',
//                                 //                 style:
//                                 //                 TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
//                                 //           ),
//                                 //         ),
//                                 //
//                                 //         actions: <Widget>[
//                                 //           const SizedBox(
//                                 //             height: 20,
//                                 //           ),
//                                 //           MaterialButton(
//                                 //             elevation: 0,
//                                 //             color: kPrimaryColor,
//                                 //             onPressed: () {
//                                 //               debugPrint('PlayVideoFromVimeoId --> }');
//                                 //
//                                 //             },
//                                 //             padding:
//                                 //             const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                                 //             shape: RoundedRectangleBorder(
//                                 //               borderRadius: BorderRadiusDirectional.circular(6),
//                                 //               // side: const BorderSide(color: kPrimaryColor),
//                                 //             ),
//                                 //             child: const Row(
//                                 //               mainAxisAlignment: MainAxisAlignment.center,
//                                 //               children: [
//                                 //                 Text(
//                                 //                   'English',
//                                 //                   style: TextStyle(
//                                 //                     fontSize: 16,
//                                 //                     color: Colors.white,
//                                 //                     fontWeight: FontWeight.w500,
//                                 //                   ),
//                                 //                 ),
//                                 //               ],
//                                 //             ),
//                                 //           ),
//                                 //           const SizedBox(
//                                 //             height: 10,
//                                 //           ),
//                                 //           MaterialButton(
//                                 //             elevation: 0,
//                                 //             color: kPrimaryColor,
//                                 //             onPressed: () {
//                                 //
//                                 //                },
//                                 //             padding:
//                                 //             const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                                 //             shape: RoundedRectangleBorder(
//                                 //               borderRadius: BorderRadiusDirectional.circular(6),
//                                 //               // side: const BorderSide(color: kPrimaryColor),
//                                 //             ),
//                                 //             child: const Row(
//                                 //               mainAxisAlignment: MainAxisAlignment.center,
//                                 //               children: [
//                                 //                 Text(
//                                 //                   'Hindi',
//                                 //                   style: TextStyle(
//                                 //                     fontSize: 16,
//                                 //                     color: Colors.white,
//                                 //                     fontWeight: FontWeight.w500,
//                                 //                   ),
//                                 //                 ),
//                                 //               ],
//                                 //             ),
//                                 //           ),
//                                 //           const SizedBox(height: 10),
//                                 //         ],
//                                 //       );
//                                 //     },
//                                 //   );
//                                 // }
//                                 else {
//                                   Share.share(
//                                       myLoadedCourse.shareableLink.toString());
//                                 }
//                               },
//                               icon: const Icon(
//                                 Icons.more_vert,
//                               ),
//                               itemBuilder: (_) => [
//                                 const PopupMenuItem(
//                                   value: 'details',
//                                   child: Text('Course Details'),
//                                 ),
//                                 const PopupMenuItem(
//                                   value: 'share',
//                                   child: Text('Share this Course'),
//                                 ),
//                                 // const PopupMenuItem(
//                                 //   value: 'change',
//                                 //   child: Text('Change Language'),
//                                 // ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         child: LinearPercentIndicator(
//                           lineHeight: 8.0,
//                           backgroundColor: kBackgroundColor,
//                           percent: myLoadedCourse.courseCompletion! / 100,
//                           // percent: 1.0,
//                           progressColor: kPrimaryColor,
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 10),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               flex: 1,
//                               child: Padding(
//                                 padding: const EdgeInsets.only(bottom: 10.0),
//                                 child: CustomText(
//                                   text:
//                                   '${myLoadedCourse.courseCompletion}% Complete',
//                                   fontSize: 12,
//                                   colors: Colors.black54,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(bottom: 10.0),
//                               child: CustomText(
//                                 text:
//                                 '${myLoadedCourse.totalNumberOfCompletedLessons}/${myLoadedCourse.totalNumberOfLessons}',
//                                 fontSize: 14,
//                                 colors: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       myLoadedCourse.courseCompletion! >= 100 ? Card(
//                         color: kGreenColorColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 0.1,
//                         child: GestureDetector(
//                           child: const Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               SizedBox(
//                                 height:20,
//                                 child: CircleAvatar(
//                                   backgroundColor: Colors.black54,
//                                   radius: 10,
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(2),
//                                     child: FittedBox(
//                                       child: Icon(
//                                         Icons.file_download,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child: CustomText(
//                                   text: "Download Certificate",
//                                   colors: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           onTap: () async {
//                             final token = await SharedPreferenceHelper().getAuthToken();
//                             final link = widget.courseId.toString();
//                             final url = '$BASE_URL/api/download_certificate_mobile_web_view/$link/$token';
//                             await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//                             // LinkNavigator.instance.navigate(context,widget.courseId.toString(), 'certificate', 0,false, token ?? '','');
//                           },
//                         ),
//                       ) : sections.length == 0 ? const Align(
//                         alignment: Alignment.center,
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(
//                             vertical: 5.0,
//                           ),
//                           child: CustomText(
//                             text: 'This course is expired',
//                             colors: Colors.red,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       )  : const SizedBox.shrink(),
//                     ],
//                   ),
//                 ),
//               ),
//               ListView.builder(
//                 key: Key('builder ${selected.toString()}'), //attention
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: sections.length,
//                 itemBuilder: (ctx, index) {
//                   final section = sections[index];
//                   return Card(
//                     elevation: 0.3,
//                     color: kBackgroundColor,
//                     child: Theme(
//                       data: Theme.of(context).copyWith(
//                         dividerColor: Colors.transparent,
//                         unselectedWidgetColor: Colors.transparent,
//                         colorScheme: const ColorScheme.light(
//                           primary: Colors.black,
//                         ),
//                       ),
//                       child: ExpansionTile(
//                         key: Key(index.toString()), //attention
//                         initiallyExpanded: index == selected,
//                         onExpansionChanged: ((newState) {
//                           if (newState) {
//                             setState(() {
//                               selected = index;
//                             });
//                           } else {
//                             setState(() {
//                               selected = -1;
//                             });
//                           }
//                         }),
//                         // collapsedShape: RoundedRectangleBorder(
//                         //   borderRadius: BorderRadius.circular(0),
//                         //   side: BorderSide.none,
//                         // ),
//                         // shape: RoundedRectangleBorder(
//                         //   borderRadius: BorderRadius.circular(0),
//                         //   side: BorderSide.none,
//                         // ),
//                         title: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Align(
//                               alignment: Alignment.centerLeft,
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 5.0,
//                                 ),
//                                 child: CustomText(
//                                   text: HtmlUnescape()
//                                       .convert(section.title.toString()),
//                                   colors: kDarkGreyColor,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding:
//                               const EdgeInsets.symmetric(vertical: 5.0),
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     flex: 1,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: kTimeBackColor,
//                                         borderRadius: BorderRadius.circular(3),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 5.0,
//                                       ),
//                                       child: Align(
//                                         alignment: Alignment.center,
//                                         child: CustomText(
//                                           text: section.totalDuration,
//                                           fontSize: 10,
//                                           colors: kTimeColor,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     width: 10.0,
//                                   ),
//                                   Expanded(
//                                     flex: 1,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: kLessonBackColor,
//                                         borderRadius: BorderRadius.circular(3),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 5.0,
//                                       ),
//                                       child: Align(
//                                         alignment: Alignment.center,
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             color: kLessonBackColor,
//                                             borderRadius:
//                                             BorderRadius.circular(3),
//                                           ),
//                                           child: CustomText(
//                                             text:
//                                             '${section.mLesson!.length} Lessons',
//                                             fontSize: 10,
//                                             colors: kDarkGreyColor,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const Expanded(flex: 2, child: Text("")),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         children: [
//                           widget.enableDripContent == '1'
//                               ? ListView.builder(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             itemCount: section.mLesson!.length,
//                             itemBuilder: (ctx, indexLess) {
//                               // return LessonListItem(
//                               //   lesson: section.mLesson[index],
//                               // );
//                               final lesson = section.mLesson![indexLess];
//                               return InkWell(
//                                 onTap: () {
//                                   if (sections[0].id == section.id) {
//                                     if (indexLess != 0) {
//                                       if (section.mLesson![indexLess - 1]
//                                           .isCompleted !=
//                                           '1') {
//                                         CommonFunctions.showWarningToast(
//                                             'previous lessons was not completed.');
//                                       } else {
//                                         setState(() {
//                                           _activeLesson = lesson;
//                                         });
//                                         lessonAction(_activeLesson!);
//                                       }
//                                     } else {
//                                       setState(() {
//                                         _activeLesson = lesson;
//                                       });
//                                       lessonAction(_activeLesson!);
//                                     }
//                                   } else {
//                                     if (sections[index - 1]
//                                         .mLesson!
//                                         .last
//                                         .isCompleted !=
//                                         '1') {
//                                       CommonFunctions.showWarningToast(
//                                           'previous lessons was not completed.');
//                                     } else {
//                                       setState(() {
//                                         _activeLesson = lesson;
//                                       });
//                                       lessonAction(_activeLesson!);
//                                     }
//                                   }
//                                 },
//                                 child: Column(
//                                   children: <Widget>[
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 10, horizontal: 10),
//                                       color: Colors.white60,
//                                       width: double.infinity,
//                                       child: Row(
//                                         children: <Widget>[
//                                           sections[0].id == section.id
//                                               ? indexLess == 0
//                                               ? lesson.lessonType ==
//                                               'video'
//                                               ? Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor:
//                                                 kPrimaryColor,
//                                                 value: lesson.isCompleted ==
//                                                     '1'
//                                                     ? true
//                                                     : false,
//                                                 onChanged:
//                                                     (bool?
//                                                 value) {
//                                                   CommonFunctions
//                                                       .showWarningToast(
//                                                       'Watch lessons to update course progress.');
//                                                 }),
//                                           )
//                                               : Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor:
//                                                 kPrimaryColor,
//                                                 value: lesson.isCompleted ==
//                                                     '1'
//                                                     ? true
//                                                     : false,
//                                                 onChanged:
//                                                     (bool?
//                                                 value) {
//                                                   // print(value);
//
//                                                   setState(
//                                                           () {
//                                                         lesson.isCompleted = value!
//                                                             ? '1'
//                                                             : '0';
//                                                         if (value) {
//                                                           myLoadedCourse.totalNumberOfCompletedLessons =
//                                                               myLoadedCourse.totalNumberOfCompletedLessons! + 1;
//                                                         } else {
//                                                           myLoadedCourse.totalNumberOfCompletedLessons =
//                                                               myLoadedCourse.totalNumberOfCompletedLessons! - 1;
//                                                         }
//                                                         var completePerc =
//                                                             (myLoadedCourse.totalNumberOfCompletedLessons! / myLoadedCourse.totalNumberOfLessons!) *
//                                                                 100;
//                                                         myLoadedCourse.courseCompletion =
//                                                             completePerc.round();
//                                                       });
//                                                   Provider.of<MyCourses>(
//                                                       context,
//                                                       listen:
//                                                       false)
//                                                       .toggleLessonCompleted(
//                                                       lesson.id!.toInt(),
//                                                       value! ? 1 : 0)
//                                                       .then((_) => CommonFunctions.showSuccessToast('Course Progress Updated'));
//                                                 }),
//                                           )
//                                               : section
//                                               .mLesson![
//                                           indexLess -
//                                               1]
//                                               .isCompleted !=
//                                               '1'
//                                               ? const Expanded(
//                                             flex: 1,
//                                             child: Icon(Icons
//                                                 .lock_outlined),
//                                           )
//                                               : lesson.lessonType ==
//                                               'video'
//                                               ? Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor: kPrimaryColor,
//                                                 value: lesson.isCompleted == '1' ? true : false,
//                                                 onChanged: (bool? value) {
//                                                   CommonFunctions.showWarningToast(
//                                                       'Watch lessons to update course progress.');
//                                                 }),
//                                           )
//                                               : Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor: kPrimaryColor,
//                                                 value: lesson.isCompleted == '1' ? true : false,
//                                                 onChanged: (bool? value) {
//                                                   // print(value);
//
//                                                   setState(
//                                                           () {
//                                                         lesson.isCompleted = value!
//                                                             ? '1'
//                                                             : '0';
//                                                         if (value) {
//                                                           myLoadedCourse.totalNumberOfCompletedLessons = myLoadedCourse.totalNumberOfCompletedLessons! + 1;
//                                                         } else {
//                                                           myLoadedCourse.totalNumberOfCompletedLessons = myLoadedCourse.totalNumberOfCompletedLessons! - 1;
//                                                         }
//                                                         var completePerc =
//                                                             (myLoadedCourse.totalNumberOfCompletedLessons! / myLoadedCourse.totalNumberOfLessons!) * 100;
//                                                         myLoadedCourse.courseCompletion =
//                                                             completePerc.round();
//                                                       });
//                                                   Provider.of<MyCourses>(context, listen: false)
//                                                       .toggleLessonCompleted(lesson.id!.toInt(), value! ? 1 : 0)
//                                                       .then((_) => CommonFunctions.showSuccessToast('Course Progress Updated'));
//                                                 }),
//                                           )
//                                               : sections[index - 1]
//                                               .mLesson!
//                                               .last
//                                               .isCompleted !=
//                                               '1'
//                                               ? const Expanded(
//                                             flex: 1,
//                                             child: Icon(Icons
//                                                 .lock_outlined),
//                                           )
//                                               : lesson.lessonType ==
//                                               'video'
//                                               ? Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor:
//                                                 kPrimaryColor,
//                                                 value: lesson.isCompleted ==
//                                                     '1'
//                                                     ? true
//                                                     : false,
//                                                 onChanged:
//                                                     (bool?
//                                                 value) {
//                                                   CommonFunctions
//                                                       .showWarningToast(
//                                                       'Watch lessons to update course progress.');
//                                                 }),
//                                           )
//                                               : Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor:
//                                                 kPrimaryColor,
//                                                 value: lesson.isCompleted ==
//                                                     '1'
//                                                     ? true
//                                                     : false,
//                                                 onChanged:
//                                                     (bool?
//                                                 value) {
//                                                   // print(value);
//
//                                                   setState(
//                                                           () {
//                                                         lesson.isCompleted = value!
//                                                             ? '1'
//                                                             : '0';
//                                                         if (value) {
//                                                           myLoadedCourse.totalNumberOfCompletedLessons =
//                                                               myLoadedCourse.totalNumberOfCompletedLessons! + 1;
//                                                         } else {
//                                                           myLoadedCourse.totalNumberOfCompletedLessons =
//                                                               myLoadedCourse.totalNumberOfCompletedLessons! - 1;
//                                                         }
//                                                         var completePerc =
//                                                             (myLoadedCourse.totalNumberOfCompletedLessons! / myLoadedCourse.totalNumberOfLessons!) *
//                                                                 100;
//                                                         myLoadedCourse.courseCompletion =
//                                                             completePerc.round();
//                                                       });
//                                                   Provider.of<MyCourses>(
//                                                       context,
//                                                       listen:
//                                                       false)
//                                                       .toggleLessonCompleted(
//                                                       lesson.id!.toInt(),
//                                                       value! ? 1 : 0)
//                                                       .then((_) => CommonFunctions.showSuccessToast('Course Progress Updated'));
//                                                 }),
//                                           ),
//                                           Expanded(
//                                             flex: 8,
//                                             child: Column(
//                                               crossAxisAlignment:
//                                               CrossAxisAlignment
//                                                   .start,
//                                               children: <Widget>[
//                                                 CustomText(
//                                                   text: lesson.title,
//                                                   fontSize: 14,
//                                                   colors: kTextColor,
//                                                   fontWeight:
//                                                   FontWeight.w400,
//                                                 ),
//                                                 getLessonSubtitle(lesson),
//                                               ],
//                                             ),
//                                           ),
//                                           if (lesson.lessonType ==
//                                               'video')
//                                             sections[0].id == section.id
//                                                 ? indexLess == 0
//                                                 ? Expanded(
//                                               flex: 2,
//                                               child: SizedBox.shrink(),
//                                             )
//                                                 : section
//                                                 .mLesson![
//                                             indexLess -
//                                                 1]
//                                                 .isCompleted ==
//                                                 '1'
//                                                 ? Expanded(
//                                               flex: 2,
//                                               child: SizedBox.shrink(),
//                                               //     IconButton(
//                                               //   icon: const Icon(
//                                               //       Icons
//                                               //           .file_download_outlined),
//                                               //   color: Colors
//                                               //       .black45,
//                                               //   onPressed: () => _initDownload(
//                                               //       lesson,
//                                               //       widget
//                                               //           .courseId,
//                                               //       myLoadedCourse
//                                               //           .title,
//                                               //       myLoadedCourse
//                                               //           .thumbnail,
//                                               //       section
//                                               //           .title,
//                                               //       section
//                                               //           .id),
//                                               // ),
//                                             )
//                                                 : Container()
//                                                 : sections[index - 1]
//                                                 .mLesson!
//                                                 .last
//                                                 .isCompleted !=
//                                                 '1'
//                                                 ? Container()
//                                                 : Expanded(
//                                               flex: 2,
//                                               child: SizedBox.shrink(),                                                            ),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                   ],
//                                 ),
//                               );
//                               // return Text(section.mLesson[index].title);
//                             },
//                           )
//                               : ListView.builder(
//                             shrinkWrap: true,
//                             physics: const NeverScrollableScrollPhysics(),
//                             itemBuilder: (ctx, index) {
//                               // return LessonListItem(
//                               //   lesson: section.mLesson[index],
//                               // );
//                               final lesson = section.mLesson![index];
//                               return InkWell(
//                                 onTap: () {
//                                   setState(() {
//                                     _activeLesson = lesson;
//                                   });
//                                   lessonAction(_activeLesson!);
//                                 },
//                                 child: Column(
//                                   children: <Widget>[
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 10, horizontal: 10),
//                                       color: Colors.white60,
//                                       width: double.infinity,
//                                       child: Row(
//                                         children: <Widget>[
//                                           Expanded(
//                                             flex: 1,
//                                             child: Checkbox(
//                                                 activeColor:
//                                                 kPrimaryColor,
//                                                 value:
//                                                 lesson.isCompleted ==
//                                                     '1'
//                                                     ? true
//                                                     : false,
//                                                 onChanged: (bool? value) {
//                                                   // print(value);
//
//                                                   setState(() {
//                                                     lesson.isCompleted =
//                                                     value!
//                                                         ? '1'
//                                                         : '0';
//                                                     if (value) {
//                                                       myLoadedCourse
//                                                           .totalNumberOfCompletedLessons =
//                                                           myLoadedCourse
//                                                               .totalNumberOfCompletedLessons! +
//                                                               1;
//                                                     } else {
//                                                       myLoadedCourse
//                                                           .totalNumberOfCompletedLessons =
//                                                           myLoadedCourse
//                                                               .totalNumberOfCompletedLessons! -
//                                                               1;
//                                                     }
//                                                     var completePerc = (myLoadedCourse
//                                                         .totalNumberOfCompletedLessons! /
//                                                         myLoadedCourse
//                                                             .totalNumberOfLessons!) *
//                                                         100;
//                                                     myLoadedCourse
//                                                         .courseCompletion =
//                                                         completePerc
//                                                             .round();
//                                                   });
//                                                   Provider.of<MyCourses>(
//                                                       context,
//                                                       listen: false)
//                                                       .toggleLessonCompleted(
//                                                       lesson.id!
//                                                           .toInt(),
//                                                       value! ? 1 : 0)
//                                                       .then((_) => CommonFunctions
//                                                       .showSuccessToast(
//                                                       'Course Progress Updated'));
//                                                 }),
//                                           ),
//                                           Expanded(
//                                             flex: 8,
//                                             child: Column(
//                                               crossAxisAlignment:
//                                               CrossAxisAlignment
//                                                   .start,
//                                               children: <Widget>[
//                                                 CustomText(
//                                                   text: lesson.title,
//                                                   fontSize: 14,
//                                                   colors: kTextColor,
//                                                   fontWeight:
//                                                   FontWeight.w400,
//                                                 ),
//                                                 getLessonSubtitle(lesson),
//                                               ],
//                                             ),
//                                           ),
//                                           if (lesson.lessonType ==
//                                               'video')
//                                             Expanded(
//                                               flex: 2,
//                                               child: SizedBox.shrink(),                                                  ),
//                                         ],
//                                       ),
//                                     ),
//                                     const SizedBox(
//                                       height: 10,
//                                     ),
//                                   ],
//                                 ),
//                               );
//                               // return Text(section.mLesson[index].title);
//                             },
//                             itemCount: section.mLesson!.length,
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     myCourseBodyTwo() {
//       return SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10.0),
//           child: ListView.builder(
//             key: Key('builder ${selected.toString()}'), //attention
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: sections.length,
//             itemBuilder: (ctx, index) {
//               final section = sections[index];
//               return Card(
//                 elevation: 0.3,
//                 child: Theme(
//                   data: Theme.of(context).copyWith(
//                     dividerColor: Colors.transparent,
//                     unselectedWidgetColor: Colors.transparent,
//                     colorScheme: const ColorScheme.light(
//                       primary: Colors.black,
//                     ),
//                   ),
//                   child: ExpansionTile(
//                     key: Key(index.toString()), //attention
//                     initiallyExpanded: index == selected,
//                     onExpansionChanged: ((newState) {
//                       if (newState) {
//                         setState(() {
//                           selected = index;
//                         });
//                       } else {
//                         setState(() {
//                           selected = -1;
//                         });
//                       }
//                     }), //attention
//                     title: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(
//                               vertical: 5.0,
//                             ),
//                             child: CustomText(
//                               text: HtmlUnescape()
//                                   .convert(section.title.toString()),
//                               colors: kDarkGreyColor,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 5.0),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 flex: 1,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: kTimeBackColor,
//                                     borderRadius: BorderRadius.circular(3),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 5.0,
//                                   ),
//                                   child: Align(
//                                     alignment: Alignment.center,
//                                     child: CustomText(
//                                       text: section.totalDuration,
//                                       fontSize: 10,
//                                       colors: kTimeColor,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(
//                                 width: 10.0,
//                               ),
//                               Expanded(
//                                 flex: 1,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: kLessonBackColor,
//                                     borderRadius: BorderRadius.circular(3),
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 5.0,
//                                   ),
//                                   child: Align(
//                                     alignment: Alignment.center,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: kLessonBackColor,
//                                         borderRadius: BorderRadius.circular(3),
//                                       ),
//                                       child: CustomText(
//                                         text:
//                                         '${section.mLesson!.length} Lessons',
//                                         fontSize: 10,
//                                         colors: kDarkGreyColor,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const Expanded(flex: 2, child: Text("")),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     children: [
//                       widget.enableDripContent == '1'
//                           ? ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: section.mLesson!.length,
//                         itemBuilder: (ctx, indexLess) {
//                           // return LessonListItem(
//                           //   lesson: section.mLesson[index],
//                           // );
//                           final lesson = section.mLesson![indexLess];
//                           return InkWell(
//                             onTap: () {
//                               if (sections[0].id == section.id) {
//                                 if (indexLess != 0) {
//                                   if (section.mLesson![indexLess - 1]
//                                       .isCompleted !=
//                                       '1') {
//                                     CommonFunctions.showWarningToast(
//                                         'previous lessons was not completed.');
//                                   } else {
//                                     setState(() {
//                                       _activeLesson = lesson;
//                                     });
//                                     lessonAction(_activeLesson!);
//                                   }
//                                 } else {
//                                   setState(() {
//                                     _activeLesson = lesson;
//                                   });
//                                   lessonAction(_activeLesson!);
//                                 }
//                               } else {
//                                 if (sections[index - 1]
//                                     .mLesson!
//                                     .last
//                                     .isCompleted !=
//                                     '1') {
//                                   CommonFunctions.showWarningToast(
//                                       'previous lessons was not completed.');
//                                 } else {
//                                   setState(() {
//                                     _activeLesson = lesson;
//                                   });
//                                   lessonAction(_activeLesson!);
//                                 }
//                               }
//                             },
//                             child: Column(
//                               children: <Widget>[
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 10, horizontal: 10),
//                                   color: Colors.white60,
//                                   width: double.infinity,
//                                   child: Row(
//                                     children: <Widget>[
//                                       sections[0].id == section.id
//                                           ? indexLess == 0
//                                           ? lesson.lessonType ==
//                                           'video'
//                                           ? Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor:
//                                             kPrimaryColor,
//                                             value:
//                                             lesson.isCompleted ==
//                                                 '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged:
//                                                 (bool?
//                                             value) {
//                                               CommonFunctions
//                                                   .showWarningToast(
//                                                   'Watch lessons to update course progress.');
//                                             }),
//                                       )
//                                           : Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor:
//                                             kPrimaryColor,
//                                             value:
//                                             lesson.isCompleted ==
//                                                 '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged:
//                                                 (bool?
//                                             value) {
//                                               // print(value);
//
//                                               setState(() {
//                                                 lesson.isCompleted =
//                                                 value!
//                                                     ? '1'
//                                                     : '0';
//                                                 if (value) {
//                                                   myLoadedCourse
//                                                       .totalNumberOfCompletedLessons =
//                                                       myLoadedCourse.totalNumberOfCompletedLessons! +
//                                                           1;
//                                                 } else {
//                                                   myLoadedCourse
//                                                       .totalNumberOfCompletedLessons =
//                                                       myLoadedCourse.totalNumberOfCompletedLessons! -
//                                                           1;
//                                                 }
//                                                 var completePerc =
//                                                     (myLoadedCourse.totalNumberOfCompletedLessons! /
//                                                         myLoadedCourse.totalNumberOfLessons!) *
//                                                         100;
//                                                 myLoadedCourse
//                                                     .courseCompletion =
//                                                     completePerc
//                                                         .round();
//                                               });
//                                               Provider.of<MyCourses>(
//                                                   context,
//                                                   listen:
//                                                   false)
//                                                   .toggleLessonCompleted(
//                                                   lesson
//                                                       .id!
//                                                       .toInt(),
//                                                   value!
//                                                       ? 1
//                                                       : 0)
//                                                   .then((_) =>
//                                                   CommonFunctions.showSuccessToast(
//                                                       'Course Progress Updated'));
//                                             }),
//                                       )
//                                           : section
//                                           .mLesson![
//                                       indexLess -
//                                           1]
//                                           .isCompleted !=
//                                           '1'
//                                           ? const Expanded(
//                                         flex: 1,
//                                         child: Icon(Icons
//                                             .lock_outlined),
//                                       )
//                                           : lesson.lessonType ==
//                                           'video'
//                                           ? Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor:
//                                             kPrimaryColor,
//                                             value: lesson.isCompleted ==
//                                                 '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged:
//                                                 (bool?
//                                             value) {
//                                               CommonFunctions
//                                                   .showWarningToast(
//                                                   'Watch lessons to update course progress.');
//                                             }),
//                                       )
//                                           : Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor:
//                                             kPrimaryColor,
//                                             value: lesson.isCompleted ==
//                                                 '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged:
//                                                 (bool?
//                                             value) {
//                                               // print(value);
//
//                                               setState(
//                                                       () {
//                                                     lesson.isCompleted = value!
//                                                         ? '1'
//                                                         : '0';
//                                                     if (value) {
//                                                       myLoadedCourse.totalNumberOfCompletedLessons =
//                                                           myLoadedCourse.totalNumberOfCompletedLessons! + 1;
//                                                     } else {
//                                                       myLoadedCourse.totalNumberOfCompletedLessons =
//                                                           myLoadedCourse.totalNumberOfCompletedLessons! - 1;
//                                                     }
//                                                     var completePerc =
//                                                         (myLoadedCourse.totalNumberOfCompletedLessons! / myLoadedCourse.totalNumberOfLessons!) *
//                                                             100;
//                                                     myLoadedCourse.courseCompletion =
//                                                         completePerc.round();
//                                                   });
//                                               Provider.of<MyCourses>(
//                                                   context,
//                                                   listen:
//                                                   false)
//                                                   .toggleLessonCompleted(
//                                                   lesson.id!.toInt(),
//                                                   value! ? 1 : 0)
//                                                   .then((_) => CommonFunctions.showSuccessToast('Course Progress Updated'));
//                                             }),
//                                       )
//                                           : sections[index - 1]
//                                           .mLesson!
//                                           .last
//                                           .isCompleted !=
//                                           '1'
//                                           ? const Expanded(
//                                         flex: 1,
//                                         child: Icon(Icons
//                                             .lock_outlined),
//                                       )
//                                           : lesson.lessonType ==
//                                           'video'
//                                           ? Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor:
//                                             kPrimaryColor,
//                                             value:
//                                             lesson.isCompleted ==
//                                                 '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged:
//                                                 (bool?
//                                             value) {
//                                               CommonFunctions
//                                                   .showWarningToast(
//                                                   'Watch lessons to update course progress.');
//                                             }),
//                                       )
//                                           : Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor:
//                                             kPrimaryColor,
//                                             value:
//                                             lesson.isCompleted ==
//                                                 '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged:
//                                                 (bool?
//                                             value) {
//                                               // print(value);
//
//                                               setState(() {
//                                                 lesson.isCompleted =
//                                                 value!
//                                                     ? '1'
//                                                     : '0';
//                                                 if (value) {
//                                                   myLoadedCourse
//                                                       .totalNumberOfCompletedLessons =
//                                                       myLoadedCourse.totalNumberOfCompletedLessons! +
//                                                           1;
//                                                 } else {
//                                                   myLoadedCourse
//                                                       .totalNumberOfCompletedLessons =
//                                                       myLoadedCourse.totalNumberOfCompletedLessons! -
//                                                           1;
//                                                 }
//                                                 var completePerc =
//                                                     (myLoadedCourse.totalNumberOfCompletedLessons! /
//                                                         myLoadedCourse.totalNumberOfLessons!) *
//                                                         100;
//                                                 myLoadedCourse
//                                                     .courseCompletion =
//                                                     completePerc
//                                                         .round();
//                                               });
//                                               Provider.of<MyCourses>(
//                                                   context,
//                                                   listen:
//                                                   false)
//                                                   .toggleLessonCompleted(
//                                                   lesson
//                                                       .id!
//                                                       .toInt(),
//                                                   value!
//                                                       ? 1
//                                                       : 0)
//                                                   .then((_) =>
//                                                   CommonFunctions.showSuccessToast(
//                                                       'Course Progress Updated'));
//                                             }),
//                                       ),
//
//                                       //OLD CODE
//
//                                       Expanded(
//                                         flex: 8,
//                                         child: Column(
//                                           crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                           children: <Widget>[
//                                             CustomText(
//                                               text: lesson.title,
//                                               fontSize: 14,
//                                               colors: kTextColor,
//                                               fontWeight: FontWeight.w400,
//                                             ),
//                                             getLessonSubtitle(lesson),
//                                           ],
//                                         ),
//                                       ),
//
//                                       if (lesson.lessonType == 'video')
//                                         sections[0].id == section.id
//                                             ? indexLess == 0
//                                             ? Expanded(
//                                           flex: 2,
//                                           child: SizedBox.shrink(),                                                        )
//                                             : section
//                                             .mLesson![
//                                         indexLess -
//                                             1]
//                                             .isCompleted ==
//                                             '1'
//                                             ? Expanded(
//                                           flex: 2,
//                                           child: SizedBox.shrink(),                                                            )
//                                             : Container()
//                                             : sections[index - 1]
//                                             .mLesson!
//                                             .last
//                                             .isCompleted !=
//                                             '1'
//                                             ? Container()
//                                             : Expanded(
//                                           flex: 2,
//                                           child: SizedBox.shrink(),                                                        ),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(
//                                   height: 10,
//                                 ),
//                               ],
//                             ),
//                           );
//                           // return Text(section.mLesson[index].title);
//                         },
//                       )
//                           : ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: section.mLesson!.length,
//                         itemBuilder: (ctx, indexLess) {
//                           // return LessonListItem(
//                           //   lesson: section.mLesson[index],
//                           // );
//                           final lesson = section.mLesson![indexLess];
//                           return InkWell(
//                             onTap: () {
//                               setState(() {
//                                 _activeLesson = lesson;
//                               });
//                               lessonAction(_activeLesson!);
//                             },
//                             child: Column(
//                               children: <Widget>[
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 10, horizontal: 10),
//                                   color: Colors.white60,
//                                   width: double.infinity,
//                                   child: Row(
//                                     children: <Widget>[
//                                       Expanded(
//                                         flex: 1,
//                                         child: Checkbox(
//                                             activeColor: kPrimaryColor,
//                                             value:
//                                             lesson.isCompleted == '1'
//                                                 ? true
//                                                 : false,
//                                             onChanged: (bool? value) {
//                                               // print(value);
//
//                                               setState(() {
//                                                 lesson.isCompleted =
//                                                 value! ? '1' : '0';
//                                                 if (value) {
//                                                   myLoadedCourse
//                                                       .totalNumberOfCompletedLessons =
//                                                       myLoadedCourse
//                                                           .totalNumberOfCompletedLessons! +
//                                                           1;
//                                                 } else {
//                                                   myLoadedCourse
//                                                       .totalNumberOfCompletedLessons =
//                                                       myLoadedCourse
//                                                           .totalNumberOfCompletedLessons! -
//                                                           1;
//                                                 }
//                                                 var completePerc = (myLoadedCourse
//                                                     .totalNumberOfCompletedLessons! /
//                                                     myLoadedCourse
//                                                         .totalNumberOfLessons!) *
//                                                     100;
//                                                 myLoadedCourse
//                                                     .courseCompletion =
//                                                     completePerc.round();
//                                               });
//                                               Provider.of<MyCourses>(
//                                                   context,
//                                                   listen: false)
//                                                   .toggleLessonCompleted(
//                                                   lesson.id!.toInt(),
//                                                   value! ? 1 : 0)
//                                                   .then((_) => CommonFunctions
//                                                   .showSuccessToast(
//                                                   'Course Progress Updated'));
//                                             }),
//                                       ),
//                                       Expanded(
//                                         flex: 8,
//                                         child: Column(
//                                           crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                           children: <Widget>[
//                                             CustomText(
//                                               text: lesson.title,
//                                               fontSize: 14,
//                                               colors: kTextColor,
//                                               fontWeight: FontWeight.w400,
//                                             ),
//                                             getLessonSubtitle(lesson),
//                                           ],
//                                         ),
//                                       ),
//                                       if (lesson.lessonType == 'video')
//                                         Expanded(
//                                           flex: 2,
//                                           child: SizedBox.shrink(),                                              ),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(
//                                   height: 10,
//                                 ),
//                               ],
//                             ),
//                           );
//                           // return Text(section.mLesson[index].title);
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       );
//     }
//
//     addonBody() {
//       return NestedScrollView(
//         controller: _scrollController,
//         headerSliverBuilder: (context, value) {
//           return [
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 child: Card(
//                   elevation: 0.3,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Column(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             vertical: 10,
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 flex: 1,
//                                 child: RichText(
//                                   textAlign: TextAlign.left,
//                                   text: TextSpan(
//                                     text: myLoadedCourse.title,
//                                     style: const TextStyle(
//                                         fontSize: 20, color: Colors.black),
//                                   ),
//                                 ),
//                               ),
//                               PopupMenuButton(
//                                 onSelected: (value) {
//                                   if (value == 'details') {
//                                     Navigator.of(context).pushNamed(
//                                         CourseDetailScreen.routeName,
//                                         arguments: myLoadedCourse.id);
//                                   } else {
//                                     Share.share(myLoadedCourse.shareableLink
//                                         .toString());
//                                   }
//                                 },
//                                 icon: const Icon(
//                                   Icons.more_vert,
//                                 ),
//                                 itemBuilder: (_) => [
//                                   const PopupMenuItem(
//                                     value: 'details',
//                                     child: Text('Course Details'),
//                                   ),
//                                   const PopupMenuItem(
//                                     value: 'share',
//                                     child: Text('Share this Course'),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           child: LinearPercentIndicator(
//                             lineHeight: 8.0,
//                             backgroundColor: kBackgroundColor,
//                             percent: myLoadedCourse.courseCompletion! / 100,
//                             // percent: 1.0,
//                             progressColor: kPrimaryColor,
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 flex: 1,
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(bottom: 10.0),
//                                   child: CustomText(
//                                     text:
//                                     '${myLoadedCourse.courseCompletion}% Complete',
//                                     fontSize: 12,
//                                     colors: Colors.black54,
//                                   ),
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.only(bottom: 10.0),
//                                 child: CustomText(
//                                   text:
//                                   '${myLoadedCourse.totalNumberOfCompletedLessons}/${myLoadedCourse.totalNumberOfLessons}',
//                                   fontSize: 14,
//                                   colors: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             // SliverToBoxAdapter(
//             //   child: SizedBox(
//             //     height: 60,
//             //     child: Padding(
//             //       padding: const EdgeInsets.symmetric(
//             //           horizontal: 15.0, vertical: 10),
//             //       child: TabBar(
//             //         dividerHeight: 0,
//             //         controller: _tabController,
//             //         isScrollable: false,
//             //         indicatorColor: kPrimaryColor,
//             //         padding: EdgeInsets.zero,
//             //         indicatorPadding: EdgeInsets.zero,
//             //         labelPadding: EdgeInsets.zero,
//             //         indicatorSize: TabBarIndicatorSize.tab,
//             //         indicator: BoxDecoration(
//             //             borderRadius: BorderRadius.circular(8),
//             //             color: kPrimaryColor),
//             //         unselectedLabelColor: Colors.black87,
//             //         labelColor: Colors.white,
//             //         tabs: [
//             //           const Tab(
//             //             child: Row(
//             //               mainAxisAlignment: MainAxisAlignment.center,
//             //               children: [
//             //                 Icon(
//             //                   Icons.play_lesson,
//             //                   size: 15,
//             //                 ),
//             //                 Text(
//             //                   'Lessons',
//             //                   style: TextStyle(
//             //                     // fontWeight: FontWeight.bold,
//             //                     fontSize: 14,
//             //                   ),
//             //                 ),
//             //               ],
//             //             ),
//             //           ),
//             //           if (liveClassStatus == true)
//             //             const Tab(
//             //               child: Row(
//             //                 mainAxisAlignment: MainAxisAlignment.center,
//             //                 children: [
//             //                   Icon(Icons.video_call),
//             //                   Text(
//             //                     'Live Class',
//             //                     style: TextStyle(
//             //                       // fontWeight: FontWeight.bold,
//             //                       fontSize: 14,
//             //                     ),
//             //                   ),
//             //                 ],
//             //               ),
//             //             ),
//             //           if (courseForumStatus == true)
//             //             const Tab(
//             //               child: Row(
//             //                 mainAxisAlignment: MainAxisAlignment.center,
//             //                 children: [
//             //                   Icon(Icons.question_answer_outlined),
//             //                   Text(
//             //                     'Forum',
//             //                     style: TextStyle(
//             //                       // fontWeight: FontWeight.bold,
//             //                       fontSize: 14,
//             //                     ),
//             //                   ),
//             //                 ],
//             //               ),
//             //             ),
//             //         ],
//             //       ),
//             //     ),
//             //   ),
//             // ),
//           ];
//         },
//         body: TabBarView(
//           controller: _tabController,
//           children: [
//             myCourseBodyTwo(),
//             if (liveClassStatus == true)
//               LiveClassTabWidget(courseId: widget.courseId),
//             if (courseForumStatus == true)
//               ForumTabWidget(courseId: widget.courseId),
//           ],
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: const CustomAppBarTwo(),
//       backgroundColor: kBackgroundColor,
//       body: _isLoading
//           ? Center(
//         child: CircularProgressIndicator(
//             color: kPrimaryColor.withOpacity(0.7)),
//       )
//           : liveClassStatus == false && courseForumStatus == false
//           ? myCourseBody()
//           : addonBody(),
//     );
//   }
// }
//
//
//
//
//
//
//
//
