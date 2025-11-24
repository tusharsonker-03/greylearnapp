import 'package:flutter/cupertino.dart';

class Lesson {
  int? id;
  String? title;
  String? duration;
  String? videoUrl;
  String? lessonType;
  String? isFree;
  String? summary;
  String? attachmentType;
  String? attachment;
  String? attachmentUrl;
  String? isCompleted;
  String? videoUrlWeb;
  String? videoTypeWeb;
  String? vimeoVideoId;

  Lesson({
    @required this.id,
    @required this.title,
    @required this.duration,
    @required this.lessonType,
    this.isFree,
    this.videoUrl,
    this.summary,
    this.attachmentType,
    this.attachment,
    this.attachmentUrl,
    this.isCompleted,
    this.videoUrlWeb,
    this.videoTypeWeb,
    this.vimeoVideoId,
  });

  @override
  String toString() {
    return 'Lesson{id: $id, title: $title, duration: $duration, videoUrl: $videoUrl, lessonType: $lessonType, isFree: $isFree, summary: $summary, attachmentType: $attachmentType, attachment: $attachment, attachmentUrl: $attachmentUrl, isCompleted: $isCompleted, videoUrlWeb: $videoUrlWeb, videoTypeWeb: $videoTypeWeb, vimeoVideoId: $vimeoVideoId}';
  }
}

