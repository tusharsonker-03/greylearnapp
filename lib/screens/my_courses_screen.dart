// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:academy_app/providers/my_bundles.dart';
import 'package:academy_app/providers/my_courses.dart';
import 'package:academy_app/widgets/my_bundle_grid.dart';
import 'package:academy_app/widgets/my_course_grid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../api/api_client.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import 'package:skeletonizer/skeletonizer.dart';


class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  _MyCoursesScreenState createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool _isLoading = true;
  dynamic bundleStatus = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_smoothScrollToTop);

    addonStatus();

    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
      return;
    }
    if (!mounted) {
      return;
    }

    _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  _scrollListener() {
    // if (fixedScroll) {
    //   _scrollController.jumpTo(0);
    // }
  }

  _smoothScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> addonStatus() async {
    var url = '$BASE_URL/api/addon_status?unique_identifier=course_bundle';
    final response = await ApiClient().get(url);
    setState(() {
      _isLoading = false;
      bundleStatus = json.decode(response.body)['status'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _isLoading
          // ? Center(
          //     child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
          //   )
          ? const MyCoursesSkeleton()   // 🔥 loading → skeleton

          : bundleStatus == true
              ? NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, value) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: false,
                            indicatorColor: kPrimaryColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: kPrimaryColor),
                            unselectedLabelColor: Colors.black87,
                            dividerHeight: 0,
                            labelColor: Colors.white,
                            tabs: const [
                              Tab(
                                
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_lesson,
                                      size: 15,
                                    ),
                                    Text(
                                      'My Courses',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.all_inbox,
                                      size: 15,
                                    ),
                                    Text(
                                      'My Bundles',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      courseView(),
                      bundleView(),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'My Courses',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      courseView(),
                    ],
                  ),
                ),
    );
  }

  Widget courseView() {
    return FutureBuilder(
      future: Provider.of<MyCourses>(context, listen: false).fetchMyCourses(),
      builder: (ctx, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * .7,
            // child: Center(
            //   child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
            // ),
            child: MyCoursesSkeleton(), // 🔥 loading → skeleton

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
                          child: Text('Please check your Internet connection'),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text('Error Occured'),
                    // child: Text(dataSnapshot.error.toString()),
                  );
          } else {
            return Consumer<MyCourses>(
              builder: (context, myCourseData, child) =>
                  AlignedGridView.count(
                padding: const EdgeInsets.all(10.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                itemCount: myCourseData.items.length,
                itemBuilder: (ctx, index) {
                  return MyCourseGrid(
                    myCourse: myCourseData.items[index],
                  );
                  // return Text(myCourseData.items[index].title);
                },
                mainAxisSpacing: 5.0,
                crossAxisSpacing: 5.0,
              ),
            );
          }
        }
      },
    );
  }

  Widget bundleView() {
    return SingleChildScrollView(
      child: FutureBuilder(
        future: Provider.of<MyBundles>(context, listen: false).fetchMybundles(),
        builder: (ctx, dataSnapshot) {
          if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return const MyCoursesSkeleton(); // 🔥 loading → skeleton

          // return Center(
            //   child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
            // );
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
                        ],
                      ),
                    )
                  : Center(
                      // child: Text('Error Occured'),
                      child: Text(dataSnapshot.error.toString()),
                    );
            } else {
              return Consumer<MyBundles>(
                builder: (context, myBundleData, child) =>
                    AlignedGridView.count(
                  padding: const EdgeInsets.all(10.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  itemCount: myBundleData.bundleItems.length,
                  itemBuilder: (ctx, index) {
                    return MyBundleGrid(
                      myBundle: myBundleData.bundleItems[index],
                    );
                    // return Text(myCourseData.items[index].title);
                  },
                  mainAxisSpacing: 5.0,
                  crossAxisSpacing: 5.0,
                ),
              );
            }
          }
        },
      ),
    );
  }
}


class MyCoursesSkeleton extends StatelessWidget {
  const MyCoursesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 "My Courses" heading
              const SizedBox(height: 4),
              const Text(
                'My Courses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF003840),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 2-column grid of course cards (6 items)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6, // 6 skeleton cards
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.70, // approx same as design
                ),
                itemBuilder: (_, __) => const _MyCourseCardSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyCourseCardSkeleton extends StatelessWidget {
  const _MyCourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // 🔸 Top banner image (same style as real card)
          Container(
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xffe5ebeb),
              borderRadius: BorderRadius.only(
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF003840),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 🔸 Rating row: ⭐⭐⭐ + (45)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
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
                  '(45)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 🔸 Progress bar (white bg, green foreground – Skeletonizer phir bhi grey karega)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xffE6EFF2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.4, // e.g. 40% completed
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff00A66C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 🔸 Completed text row: "34% Completed"  "49/144"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '34% Completed',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF003840),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '49/144',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF003840),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
