class Notifications {
  String id = '';
  String title = '';
  String description = '';
  String createdAt = '';
  String redirectType = '';
  String redirectSection = '';
  String redirectIdOrUrl = '';
  String authentication = '';

  Notifications({required this.id, required this.title, required this.description, required this.createdAt,required this.redirectType,required this.redirectSection, required this.redirectIdOrUrl, required this.authentication});

  Notifications.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    createdAt = json['created_at'];
    redirectType = json['redirect_type'];
    redirectSection = json['redirect_section'];
    redirectIdOrUrl = json['redirect_id_or_url'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['created_at'] = this.createdAt;
    data['redirect_type'] = this.redirectType;
    data['redirect_section'] = this.redirectSection;
    data['redirect_id_or_url'] = this.redirectIdOrUrl;
    data['authentication'] = this.authentication;
    return data;
  }
}








