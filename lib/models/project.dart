class Project {
  int id;
  String name;
  String description;
  int location;
  String owner;
  int membership;
  int permissionLevel;

  Project(
      {required this.id,
      required this.name,
      required this.description,
      required this.location,
      required this.owner,
      required this.membership,
      required this.permissionLevel});

  toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "location": location,
      "owner": owner,
      "membership": membership,
      "permissionLevel": permissionLevel,
    };
  }

  factory Project.fromJson(Map json) {
    return Project(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        location: json['location'],
        owner: json['owner'],
        membership: json['membership'],
        permissionLevel: json['permission_level']);
  }
}
