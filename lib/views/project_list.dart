import 'package:flutter/material.dart';
import 'package:project_tracker/models/project.dart';
import 'project_item.dart';

class ProjectList extends StatelessWidget {
  final List<Project> items;
  final Function(int itemID) onSwipeTap;
  final Function hasMore;
  final ScrollController controller;

  ProjectList(
      {required this.items,
      required this.onSwipeTap,
      required this.hasMore,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return hasMore();
        } else {
          return ProjectItem(
            item: items[index],
            onSwipeTap: onSwipeTap,
          );
        }
      },
    );
  }
}
