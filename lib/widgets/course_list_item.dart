import 'package:academy_app/screens/course_detail_screen.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../screens/newcoursedetail_landing_page.dart';
import '../widgets/star_display_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CourseListItem extends StatelessWidget {
  final int? id;
  final String? title;
  final String? thumbnail;
  final int? rating;
  final String? price;
  final String? instructor;
  final int? noOfRating;

  const CourseListItem({
    super.key,
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.rating,
    required this.price,
    required this.instructor,
    required this.noOfRating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            CourseLandingPage.routeName,
            arguments: id,
          );
        },
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 📸 Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/images/loading_animated.gif',
                    image: thumbnail.toString(),
                    width: 140,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                // 📄 Text Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // ✅ auto-adjust height
                    children: <Widget>[
                      Text(
                        title.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instructor.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price.toString(),
                        style: const TextStyle(
                          color: kTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // ⭐ Rating Row
                      Row(
                        children: <Widget>[
                          StarDisplayWidget(
                            value: rating ?? 0,
                            filledStar: const Icon(
                              Icons.star,
                              color: kStarColor,
                              size: 15,
                            ),
                            unfilledStar: const Icon(
                              Icons.star_border,
                              color: kStarColor,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '( $noOfRating )',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CourseListItemSkeleton extends StatelessWidget {
  const CourseListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: const _CourseListItemSkeletonInner(),
    );
  }
}

/// Actual layout skeleton (Skeletonizer is upar)
class _CourseListItemSkeletonInner extends StatelessWidget {
  const _CourseListItemSkeletonInner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 📸 Image placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 140,
                  height: 100,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 10),
              // 📄 Text Section – placeholder texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    // Title
                    Text(
                      'Course title placeholder',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Instructor
                    Text(
                      'Instructor name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Price
                    Text(
                      '₹0,000',
                      style: TextStyle(
                        color: kTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    // ⭐ Rating Row
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.star,
                          color: kStarColor,
                          size: 15,
                        ),
                        Icon(
                          Icons.star,
                          color: kStarColor,
                          size: 15,
                        ),
                        Icon(
                          Icons.star,
                          color: kStarColor,
                          size: 15,
                        ),
                        Icon(
                          Icons.star_border,
                          color: kStarColor,
                          size: 15,
                        ),
                        Icon(
                          Icons.star_border,
                          color: kStarColor,
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '( 0 )',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
