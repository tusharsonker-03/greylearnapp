/*
// Example Usage
Map<String, dynamic> map = jsonDecode(<myJSONString>);
var myRootNode = Root.fromJson(map);
*/
class Country {
  String? id;
  String? sortname;
  String? name;
  String? phonecode;
  String? isdeleted;
  String? status;
  String? createdon;
  String? updatedon;
  String? createdby;
  String? updatedby;

  Country({this.id, this.sortname, this.name, this.phonecode, this.isdeleted, this.status, this.createdon, this.updatedon, this.createdby, this.updatedby});

  Country.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sortname = json['sortname'];
    name = json['name'];
    phonecode = json['phonecode'];
    isdeleted = json['is_deleted'];
    status = json['status'];
    createdon = json['created_on'];
    updatedon = json['updated_on'];
    createdby = json['created_by'];
    updatedby = json['updated_by'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = id;
    data['sortname'] = sortname;
    data['name'] = name;
    data['phonecode'] = phonecode;
    data['is_deleted'] = isdeleted;
    data['status'] = status;
    data['created_on'] = createdon;
    data['updated_on'] = updatedon;
    data['created_by'] = createdby;
    data['updated_by'] = updatedby;
    return data;
  }

  @override
  String toString() {
    return 'Country{id: $id, sortname: $sortname, name: $name, phonecode: $phonecode, isdeleted: $isdeleted, status: $status, createdon: $createdon, updatedon: $updatedon, createdby: $createdby, updatedby: $updatedby}';
  }
}

