class Task {
  int id;
  int project;
  String owner;
  String name;
  String description;
  int category;
  int priority;
  int status;

  Task(
      {required this.id,
      required this.project,
      required this.owner,
      required this.name,
      required this.description,
      required this.category,
      required this.priority,
      required this.status});

  toJson() {
    return {
      "id": id,
      "owner": owner,
      "project": project,
      "name": name,
      "description": description,
      "category": category,
      "priority": priority,
      "status": status,
    };
  }

  factory Task.fromJson(Map json) {
    return Task(
        id: json['id'],
        project: json['project'],
        owner: json['owner'],
        name: json['name'],
        description: json['description'],
        category: json['category'],
        priority: json['priority'],
        status: json['status']);
  }

  copyWith({required Task task}) {
    this.id = task.id;
    this.project = task.project;
    this.owner = task.owner;
    this.name = task.name;
    this.description = task.description;
    this.category = task.category;
    this.priority = task.priority;
    this.status = task.status;
  }
}
