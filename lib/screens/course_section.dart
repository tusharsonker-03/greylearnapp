import 'package:flutter/material.dart';

// Your existing imports:
import '../constants.dart';
import '../models/course.dart';
import '../widgets/course_grid.dart';

typedef CourseTapCallback = void Function();

class CourseSection extends StatelessWidget {
  final String title;
  final List<Course> courses;
  final bool isLoading;
  final CourseTapCallback onTapAll;

  const CourseSection({
    Key? key,
    required this.title,
    required this.courses,
    required this.isLoading,
    required this.onTapAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (courses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: onTapAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: Row(
                    children: [
                      const Text('All courses', style: TextStyle(fontSize: 14,color: kDarkGreyColor),),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: kDarkGreyColor.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (courses.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: courses.length,
              itemBuilder: (ctx, i) {
                final c = courses[i];
                return CourseGrid(
                  id: c.id,
                  title: c.title,
                  thumbnail: c.thumbnail,
                  instructorName: c.instructor,
                  instructorImage: c.instructorImage,
                  rating: c.rating,
                  price: c.price,
                );
              },
            ),
          ),
      ],
    );
  }
}
