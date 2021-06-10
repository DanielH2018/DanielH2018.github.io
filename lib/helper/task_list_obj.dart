import 'package:flutter/cupertino.dart';
import 'package:project_tracker/models/task.dart';

class TaskListObj {
  int status;
  List<Task> tasks;
  final Function(int status) fetchTasks;
  int page = 1;
  late ScrollController controller;

  TaskListObj(
      {required this.status, required this.tasks, required this.fetchTasks});

  void taskScrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      fetchTasks(status);
    }
  }
}
