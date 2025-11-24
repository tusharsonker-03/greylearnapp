import 'package:academy_app/providers/courses.dart';
import 'package:academy_app/screens/tabs_screen.dart';
import 'package:academy_app/widgets/app_bar_two.dart';
import 'package:academy_app/widgets/course_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import 'coursedetailscreendeeiplink.dart';
import 'package:skeletonizer/skeletonizer.dart'; // ✅ NEW

class CoursesScreen extends StatefulWidget {
  static const routeName = '/courses';
  const CoursesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  var _isInit = true;
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      final routeArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      final pageDataType = routeArgs['type'] as CoursesPageData;
      if (pageDataType == CoursesPageData.Category) {
        final categoryId = routeArgs['category_id'] as int;
        Provider.of<Courses>(context)
            .fetchCoursesByCategory(categoryId)
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else if (pageDataType == CoursesPageData.Search) {
        final searchQuery = routeArgs['seacrh_query'] as String;

        Provider.of<Courses>(context)
            .fetchCoursesBySearchQuery(searchQuery)
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else if (pageDataType == CoursesPageData.All) {
        Provider.of<Courses>(context)
            .filterCourses('all', 'all', 'all', 'all', 'all')
            .then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseData = Provider.of<Courses>(context, listen: false).items;
    final courseCount = courseData.length;
    return WillPopScope(onWillPop: _handleBackToHome,
        child: Scaffold(
      appBar: const CustomAppBarr(),
      backgroundColor: kBackgroundColor,
      body: _isLoading
      //     ? Center(
      //   child: CircularProgressIndicator(color: kPrimaryColor.withOpacity(0.7)),
      // )
          ? const _CoursesSkeleton()

          : SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Showing $courseCount Courses',
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (ctx, index) {
                  return Center(
                    child: CourseListItem(
                      id: courseData[index].id!.toInt(),
                      title: courseData[index].title.toString(),
                      thumbnail: courseData[index].thumbnail.toString(),
                      rating: courseData[index].rating!.toInt(),
                      price: courseData[index].price.toString(),
                      instructor: courseData[index].instructor.toString(),
                      noOfRating:
                      courseData[index].totalNumberRating!.toInt(),
                    ),
                  );
                },
                itemCount: courseData.length,
              ),
            ),
          ],
        ),
      ),
    ), )
      ;
  }

// TOP of _MyCoursesScreenState
  Future<bool> _handleBackToHome() async {
    // Home tab (index 0) par jao, purana stack clear kar do to avoid duplicates
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => TabsScreen(index: 0)),
          (route) => false,
    );
    return false; // we handled it
  }
}

class _CoursesSkeleton extends StatelessWidget {
  const _CoursesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // 🔹 Top "Showing X Courses" header skeleton
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing 00 Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            // 🔹 Skeleton course cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6, // 6 fake cards
                itemBuilder: (context, index) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffe5ebeb),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail placeholder
                          Container(
                            width: 90,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text placeholders
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SizedBox(
                                  height: 16,
                                  child: Text(
                                    'Course title placeholder',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 6),
                                SizedBox(
                                  height: 14,
                                  child: Text(
                                    'Instructor name',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '₹0',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '⭐ 0.0 (0)',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
