import 'package:academy_app/widgets/custom_text.dart';

import '../Utils/image_cache.dart';
import '../screens/course_detail_screen.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../screens/newcoursedetail_landing_page.dart';
import '../widgets/star_display_widget.dart';

class CourseGrid extends StatelessWidget {
  final int? id;
  final String? title;
  final String? thumbnail;
  final String? instructorName;
  final String? instructorImage;
  final int? rating;
  final String? price;

  const CourseGrid({
    super.key,
    @required this.id,
    @required this.title,
    @required this.thumbnail,
    @required this.instructorName,
    @required this.instructorImage,
    @required this.rating,
    @required this.price,
  });

  @override
  Widget build(BuildContext context) {

    // unique cache key per course card
    final cacheKey = 'course_thumb_${id ?? 0}';
    final imageUrl = thumbnail?.toString() ?? '';

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .pushNamed(CourseLandingPage.routeName, arguments: id);
      },
      child: FittedBox(
        child: SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black38, width: 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                  //     ClipRRect(
                  //       borderRadius: BorderRadius.circular(10),
                  //       child: FadeInImage.assetNetwork(
                  //         placeholder: 'assets/images/loading_animated.gif',
                  //         image: thumbnail.toString(),
                  //         height: 120,
                  //         width: 180,
                  //         fit: BoxFit.cover,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _CachedThumb(
                          cacheKey: cacheKey,
                          url: imageUrl,
                          height: 120,
                          width: 180,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 5, right: 8, left: 8, top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 20,
                          child: Text(
                            title.toString().length < 41
                                ? title.toString()
                                : '${title.toString().substring(0, 40)}...',
                            style: const TextStyle(
                                fontSize: 12, color: kTextLightColor),
                          ),
                        ),
                        const SizedBox(height: 4), // chhoti spacing add ki readability ke liye

                        // Visibility(
                        //   visible: false,
                        //   child: Row(
                        //     children: [
                        //       CircleAvatar(
                        //         radius: 10,
                        //         backgroundImage:
                        //             NetworkImage(instructorImage.toString()),
                        //         backgroundColor: kLightBlueColor,
                        //       ),
                        //       Padding(
                        //         padding: const EdgeInsets.only(left: 5.0),
                        //         child: CustomText(
                        //           text: instructorName,
                        //           fontSize: 13,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            StarDisplayWidget(
                              value: rating!,
                              filledStar: const Icon(
                                Icons.star,
                                color: kStarColor,
                                size: 14,
                              ),
                              unfilledStar: const Icon(
                                Icons.star_border,
                                color: kStarColor,
                                size: 14,
                              ),
                            ),
                            Text(
                              price ?? "0",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: kTextLightColor),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small helper widget: loads from SharedPrefs cache or fetches & caches.
/// Uses SPImageCache.loadProvider(cacheKey, url)
class _CachedThumb extends StatelessWidget {
  final String cacheKey;
  final String url;
  final double height;
  final double width;

  const _CachedThumb({
    required this.cacheKey,
    required this.url,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: SPImageCache.loadProvider(cacheKey, url, maxAge: const Duration(days: 7)),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return Image.asset(
            'assets/images/loading_animated.gif',
            height: height,
            width: width,
            fit: BoxFit.cover,
          );
        }
        return Image(
          image: snap.data!,
          height: height,
          width: width,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
