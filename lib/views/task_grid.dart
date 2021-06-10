import 'package:flutter/material.dart';
import 'package:project_tracker/models/task.dart';
import 'task_item.dart';

class TaskGrid extends StatelessWidget {
  final List<Task> items;
  final Function(Task task, int initialStatus) onUpdate;
  final Function hasMore;
  final ScrollController controller;
  final int status;
  final int permissionLevel;
  final Function insufficientPermissionsAlert;

  TaskGrid({
    required this.items,
    required this.onUpdate,
    required this.hasMore,
    required this.controller,
    required this.status,
    required this.permissionLevel,
    required this.insufficientPermissionsAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: GridView.builder(
        controller: controller,
        itemCount: items.length + 1,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200.0,
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 10.0,
        ),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return hasMore(status);
          } else {
            return TaskItem(
              item: items[index],
              onUpdate: onUpdate,
              permissionLevel: permissionLevel,
              insufficientPermissionsAlert: insufficientPermissionsAlert,
            );
          }
        },
      ),
    );
  }
}
