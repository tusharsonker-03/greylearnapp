/* 
// Example Usage
Map<String, dynamic> map = jsonDecode(<myJSONString>);
var myRootNode = Root.fromJson(map);
*/
class Root {
  String? id;
  String? name;
  String? isdeleted;
  String? status;
  String? countryid;
  String? createdon;
  String? createdby;
  String? updatedon;
  String? updatedby;

  Root({this.id, this.name, this.isdeleted, this.status, this.countryid, this.createdon, this.createdby, this.updatedon, this.updatedby});

  Root.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isdeleted = json['is_deleted'];
    status = json['status'];
    countryid = json['country_id'];
    createdon = json['created_on'];
    createdby = json['created_by'];
    updatedon = json['updated_on'];
    updatedby = json['updated_by'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = id;
    data['name'] = name;
    data['is_deleted'] = isdeleted;
    data['status'] = status;
    data['country_id'] = countryid;
    data['created_on'] = createdon;
    data['created_by'] = createdby;
    data['updated_on'] = updatedon;
    data['updated_by'] = updatedby;
    return data;
  }
}

