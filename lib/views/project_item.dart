import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:project_tracker/models/project.dart';
import 'package:project_tracker/pages/project_page.dart';
import 'package:project_tracker/helper/url.dart';

class ProjectItem extends StatelessWidget {
  final Project item;
  final Function(int itemID) onSwipeTap;

  ProjectItem({required this.item, required this.onSwipeTap});

  Widget build(BuildContext context) {
    return Slidable(
      actions: <Widget>[
        getAction(0, context),
      ],
      secondaryActions: <Widget>[getAction(1, context)],
      child: ListTile(
        title: Text(
          item.name,
          textAlign: TextAlign.center,
        ),
        subtitle: Text(
          item.description,
          textAlign: TextAlign.center,
        ),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProjectPage(project: item)));
        },
      ),
      actionPane: SlidableDrawerActionPane(),
    );
  }

  // 0 = Left, 1 = Right
  IconSlideAction getAction(int side, BuildContext context) {
    IconData icon;
    String caption;
    Color color;
    if (item.location == 1) {
      if (side == 0) {
        icon = Icons.archive;
        caption = 'Archive';
        color = Colors.blueAccent;
      } else {
        icon = Icons.delete;
        caption = 'Trash';
        color = Colors.red;
      }
    } else if (item.location == 2) {
      if (side == 0) {
        icon = Icons.add_to_queue_rounded;
        caption = 'Un-archive';
        color = Colors.blueAccent;
      } else {
        icon = Icons.delete;
        caption = 'Trash';
        color = Colors.red;
      }
    } else if (item.location == 3) {
      if (side == 0) {
        icon = Icons.add_to_queue_rounded;
        caption = 'Un-trash';
        color = Colors.blueAccent;
      } else {
        icon = Icons.archive;
        caption = 'Delete';
        color = Colors.red;
      }
    } else {
      throw ("Got an unexpected location: " + item.location.toString() + "!");
    }
    return IconSlideAction(
      icon: icon,
      caption: caption,
      color: color,
      onTap: () => getOnTap(side, context),
    );
  }

  getOnTap(int side, BuildContext context) {
    if (item.location == 1) {
      if (side == 0) {
        updateProjectLocation(2);
      } else {
        updateProjectLocation(3);
      }
    } else if (item.location == 2) {
      if (side == 0) {
        updateProjectLocation(1);
      } else {
        updateProjectLocation(3);
      }
    } else if (item.location == 3) {
      if (side == 0) {
        updateProjectLocation(1);
      } else {
        deleteTaskAlert(context);
      }
    } else {
      throw ("Got an unexpected location: " + item.location.toString() + "!");
    }
  }

  updateProjectLocation(int newLocation) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;

    final response = await http.patch(
      Uri.http(url, '/projectmemberships/' + item.membership.toString() + '/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      body: {"location": newLocation.toString()},
    );

    if (response.statusCode == 200) {
      onSwipeTap(item.id);
    } else {
      // TODO Display error alert
      print(response.statusCode);
    }
  }

  deleteProject() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    final response = await http.delete(
      Uri.http(url, '/projectmemberships/' + item.membership.toString() + '/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
    );
    if (response.statusCode == 204) {
      onSwipeTap(item.id);
    } else {
      // TODO Display error alert
      print(response.statusCode);
    }
  }

  deleteTaskAlert(BuildContext context) {
    // Set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget continueButton = TextButton(
      child: Text("Delete"),
      onPressed: () {
        deleteProject();
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Are you sure you want to delete this project?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
