class ProjectMembership {
  int id;
  int project;
  String owner;
  int permissionLevel;
  int location;

  ProjectMembership(
      {required this.id,
      required this.project,
      required this.owner,
      required this.permissionLevel,
      required this.location});

  toJson() {
    return {
      "id": id,
      "project": project,
      "owner": owner,
      "permissionLevel": permissionLevel,
      "location": location,
    };
  }

  factory ProjectMembership.fromJson(Map json) {
    return ProjectMembership(
        id: json['id'],
        project: json['project'],
        owner: json['owner'],
        permissionLevel: json['permission_level'],
        location: json['location']);
  }
}
