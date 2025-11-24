import 'dart:async';
import 'dart:convert';
import 'package:academy_app/screens/webview_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:academy_app/models/app_logo.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../constants.dart';
import '../screens/tabs_screen.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    show YoutubePlayer, YoutubePlayerController, YoutubePlayerFlags;

import '../providers/shared_pref_helper.dart';
import '../widgets/custom_text.dart';
import '../widgets/star_display_widget.dart';
import '../widgets/tab_view_details.dart';
import '../widgets/from_network.dart';
import '../widgets/from_vimeo_id.dart';
import '../widgets/lesson_list_item.dart';
import '../models/common_functions.dart';
import '../providers/courses.dart';
import 'auth_screen.dart';

class CourseDetailScreenDL extends StatefulWidget {
  final int courseId;
  final Map<String, dynamic> prefetch;

  const CourseDetailScreenDL({
    super.key,
    required this.courseId,
    required this.prefetch,
  });

  @override
  State<CourseDetailScreenDL> createState() => _CourseDetailScreenDLState();
}

class _CourseDetailScreenDLState extends State<CourseDetailScreenDL>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Map<String, dynamic> data; // local snapshot (prefetch -> UI now)

  // 👇 Purchased ko provider-first rakho; prefetch fallback rakho
  bool _parsePurchased(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    data = Map<String, dynamic>.from(widget.prefetch);

    // Background refresh (non-blocking)
    Future.microtask(() async {
      try {
        await Provider.of<Courses>(context, listen: false)
            .fetchCourseDetailById(widget.courseId);
        if (mounted) setState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ---- helpers to read fields safely from prefetch ----
  T? _get<T>(String key) {
    final v = data[key];
    if (v is T) return v;
    return null;
  }

  List _list(String key) {
    final v = data[key];
    if (v is List) return v;
    return const [];
  }

  String get _title => (_get<String>('title') ?? 'Course');
  String get _thumb => (_get<String>('thumbnail') ?? '');

  // ===== Rating: robust parsing (string/int/double) + safe int for stars =====
  num get _ratingRaw {
    final v = data['rating'];
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  int get _ratingInt => _ratingRaw.round().clamp(0, 5);
  String get _ratingLabel {
    // show 4.5 as "4.5", 4 as "4.0"
    if (_ratingRaw % 1 == 0) return _ratingRaw.toStringAsFixed(1);
    return _ratingRaw.toString();
  }

  String get _priceStr {
    final p = _get<dynamic>('price');
    return (p == null) ? '' : p.toString();
  }

  bool get _isPurchased => (_get<bool>('isPurchased') ??
      (() {
        final s = _get<dynamic>('isPurchased');
        if (s is String) return s == '1' || s.toLowerCase() == 'true';
        if (s is num) return s != 0;
        return false;
      }()) ??
      false);

  String get _overviewProvider => (_get<String>('course_overview_provider') ??
      _get<String>('courseOverviewProvider') ??
      '');

  String get _overviewUrl => (_get<String>('course_overview_url') ??
      _get<String>('courseOverviewUrl') ??
      '');

  // ---- helpers to convert dynamic list -> List<String> ----
  List<String> _asStrings(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .cast<String>()
          .toList();
    }
    return const <String>[];
  }

  // Prefetch sections (multi-key fallback)
  List<Map<String, dynamic>> _sectionsFromPrefetch() {
    List asList(dynamic v) => (v is List) ? v : const [];
    final candidates = [
      data['mSection'],
      data['sections'],
      data['course_sections'],
      data['m_section'],
    ];
    for (final cand in candidates) {
      final raw = asList(cand);
      if (raw.isNotEmpty) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  // === SAFE access to provider.getCourseDetail (prevents "Bad state: No element") ===
  dynamic _safeGetCourseDetail(BuildContext context) {
    try {
      // if provider getter throws (list empty), we catch and return null
      return context.watch<Courses>().getCourseDetail;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ----- tabs data (prefetch > provider) -----
    final includesPref = data['course_includes'] ?? data['courseIncludes'];
    final outcomesPref = data['course_outcomes'] ?? data['courseOutcomes'];
    final reqsPref = data['course_requirements'] ?? data['courseRequirements'];

    final provDetail = _safeGetCourseDetail(context); // may be null
    final includesProv = provDetail?.courseIncludes;
    final outcomesProv = provDetail?.courseOutcomes;
    final reqsProv = provDetail?.courseRequirements;

    final includesStr = _asStrings(includesPref ?? includesProv);
    final outcomesStr = _asStrings(outcomesPref ?? outcomesProv);
    final reqsStr = _asStrings(reqsPref ?? reqsProv);

    // ----- curriculum data -----
    final preSections = _sectionsFromPrefetch();
    final provSections = (provDetail?.mSection ?? const []);
    final bool useProviderSections = provSections.isNotEmpty;

    final bool isPurchased = (provDetail?.isPurchased == true) ||
        _parsePurchased(data['isPurchased']);

    return WillPopScope(
      onWillPop: () async {
        // System/gesture back -> directly Home (tab index = 1)
        Navigator.of(context).pushNamedAndRemoveUntil(
          TabsScreen.routeName,
              (route) => false,
          arguments: {'index': 1},
        );
        return false; // pop ko consume kar liya
      },
      child: Scaffold(
        appBar: const CustomAppBarr(),
        backgroundColor: kBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ===== Hero / Poster =====
              Padding(
                padding: const EdgeInsets.all(15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: MediaQuery.of(context).size.height / 3.3,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          image: _thumb.isNotEmpty
                              ? DecorationImage(
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.6),
                              BlendMode.dstATop,
                            ),
                            image: NetworkImage(_thumb),
                          )
                              : null,
                        ),
                      ),
                    ),
                    ClipOval(
                      child: InkWell(
                        onTap: _openOverview,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [kDefaultShadow],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Image.asset('assets/images/play.png'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Title / Rating =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style:
                        const TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: StarDisplayWidget(
                        value: _ratingInt,
                        filledStar:
                        const Icon(Icons.star, color: kStarColor, size: 18),
                        unfilledStar: const Icon(Icons.star_border,
                            color: kStarColor, size: 18),
                      ),
                    ),
                    Text('( $_ratingLabel )',
                        style:
                        const TextStyle(fontSize: 11, color: kTextColor)),
                    const SizedBox(width: 8),
                    CustomText(
                        text:
                        '${_get<num>('number_of_ratings') ?? _get<num>('totalNumberRating') ?? 0}+ Rating',
                        fontSize: 11,
                        colors: kTextColor),
                  ],
                ),
              ),

              // ===== Price / Share / CTA =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(right: 15, left: 15, bottom: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        text: _priceStr,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        colors: kTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: kSecondaryColor),
                      onPressed: () => Share.share(
                          (_get<String>('shareable_link') ??
                              _get<String>('shareableLink') ??
                              '')),
                    ),
                    MaterialButton(
                      onPressed: _handleCTA,
                      color: isPurchased ? kGreenPurchaseColor : kPrimaryColor,
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7)),
                      child: Text(isPurchased
                          ? 'Purchased'
                          : ((_get<String>('is_free_course') ??
                          _get<String>('isFreeCourse') ??
                          '0') ==
                          '1'
                          ? 'Get Enroll'
                          : 'Buy Now')),
                    )
                  ],
                ),
              ),

              // ===== Tabs =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TabBar(
                          controller: _tab,
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: kPrimaryColor),
                          unselectedLabelColor: kTextColor,
                          labelColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                          tabs: const [
                            Tab(
                                child: Text('Includes',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11))),
                            Tab(
                                child: Text('Outcomes',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11))),
                            Tab(
                                child: Text('Requirements',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10))),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 300,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            TabViewDetails(
                                titleText: 'What is Included',
                                listText: includesStr),
                            TabViewDetails(
                                titleText: 'What you will learn',
                                listText: outcomesStr),
                            TabViewDetails(
                                titleText: 'Course Requirements',
                                listText: reqsStr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== Course Curriculum =====
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    text: 'Course Curriculum',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    colors: kDarkGreyColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: useProviderSections
                // === EXACT SAME UI as CourseDetailScreen ===
                    ? (provSections.isNotEmpty
                    ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provSections.length,
                  itemBuilder: (ctx, index) {
                    final section =
                    provSections[index]; // Section model
                    return Card(
                      elevation: 0.3,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          unselectedWidgetColor: Colors.transparent,
                          colorScheme: const ColorScheme.light(
                              primary: Colors.black),
                        ),
                        child: ExpansionTile(
                          key: Key(index.toString()),
                          title: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5.0),
                                  child: CustomText(
                                    text: HtmlUnescape().convert(
                                        section.title.toString()),
                                    colors: kDarkGreyColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: kTimeBackColor,
                                          borderRadius:
                                          BorderRadius.circular(
                                              3),
                                        ),
                                        padding: const EdgeInsets
                                            .symmetric(vertical: 5.0),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: CustomText(
                                            text: section
                                                .totalDuration ??
                                                '',
                                            fontSize: 10,
                                            colors: kTimeColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: kLessonBackColor,
                                          borderRadius:
                                          BorderRadius.circular(
                                              3),
                                        ),
                                        padding: const EdgeInsets
                                            .symmetric(vertical: 5.0),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: kLessonBackColor,
                                              borderRadius:
                                              BorderRadius
                                                  .circular(3),
                                            ),
                                            child: CustomText(
                                              text:
                                              '${section.mLesson?.length ?? 0} Lessons',
                                              fontSize: 10,
                                              colors: kDarkGreyColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                        flex: 2, child: SizedBox()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              itemCount: section.mLesson?.length ?? 0,
                              itemBuilder: (ctx, j) {
                                final lesson = section.mLesson![j];
                                return Column(
                                  children: [
                                    LessonListItem(
                                      lesson: lesson,
                                      courseId:
                                      provDetail?.courseId ??
                                          widget.courseId,
                                    ),
                                    if (j <
                                        (section.mLesson?.length ??
                                            0) -
                                            1)
                                      Divider(
                                        height: 3,
                                        color: Colors.grey[200],
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
                    : const Center(child: Text('No Section')))
                // === Prefetch fallback (simple list tile) ===
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sectionsFromPrefetch().length,
                  itemBuilder: (ctx, i) {
                    final section = _sectionsFromPrefetch()[i];
                    final lessons = (section['mLesson'] is List)
                        ? (section['mLesson'] as List)
                        : const [];
                    final title = HtmlUnescape()
                        .convert('${section['title'] ?? ''}');
                    final dur = '${section['totalDuration'] ?? ''}';

                    return Card(
                      elevation: 0.3,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          unselectedWidgetColor: Colors.transparent,
                          colorScheme: const ColorScheme.light(
                              primary: Colors.black),
                        ),
                        child: ExpansionTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5),
                                child: CustomText(
                                    text: title,
                                    colors: kDarkGreyColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                      child: _chip(dur, kTimeBackColor,
                                          kTimeColor)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _chip(
                                          '${lessons.length} Lessons',
                                          kLessonBackColor,
                                          kDarkGreyColor)),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              itemCount: lessons.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 3, color: Colors.grey[200]),
                              itemBuilder: (_, j) {
                                final l = lessons[j] as Map?;
                                return ListTile(
                                  title:
                                  Text('${l?['title'] ?? 'Lesson'}'),
                                  subtitle:
                                  Text('${l?['duration'] ?? ''}'),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      padding: const EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.center,
      child: CustomText(text: text, fontSize: 10, colors: fg),
    );
  }

  void _openOverview() {
    final provider = _overviewProvider;
    final url = _overviewUrl;
    if (url.isEmpty) {
      CommonFunctions.showSuccessToast('Video url not provided');
      return;
    }
    if (provider == 'vimeo') {
      final parts = url.split('/').where((s) => s.trim().isNotEmpty).toList();
      if (parts.isEmpty) {
        CommonFunctions.showSuccessToast('Invalid Vimeo URL');
        return;
      }
      final id = parts.last;
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayVideoFromVimeoId(
                courseId: widget.courseId, vimeoVideoId: id),
          ));
    } else if (provider == 'html5') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlayVideoFromNetwork(
                  courseId: widget.courseId, videoUrl: url)));
    } else {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId == null) {
        CommonFunctions.showSuccessToast('Invalid YouTube URL');
        return;
      }
      final controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(autoPlay: true, mute: false),
      );
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => YoutubePlayer(controller: controller)));
    }
  }

  Future<void> _handleCTA() async {
    final base = BASE_URL;
    final token = await SharedPreferenceHelper().getAuthToken();
    final loggedIn = token != null && token.trim().isNotEmpty;

    // ✅ runtime provider-based purchased
    final prov = _safeGetCourseDetail(context);
    final alreadyPurchased =
        (prov?.isPurchased == true) || _parsePurchased(data['isPurchased']);

    if (alreadyPurchased) {
      CommonFunctions.showSuccessToast('Already purchased');
      return;
    }

    // ✅ login gate
    if (!loggedIn) {
      CommonFunctions.showSuccessToast('Please login first');
      if (mounted) {
        Navigator.of(context).pushNamed(AuthScreen.routeName);
      }
      return;
    }

    // Free course enroll
    final isFree = (_get<String>('is_free_course') ??
        _get<String>('isFreeCourse') ??
        '0') ==
        '1';

    if (isFree) {
      try {
        await Provider.of<Courses>(context, listen: false)
            .getEnrolled(widget.courseId);

        // re-fetch detail to sync provider flag
        await Provider.of<Courses>(context, listen: false)
            .fetchCourseDetailById(widget.courseId);

        if (mounted) setState(() => data['isPurchased'] = true);
        CommonFunctions.showSuccessToast('Enrolled Successfully');
      } catch (_) {
        CommonFunctions.showWarningToast(
            'Something went wrong. Please try again.');
      }
      return;
    }

    // Paid flow -> open WebView
    final url =
        '$base/api/web_redirect_to_buy_course/$token/${widget.courseId}/academybycreativeitem';

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: url)),
    );

    // 👇 WebView se back par fresh detail le aao (purchase complete ho chuka ho to reflect ho)
    try {
      await Provider.of<Courses>(context, listen: false)
          .fetchCourseDetailById(widget.courseId);
      if (mounted) setState(() {});
    } catch (_) {}
  }

//   Future<void> _handleCTA() async {
//     final base  = BASE_URL;
//     final token = await SharedPreferenceHelper().getAuthToken();
//     final loggedIn = token != null && token.trim().isNotEmpty;
//
//     // Already purchased? kuch mat karo
//     if (_isPurchased) return;
//
//     // ✅ Universal login gate: Buy/Get Enroll pe tap par agar login nahi hai
//     if (!loggedIn) {
//       CommonFunctions.showSuccessToast('Please login first');
//       if (mounted) {
//         Navigator.of(context).pushNamed(AuthScreen.routeName);
//       }
//       return;
//     }
//
//     // Free course enroll
//     final isFree = (_get<String>('is_free_course') ??
//         _get<String>('isFreeCourse') ?? '0') == '1';
//
//     if (isFree) {
//       try {
//         await Provider.of<Courses>(context, listen: false)
//             .getEnrolled(widget.courseId);
//         if (mounted) setState(() => data['isPurchased'] = true);
//         CommonFunctions.showSuccessToast('Enrolled Successfully');
//       } catch (_) {
//         CommonFunctions.showWarningToast('Something went wrong. Please try again.');
//       }
//       return;
//     }
//
//     // Paid flow: web redirect with token
//     // final url = '$base/api/web_redirect_to_buy_course/$token/${widget.courseId}/academybycreativeitem';
//     // if (!await launchUrl(Uri.parse(url))) {
//     //   CommonFunctions.showWarningToast('Could not open purchase page');
//     // }
//     final url =
//         '$base/api/web_redirect_to_buy_course/$token/${widget.courseId}/academybycreativeitem';
//
// // open inside app WebView
//     if (!mounted) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => WebViewScreen(url: url),
//       ),
//     );
//
//   }
}

class CustomAppBarr extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const CustomAppBarr({super.key})
      : preferredSize = const Size.fromHeight(50.0);

  @override
  _CustomAppBarTwoState createState() => _CustomAppBarTwoState();
}

class _CustomAppBarTwoState extends State<CustomAppBarr> {
  final _controller = StreamController<AppLogo>();

  fetchMyLogo() async {
    var url = '$BASE_URL/api/app_logo';
    try {
      final response = await ApiClient().get(url);
      if (response.statusCode == 200) {
        var logo = AppLogo.fromJson(jsonDecode(response.body));
        _controller.add(logo);
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyLogo();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0.3,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: kSecondaryColor),

      // 👇 override back behavior
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            TabsScreen.routeName,
                (route) => false,
            arguments: {'index': 1}, // ✅ open tab index=1
          );
        },
      ),

      title: StreamBuilder<AppLogo>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const SizedBox();
          }
          if (snapshot.hasError) {
            return const Text("Error Occurred");
          }
          final logo = snapshot.data!;
          final url = (logo.darkLogo ?? '').toString();
          if (url.isEmpty) return const SizedBox();
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            height: 27,
          );
        },
      ),
    );
  }
}
