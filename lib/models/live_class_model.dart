// ignore_for_file: unnecessary_this, unnecessary_new

class LiveClassModel {
  ZoomLiveClassDetails? zoomLiveClassDetails;
  ZoomLiveClass? zoomLiveClass;
  String? meetingInviteLink;

  LiveClassModel({this.zoomLiveClassDetails, this.zoomLiveClass, this.meetingInviteLink});

  LiveClassModel.fromJson(Map<String, dynamic> json) {
    zoomLiveClassDetails = json['zoom_live_class_details'] != null
        ? ZoomLiveClassDetails.fromJson(json['zoom_live_class_details'])
        : null;
 zoomLiveClass = json['zoom_live_class'] != null
        ? new ZoomLiveClass.fromJson(json['zoom_live_class'])
        : null;
    meetingInviteLink = json['meeting_invite_link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (zoomLiveClassDetails != null) {
      data['zoom_live_class_details'] = zoomLiveClassDetails!.toJson();
    }
      if (this.zoomLiveClass != null) {
      data['zoom_live_class'] = this.zoomLiveClass!.toJson();
    }
    data['meeting_invite_link'] = meetingInviteLink;
    return data;
  }
}

class ZoomLiveClassDetails {
  String? id;
  String? courseId;
  String? date;
  String? time;
  String? zoomMeetingId;
  String? zoomMeetingPassword;
  String? noteToStudents;
  String? meetingInviteLink;

  ZoomLiveClassDetails(
      {this.id,
      this.courseId,
      this.date,
      this.time,
      this.zoomMeetingId,
      this.zoomMeetingPassword,
      this.noteToStudents,
      this.meetingInviteLink});

  ZoomLiveClassDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    courseId = json['course_id'];
    date = json['date'];
    time = json['time'];
    zoomMeetingId = json['zoom_meeting_id'];
    zoomMeetingPassword = json['zoom_meeting_password'];
    noteToStudents = json['note_to_students'];
    meetingInviteLink = json['meeting_invite_link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['course_id'] = courseId;
    data['date'] = date;
    data['time'] = time;
    data['zoom_meeting_id'] = zoomMeetingId;
    data['zoom_meeting_password'] = zoomMeetingPassword;
    data['note_to_students'] = noteToStudents;
    data['meeting_invite_link'] = meetingInviteLink;
    return data;
  }
}
class ZoomLiveClass {
  String? id;
  String? userId;
  String? clientId;
  String? clientSecret;
  String? createdAt;
  String? updatedAt;

  ZoomLiveClass(
      {this.id,
      this.userId,
      this.clientId,
      this.clientSecret,
      this.createdAt,
      this.updatedAt});

  ZoomLiveClass.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    clientId = json['client_id'];
    clientSecret = json['client_secret'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['client_id'] = this.clientId;
    data['client_secret'] = this.clientSecret;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
