import 'dart:convert';

class CourseLandingData {
  final int id;
  final String title;
  final String categoryName;
  final String courseduration;
  final String shortdescription;
  final String languages;
  final String thumbnail;
  final String heroimg;
  final String infotitle;
  final String price;
  final double rating;
  final int numberOfRatings;
  final int totalEnrollment;
  final int totalEnrollmentfake;
  final String certificateUrl;
  final bool isPurchased;
  final bool isFreeCourse;
  final String webLink;
  final List<String> reviewFaces; // reviews_user_images[]
  final List<Testimonial> testimonials; // testimonials[]
  final List<LandingSection> sections; // sections[]
  final List<String> outcomes; // outcomes
  final List<String> whatyouwillbelearn; // outcomes
  final List<String> learnwithgreylearn; // outcomes
  final Map<String, String> faqs; // faq

  CourseLandingData({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.shortdescription,
    required this.languages,
    required this.thumbnail,
    required this.heroimg,
    required this.infotitle,
    required this.price,
    required this.courseduration,
    required this.rating,
    required this.numberOfRatings,
    required this.totalEnrollment,
    required this.totalEnrollmentfake,
    required this.certificateUrl,
    required this.isPurchased,
    required this.isFreeCourse,
    required this.webLink,
    required this.reviewFaces,
    required this.testimonials,
    required this.sections,
    required this.outcomes, // NEW
    required this.whatyouwillbelearn, // NEW
    required this.learnwithgreylearn, // NEW
    required this.faqs,
  });

  factory CourseLandingData.fromApiJson(Map<String, dynamic> m) {
    // API returns numbers as strings sometimes, so guard everything
    int _toInt(dynamic v) => int.tryParse('$v') ?? 0;
    double _toDouble(dynamic v) => double.tryParse('$v') ?? 0.0;
    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v == 1;
      final s = ('$v').trim().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    final faces = (m['reviews_user_images'] as List<dynamic>?)
            ?.map((e) => '$e')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final testi = (m['testimonials'] as List<dynamic>?)
            ?.map((t) => Testimonial.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];

    final secs = (m['sections'] as List<dynamic>?)
            ?.map((s) => LandingSection.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    final outs = (m['outcomes'] as List<dynamic>?)
            ?.map((e) => '$e'.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final whatUwillearn = (m['course_benefits'] as List<dynamic>?)
            ?.map((e) => '$e'.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final learnwthgrey = (m['course_highlights'] as List<dynamic>?)
            ?.map((e) => '$e'.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    Map<String, String> _parseFaqs(dynamic v) {
      String _clean(String s) {
        return s
            .replaceAll('<br>', '\n')
            .replaceAll('<br/>', '\n')
            .replaceAll('<br />', '\n')
            .trim();
      }

      if (v == null) return {};

      if (v is Map) {
        return v.map((k, val) => MapEntry(
              _clean('$k'),
              _clean('$val'),
            ));
      }

      if (v is String && v.trim().isNotEmpty) {
        try {
          final d = json.decode(v);
          if (d is Map) {
            return d.map((k, val) => MapEntry(
                  _clean('$k'),
                  _clean('$val'),
                ));
          }
        } catch (_) {}
      }

      return {};
    }

    return CourseLandingData(
      id: _toInt(m['id']),
      title: '${m['title'] ?? ''}'.trim(),
      categoryName: '${m['course_category_name'] ?? ''}'.trim(),
      shortdescription: '${m['short_description'] ?? ''}'.trim(),
      thumbnail: '${m['thumbnail'] ?? ''}'.trim(),
      heroimg: '${m['hero_image'] ?? ''}'.trim(),
      infotitle: '${m['info_title'] ?? ''}'.trim(),
      price: '${m['price'] ?? ''}'.trim(),
      languages: '${m['language'] ?? ''}'.trim(),
      courseduration: '${m['course_duration'] ?? ''}'.trim(),
      rating: _toDouble(m['rating']),
      numberOfRatings: _toInt(m['number_of_ratings']),
      totalEnrollment: _toInt(m['total_enrollment']),
      totalEnrollmentfake: _toInt(m['total_enrollment_fake']),
      certificateUrl: '${m['course_certificate'] ?? ''}',
      isPurchased: _toBool(m['is_purchased']),
      isFreeCourse: _toBool(m['is_free_course']),
      webLink: '${m['web_link'] ?? ''}'.trim(),
      reviewFaces: faces,
      testimonials: testi,
      sections: secs,
      outcomes: outs,
      whatyouwillbelearn: whatUwillearn,
      learnwithgreylearn: learnwthgrey,
      faqs: _parseFaqs(m['faqs']),
    );
  }

  static List<CourseLandingData> listFromResponse(String body) {
    final data = json.decode(body);
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map((m) => CourseLandingData.fromApiJson(m)).toList();
  }
}

class Testimonial {
  final String userImage;
  final String name;
  final double rating;
  final String content;

  Testimonial({
    required this.userImage,
    required this.name,
    required this.rating,
    required this.content,
  });

  factory Testimonial.fromJson(Map<String, dynamic> m) {
    double _toDouble(dynamic v) => double.tryParse('$v') ?? 0.0;
    return Testimonial(
      userImage: '${m['user_image'] ?? ''}',
      name: '${m['name'] ?? ''}',
      rating: _toDouble(m['rating']),
      content: '${m['rating_content'] ?? ''}',
    );
  }
}

class LandingSection {
  final int id;
  final String title;
  final int lessons; // derive from lessons list length
  final int
      minutes; // derive from total_duration if present "HH:MM:SS" -> minutes
  final List<LandingLesson> items;

  LandingSection({
    required this.id,
    required this.title,
    required this.lessons,
    required this.minutes,
    required this.items,
  });

  factory LandingSection.fromJson(Map<String, dynamic> m) {
    int _toInt(dynamic v) => int.tryParse('$v') ?? 0;

    List<LandingLesson> lessons = [];
    if (m['lessons'] is List) {
      lessons = (m['lessons'] as List<dynamic>)
          .map((e) => LandingLesson.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // total_duration may be "HH:MM:SS" or "MM:SS"
    final totalDuration = '${m['total_duration'] ?? ''}';
    final minutes = _parseMinutes(totalDuration);

    return LandingSection(
      id: _toInt(m['id']),
      title: '${m['title'] ?? ''}',
      lessons: lessons.length,
      minutes: minutes,
      items: lessons,
    );
  }

  static int _parseMinutes(String hhmmss) {
    if (hhmmss.isEmpty) return 0;
    final parts = hhmmss.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 3) {
      return parts[0] * 60 + parts[1] + (parts[2] > 0 ? 1 : 0);
    }
    if (parts.length == 2) {
      return parts[0] + (parts[1] > 0 ? 1 : 0);
    }
    return 0;
  }
}

class LandingLesson {
  final int id;
  final String title;
  final String duration;

  LandingLesson({
    required this.id,
    required this.title,
    required this.duration,
  });

  factory LandingLesson.fromJson(Map<String, dynamic> m) {
    int _toInt(dynamic v) => int.tryParse('$v') ?? 0;
    return LandingLesson(
      id: _toInt(m['id']),
      title: '${m['title'] ?? ''}',
      duration: '${m['duration'] ?? ''}',
    );
  }
}
