/*
// Example Usage
Map<String, dynamic> map = jsonDecode(<myJSONString>);
var myRootNode = Root.fromJson(map);
*/
// class ConfigData {
//   String? appname;
//   String? tagline;
//   int? version;
//   String? whatsnew;
//   String? releasedate;
//   String? dynamicapiurl;
//   String? careernavigatorlink;
//   String? msglink;
//   String? hotsticker;
//   String? hotstickerlinktype;
//   String? hotstickerlink;
//   Subscription? subscription;
//   ProfileUpdate? profileupdate;
//   Home? home;
//   List<UserProfileField?>? userprofilefields;
//
//   ConfigData({this.appname, this.tagline, this.version, this.whatsnew, this.releasedate, this.dynamicapiurl, this.careernavigatorlink, this.msglink, this.hotsticker, this.hotstickerlinktype, this.hotstickerlink, this.subscription, this.profileupdate, this.home, this.userprofilefields});
//
//   ConfigData.fromJson(Map<String, dynamic> json) {
//     appname = json['appname'];
//     tagline = json['tagline'];
//     version = json['version'];
//     whatsnew = json['whatsnew'];
//     releasedate = json['releasedate'];
//     dynamicapiurl = json['dynamicapiurl'];
//     careernavigatorlink = json['career_navigator_link'];
//     msglink = json['msglink'];
//     hotsticker = json['hotsticker'];
//     hotstickerlinktype = json['hotstickerlinktype'];
//     hotstickerlink = json['hotstickerlink'];
//     subscription = json['subscription'] != null ? Subscription?.fromJson(json['subscription']) : null;
//     profileupdate = json['profileupdate'] != null ? ProfileUpdate?.fromJson(json['profileupdate']) : null;
//     home = json['home'] != null ? Home?.fromJson(json['home']) : null;
//     if (json['user_profile_fields'] != null) {
//       userprofilefields = <UserProfileField>[];
//       json['user_profile_fields'].forEach((v) {
//         userprofilefields!.add(UserProfileField.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['appname'] = appname;
//     data['tagline'] = tagline;
//     data['version'] = version;
//     data['whatsnew'] = whatsnew;
//     data['releasedate'] = releasedate;
//     data['dynamicapiurl'] = dynamicapiurl;
//     data['career_navigator_link'] = careernavigatorlink;
//     data['msglink'] = msglink;
//     data['hotsticker'] = hotsticker;
//     data['hotstickerlinktype'] = hotstickerlinktype;
//     data['hotstickerlink'] = hotstickerlink;
//     data['subscription'] = subscription!.toJson();
//     data['profileupdate'] = profileupdate!.toJson();
//     data['home'] = home!.toJson();
//     data['user_profile_fields'] = userprofilefields?.map((v) => v?.toJson()).toList();
//     return data;
//   }
// }
// class Home {
//   Banner1? banner1;
//   Banner2? banner2;
//   Banner3? banner3;
//   Banner4? banner4;
//
//   Home({this.banner1, this.banner2, this.banner3, this.banner4});
//
//   Home.fromJson(Map<String, dynamic> json) {
//     banner1 = json['banner1'] != null ? Banner1?.fromJson(json['banner1']) : null;
//     banner2 = json['banner2'] != null ? Banner2?.fromJson(json['banner2']) : null;
//     banner3 = json['banner3'] != null ? Banner3?.fromJson(json['banner3']) : null;
//     banner4 = json['banner4'] != null ? Banner4?.fromJson(json['banner4']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['banner1'] = banner1!.toJson();
//     data['banner2'] = banner2!.toJson();
//     data['banner3'] = banner3!.toJson();
//     data['banner4'] = banner4!.toJson();
//     return data;
//   }
// }
//
// class Option {
//   String? label;
//   String? value;
//
//   Option({this.label, this.value});
//
//   Option.fromJson(Map<String, dynamic> json) {
//     label = json['label'];
//     value = json['value'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['label'] = label;
//     data['value'] = value;
//     return data;
//   }
// }
//
// class ProfileUpdate {
//   bool? forceall;
//   bool? forcefreecourse;
//   bool? forcecareernavigator;
//
//   ProfileUpdate({this.forceall, this.forcefreecourse, this.forcecareernavigator});
//
//   ProfileUpdate.fromJson(Map<String, dynamic> json) {
//     forceall = json['forceall'];
//     forcefreecourse = json['forcefreecourse'];
//     forcecareernavigator = json['forcecareernavigator'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['forceall'] = forceall;
//     data['forcefreecourse'] = forcefreecourse;
//     data['forcecareernavigator'] = forcecareernavigator;
//     return data;
//   }
// }
// class Banner1 {
//   String? image;
//   String? linktype;
//   String? link;
//
//   Banner1({this.image, this.linktype, this.link});
//
//   Banner1.fromJson(Map<String, dynamic> json) {
//     image = json['image'];
//     linktype = json['linktype'];
//     link = json['link'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['image'] = image;
//     data['linktype'] = linktype;
//     data['link'] = link;
//     return data;
//   }
// }
//
// class Banner2 {
//   String? image;
//   String? linktype;
//   String? link;
//
//   Banner2({this.image, this.linktype, this.link});
//
//   Banner2.fromJson(Map<String, dynamic> json) {
//     image = json['image'];
//     linktype = json['linktype'];
//     link = json['link'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['image'] = image;
//     data['linktype'] = linktype;
//     data['link'] = link;
//     return data;
//   }
// }
//
// class Banner3 {
//   String? image;
//   String? linktype;
//   String? link;
//
//   Banner3({this.image, this.linktype, this.link});
//
//   Banner3.fromJson(Map<String, dynamic> json) {
//     image = json['image'];
//     linktype = json['linktype'];
//     link = json['link'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['image'] = image;
//     data['linktype'] = linktype;
//     data['link'] = link;
//     return data;
//   }
// }
//
// class Banner4 {
//   String? image;
//   String? linktype;
//   String? link;
//
//   Banner4({this.image, this.linktype, this.link});
//
//   Banner4.fromJson(Map<String, dynamic> json) {
//     image = json['image'];
//     linktype = json['linktype'];
//     link = json['link'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['image'] = image;
//     data['linktype'] = linktype;
//     data['link'] = link;
//     return data;
//   }
// }
//
// class Subscription {
//   bool? popup;
//   String? popupimage;
//   String? popupcontent;
//   String? popupbutton;
//   String? popuplink;
//   String? price;
//   String? discountedprice;
//   String? duration;
//
//   Subscription({this.popup, this.popupimage, this.popupcontent, this.popupbutton, this.popuplink, this.price, this.discountedprice, this.duration});
//
//   Subscription.fromJson(Map<String, dynamic> json) {
//     popup = json['popup'];
//     popupimage = json['popupimage'];
//     popupcontent = json['popupcontent'];
//     popupbutton = json['popupbutton'];
//     popuplink = json['popuplink'];
//     price = json['price'];
//     discountedprice = json['discounted_price'];
//     duration = json['duration'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['popup'] = popup;
//     data['popupimage'] = popupimage;
//     data['popupcontent'] = popupcontent;
//     data['popupbutton'] = popupbutton;
//     data['popuplink'] = popuplink;
//     data['price'] = price;
//     data['discounted_price'] = discountedprice;
//     data['duration'] = duration;
//     return data;
//   }
// }
//
// class UserProfileField {
//   String? academictype;
//   String? fieldname;
//   String? fieldlabel;
//   String? type;
//   bool? require;
//   List<Option?>? options;
//   String? value;
//
//   UserProfileField({this.academictype, this.fieldname, this.fieldlabel, this.type, this.require, this.options, this.value});
//
//   UserProfileField.fromJson(Map<String, dynamic> json) {
//     academictype = json['academic_type'];
//     fieldname = json['field_name'];
//     fieldlabel = json['field_label'];
//     type = json['type'];
//     require = json['require'];
//     if (json['options'] != null) {
//       options = <Option>[];
//       json['options'].forEach((v) {
//         options!.add(Option.fromJson(v));
//       });
//     }
//     value = json['value'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = Map<String, dynamic>();
//     data['academic_type'] = academictype;
//     data['field_name'] = fieldname;
//     data['field_label'] = fieldlabel;
//     data['type'] = type;
//     data['require'] = require;
//     data['options'] =options?.map((v) => v?.toJson()).toList();
//     data['value'] = value;
//     return data;
//   }
// }

/*
// Example Usage
Map<String, dynamic> map = jsonDecode(<myJSONString>);
var myRootNode = Root.fromJson(map);
*/


import 'dart:ffi';

class Banner1 {
  String? image;
  String? linktype;
  String? link;
  bool? authentication;

  Banner1({this.image, this.linktype, this.link, this.authentication});

  Banner1.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    linktype = json['linktype'];
    link = json['link'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['image'] = image;
    data['linktype'] = linktype;
    data['link'] = link;
    data['authentication'] = authentication;
    return data;
  }
}

class Banner2 {
  String? image;
  String? linktype;
  String? link;
  bool? authentication;

  Banner2({this.image, this.linktype, this.link, this.authentication});

  Banner2.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    linktype = json['linktype'];
    link = json['link'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['image'] = image;
    data['linktype'] = linktype;
    data['link'] = link;
    data['authentication'] = authentication;
    return data;
  }
}

class Banner3 {
  String? image;
  String? linktype;
  String? link;
  bool? authentication;

  Banner3({this.image, this.linktype, this.link, this.authentication});

  Banner3.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    linktype = json['linktype'];
    link = json['link'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['image'] = image;
    data['linktype'] = linktype;
    data['link'] = link;
    data['authentication'] = authentication;
    return data;
  }
}

class Banner4 {
  String? image;
  String? linktype;
  String? link;
  bool? authentication;

  Banner4({this.image, this.linktype, this.link, this.authentication});

  Banner4.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    linktype = json['linktype'];
    link = json['link'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['image'] = image;
    data['linktype'] = linktype;
    data['link'] = link;
    data['authentication'] = authentication;
    return data;
  }
}

class Home {
  Banner1? banner1;
  Banner2? banner2;
  Banner3? banner3;
  Banner4? banner4;

  Home({this.banner1, this.banner2, this.banner3, this.banner4});

  Home.fromJson(Map<String, dynamic> json) {
    banner1 =
        json['banner1'] != null ? Banner1?.fromJson(json['banner1']) : null;
    banner2 =
        json['banner2'] != null ? Banner2?.fromJson(json['banner2']) : null;
    banner3 =
        json['banner3'] != null ? Banner3?.fromJson(json['banner3']) : null;
    banner4 =
        json['banner4'] != null ? Banner4?.fromJson(json['banner4']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['banner1'] = banner1!.toJson();
    data['banner2'] = banner2!.toJson();
    data['banner3'] = banner3!.toJson();
    data['banner4'] = banner4!.toJson();
    return data;
  }
}

class Option {
  String? label;
  String? value;

  Option({this.label, this.value});

  Option.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['label'] = label;
    data['value'] = value;
    return data;
  }

  @override
  String toString() {
    return 'Option{label: $label, value: $value}';
  }
}

class ProfileBanner {
  String? image;
  String? linktype;
  bool? authentication;

  ProfileBanner({this.image, this.linktype, this.authentication});

  ProfileBanner.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    linktype = json['linktype'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['image'] = image;
    data['linktype'] = linktype;
    data['authentication'] = authentication;
    return data;
  }
}

class Profileupdate {
  bool? forceall;
  bool? forcefreecourse;
  bool? forcecareernavigator;

  Profileupdate(
      {this.forceall, this.forcefreecourse, this.forcecareernavigator});

  Profileupdate.fromJson(Map<String, dynamic> json) {
    forceall = json['forceall'];
    forcefreecourse = json['forcefreecourse'];
    forcecareernavigator = json['forcecareernavigator'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['forceall'] = forceall;
    data['forcefreecourse'] = forcefreecourse;
    data['forcecareernavigator'] = forcecareernavigator;
    return data;
  }
}

class Jobs {
  String? link;
  bool? authentication;

  Jobs({this.link, this.authentication});

  Jobs.fromJson(Map<String, dynamic> json) {
    link = json['link'];
    authentication = json['authentication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['link'] = this.link;
    data['authentication'] = this.authentication;
    return data;
  }
}

class ConfigData {
  String? appname;
  String? tagline;
  String? version;
  String? android_version;
  String? ios_version;
  String? whatsnew;
  String? releasedate;
  String? dynamicapiurl;
  // String? careernavigatorlink;
  String? msglink;
  String? hotsticker;
  String? hotstickerlinktype;
  String? hotstickerlink;
  bool? hotstickerauthentication;
  Subscription? subscription;
  Profileupdate? profileupdate;
  Home? home;
  Jobs? jobs;
  bool? underMaintenance;
  String? underMaintenanceMessage;
  ProfileBanner? profilebanner;
  List<UserProfileField?>? userprofilefields;

  // ConfigData({this.appname, this.tagline, this.version, this.whatsnew, this.releasedate, this.dynamicapiurl, this.careernavigatorlink, this.msglink, this.hotsticker, this.hotstickerlinktype, this.hotstickerlink, this.hotstickerauthentication, this.subscription, this.jobs,this.underMaintenance,this.underMaintenanceMessage,this.profileupdate, this.home, this.profilebanner, this.userprofilefields});
  ConfigData(
      {this.appname,
      this.tagline,
      this.version,
      this.android_version,
      this.ios_version,
      this.whatsnew,
      this.releasedate,
      this.dynamicapiurl,
      this.msglink,
      this.hotsticker,
      this.hotstickerlinktype,
      this.hotstickerlink,
      this.hotstickerauthentication,
      this.subscription,
      this.jobs,
      this.underMaintenance,
      this.underMaintenanceMessage,
      this.profileupdate,
      this.home,
      this.profilebanner,
      this.userprofilefields});

  ConfigData.fromJson(Map<String, dynamic> json) {
    appname = json['appname'];
    tagline = json['tagline'];
    version = json['version']?.toString();
    android_version = json['android_version'];
    ios_version = json['ios_version'];
    whatsnew = json['whatsnew'];
    releasedate = json['releasedate'];
    dynamicapiurl = json['dynamicapiurl'];
    // careernavigatorlink = json['career_navigator_link'];
    msglink = json['msglink'];
    hotsticker = json['hotsticker'];
    hotstickerlinktype = json['hotstickerlinktype'];
    hotstickerlink = json['hotstickerlink'];
    hotstickerauthentication = json['hotsticker_authentication'];
    subscription = json['subscription'] != null
        ? Subscription?.fromJson(json['subscription'])
        : null;
    profileupdate = json['profileupdate'] != null
        ? Profileupdate?.fromJson(json['profileupdate'])
        : null;
    jobs = json['jobs'] != null ? new Jobs.fromJson(json['jobs']) : null;
    underMaintenance = json['under_maintenance'] ?? false;
    underMaintenanceMessage = json['under_maintenance_change_message'];

    home = json['home'] != null ? Home?.fromJson(json['home']) : null;
    profilebanner = json['profile_banner'] != null
        ? ProfileBanner?.fromJson(json['profile_banner'])
        : null;
    if (json['user_profile_fields'] != null) {
      userprofilefields = <UserProfileField>[];
      json['user_profile_fields'].forEach((v) {
        userprofilefields!.add(UserProfileField.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['appname'] = appname;
    data['tagline'] = tagline;
    data['version'] = version;
    data['android_version'] = android_version;
    data['ios_version'] = ios_version;
    data['whatsnew'] = whatsnew;
    data['releasedate'] = releasedate;
    data['dynamicapiurl'] = dynamicapiurl;
    // data['career_navigator_link'] = careernavigatorlink;
    data['msglink'] = msglink;
    data['hotsticker'] = hotsticker;
    data['hotstickerlinktype'] = hotstickerlinktype;
    data['hotstickerlink'] = hotstickerlink;
    data['hotsticker_authentication'] = hotstickerauthentication;
    data['subscription'] = subscription!.toJson();
    data['profileupdate'] = profileupdate!.toJson();
    data['home'] = home!.toJson();
    data['profile_banner'] = profilebanner!.toJson();
    data['jobs'] = jobs!.toJson();
    data['under_maintenance'] = underMaintenance ?? false;
    data['under_maintenance_change_message'] = underMaintenanceMessage;
    data['user_profile_fields'] =
        userprofilefields?.map((v) => v?.toJson()).toList();
    return data;
  }
}

class Subscription {
  bool? popup;
  String? popupimage;
  String? popupcontent;
  String? popupbutton;
  String? popuplink;
  bool? popuplinkauthentication;
  String? price;
  String? discountedprice;
  String? duration;
  String? popupshowduration;
  int? bundleid;

  Subscription(
      {this.popup,
      this.popupimage,
      this.popupcontent,
      this.popupbutton,
      this.popuplink,
      this.popuplinkauthentication,
      this.price,
      this.discountedprice,
      this.duration,
      this.bundleid
      });

  Subscription.fromJson(Map<String, dynamic> json) {
    popup = json['popup'];
    popupimage = json['popupimage'];
    popupcontent = json['popupcontent'];
    popupbutton = json['popupbutton'];
    popuplink = json['popuplink'];
    popuplinkauthentication = json['popuplink_authentication'];
    price = json['price'];
    discountedprice = json['discounted_price'];
    duration = json['duration'];
    popupshowduration = json['popup_show_duration'];
    // 👇 Safe parsing (int ya string dono chalega)
// Subscription.fromJson me
    if (json['bundle_id'] != null) {
      if (json['bundle_id'] is int) {
        bundleid = json['bundle_id'];
      } else if (json['bundle_id'] is String) {
        bundleid = int.tryParse(json['bundle_id']);
      }
    } else {
      bundleid = 0; // default
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['popup'] = popup;
    data['popupimage'] = popupimage;
    data['popupcontent'] = popupcontent;
    data['popupbutton'] = popupbutton;
    data['popuplink'] = popuplink;
    data['popuplink_authentication'] = popuplinkauthentication;
    data['price'] = price;
    data['discounted_price'] = discountedprice;
    data['duration'] = duration;
    data['popup_show_duration'] = popupshowduration;
    data['bundle_id'] = bundleid;
    return data;
  }
}

class UserProfileField {
  String? academictype;
  String? fieldname;
  String? fieldlabel;
  String? type;
  bool? require;
  List<Option?>? options;
  String? value;

  UserProfileField(
      {this.academictype,
      this.fieldname,
      this.fieldlabel,
      this.type,
      this.require,
      this.options,
      this.value});

  UserProfileField.fromJson(Map<String, dynamic> json) {
    academictype = json['academic_type'];
    fieldname = json['field_name'];
    fieldlabel = json['field_label'];
    type = json['type'];
    require = json['require'];
    if (json['options'] != null) {
      options = <Option>[];
      json['options'].forEach((v) {
        options!.add(Option.fromJson(v));
      });
    }
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['academic_type'] = academictype;
    data['field_name'] = fieldname;
    data['field_label'] = fieldlabel;
    data['type'] = type;
    data['require'] = require;
    data['options'] =
        options != null ? options!.map((v) => v?.toJson()).toList() : null;
    data['value'] = value;
    return data;
  }
}
