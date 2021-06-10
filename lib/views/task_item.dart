import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

import 'package:project_tracker/models/task.dart';
import 'package:project_tracker/helper/url.dart';

class TaskItem extends StatelessWidget {
  final Task item;
  final Function(Task task, int initialStatus) onUpdate;
  final int permissionLevel;
  final Function insufficientPermissionsAlert;

  TaskItem({
    required this.item,
    required this.onUpdate,
    required this.permissionLevel,
    required this.insufficientPermissionsAlert,
  });

  Widget build(BuildContext context) {
    return Card(
      color: colorPriority(item.priority),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {
            if (permissionLevel < 3) {
              taskAlert(context);
            } else {
              insufficientPermissionsAlert();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.black),
              Text(
                item.description,
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
                textAlign: TextAlign.center,
              ),
              Spacer(flex: 5),
              Text(
                categoryToString(item.category),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Set sticky color based on priority int value
  Color colorPriority(int priority) {
    Color toReturn = Colors.indigo;
    switch (priority) {
      case 2:
        toReturn = Colors.green;
        break;
      case 3:
        toReturn = Colors.yellow;
        break;
      case 4:
        toReturn = Colors.red;
        break;
    }
    return toReturn;
  }

  //Generate Buttons based on Task List
  List<String> getButtons() {
    List<String> toReturn = [];

    switch (item.status) {
      case 1:
        toReturn.add('ongoing');
        toReturn.add('testing');
        toReturn.add('complete');
        break;
      case 2:
        toReturn.add('backlog');
        toReturn.add('testing');
        toReturn.add('complete');
        break;
      case 3:
        toReturn.add('backlog');
        toReturn.add('ongoing');
        toReturn.add('complete');
        break;
      case 4:
        toReturn.add('backlog');
        toReturn.add('ongoing');
        toReturn.add('testing');
        break;
    }
    toReturn.add('delete');

    return toReturn;
  }

  // 0 = Category, 1 = Priority, 2 = Status
  Widget getHint(int field) {
    String hint = '';
    if (field == 0) {
      if (item.category == 1) {
        hint = 'Task';
      } else if (item.category == 2) {
        hint = 'Feature';
      } else if (item.category == 3) {
        hint = 'Bug';
      } else if (item.category == 4) {
        hint = 'Other';
      }
    } else if (field == 1) {
      if (item.priority == 1) {
        hint = 'Wishlist';
      } else if (item.priority == 2) {
        hint = 'Low';
      } else if (item.priority == 3) {
        hint = 'Medium';
      } else if (item.priority == 4) {
        hint = 'High';
      }
    } else if (field == 2) {
      if (item.status == 1) {
        hint = 'Backlog';
      } else if (item.status == 2) {
        hint = 'In Progress';
      } else if (item.status == 3) {
        hint = 'Testing';
      } else if (item.status == 4) {
        hint = 'Completed';
      }
    }
    return Text(hint);
  }

  // 0 = Category, 1 = Priority, 2 = Status
  List<DropdownMenuItem<int>> getItems(int field) {
    List<DropdownMenuItem<int>> items = [];
    if (field == 0) {
      if (item.category != 1) {
        items.add(DropdownMenuItem<int>(child: Text('Task'), value: 1));
      }
      if (item.category != 2) {
        items.add(DropdownMenuItem<int>(child: Text('Feature'), value: 2));
      }
      if (item.category != 3) {
        items.add(DropdownMenuItem<int>(child: Text('Bug'), value: 3));
      }
      if (item.category != 4) {
        items.add(DropdownMenuItem<int>(child: Text('Other'), value: 4));
      }
    } else if (field == 1) {
      if (item.priority != 1) {
        items.add(DropdownMenuItem<int>(child: Text('Wishlist'), value: 1));
      }
      if (item.priority != 2) {
        items.add(DropdownMenuItem<int>(child: Text('Low'), value: 2));
      }
      if (item.priority != 3) {
        items.add(DropdownMenuItem<int>(child: Text('Medium'), value: 3));
      }
      if (item.priority != 4) {
        items.add(DropdownMenuItem<int>(child: Text('High'), value: 4));
      }
    } else if (field == 2) {
      if (item.status != 1) {
        items.add(DropdownMenuItem<int>(child: Text('Backlog'), value: 1));
      }
      if (item.status != 2) {
        items.add(DropdownMenuItem<int>(child: Text('In Progress'), value: 2));
      }
      if (item.status != 3) {
        items.add(DropdownMenuItem<int>(child: Text('Testing'), value: 3));
      }
      if (item.status != 4) {
        items.add(DropdownMenuItem<int>(child: Text('Completed'), value: 4));
      }
    }
    return items;
  }

  // Edit Sticky Details when clicked
  taskAlert(BuildContext context) {
    // Key used to reference the form.
    final _formKey = GlobalKey<FormState>();
    String _description = '', _name = '';
    int _owner = 1,
        _category = item.category,
        _priority = item.priority,
        _status = item.status;
    bool _btnEnabled = false;

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget continueButton = TextButton(
      child: Text("Submit"),
      onPressed: () {
        if (_btnEnabled) {
          _formKey.currentState!.save();
          updateTask(
              _description, _name, _owner, _category, _priority, _status);
          Navigator.pop(context);
        }
      },
    );

    Widget deleteButton = TextButton(
      child: Text(
        "Delete",
      ),
      onPressed: () {
        deleteTask();
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Task:"),
      content: Form(
        key: _formKey,
        onChanged: () => _btnEnabled = _formKey.currentState!.validate(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Task Title TextField
            Container(
              child: TextFormField(
                initialValue: item.owner,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                validator: (input) {
                  if (input!.isEmpty) {
                    return 'Provide an owner';
                  }
                },
                onSaved: (input) => {},
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black87),
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding: EdgeInsets.all(15),
                  filled: true,
                  fillColor: Colors.black87,
                  focusColor: Colors.black87,
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
            ),
            // Task Name TextField
            Container(
              child: TextFormField(
                initialValue: item.name,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                validator: (input) {
                  if (input!.isEmpty) {
                    return 'Provide a Task Name';
                  }
                },
                onSaved: (input) => _name = input!,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black87),
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding: EdgeInsets.all(15),
                  filled: true,
                  fillColor: Colors.black87,
                  focusColor: Colors.black87,
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            // Task Description TextField
            Container(
              child: TextFormField(
                initialValue: item.description,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                validator: (input) {
                  if (input!.isEmpty) {
                    return 'Provide a Task Description';
                  }
                },
                onSaved: (input) => _description = input!,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black87),
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding: EdgeInsets.all(15),
                  filled: true,
                  fillColor: Colors.black87,
                  focusColor: Colors.black87,
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            Container(
              child: DropdownButtonFormField<int>(
                hint: getHint(0),
                items: getItems(0),
                onChanged: (value) {
                  _category = value!;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            Container(
              child: DropdownButtonFormField<int>(
                hint: getHint(1),
                items: getItems(1),
                onChanged: (value) {
                  _priority = value!;
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            Container(
              child: DropdownButtonFormField<int>(
                hint: getHint(2),
                items: getItems(2),
                onChanged: (value) {
                  _status = value!;
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
        deleteButton,
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

  updateTask(String description, String name, int owner, int category,
      int priority, int status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    //Update
    final response = await http.patch(
      Uri.http(url, '/tasks/' + item.id.toString() + '/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      body: {
        "owner": item.owner.toString(),
        "name": name,
        'description': description,
        'category': category.toString(),
        'priority': priority.toString(),
        'status': status.toString()
      },
    );
    if (response.statusCode == 200) {
      Task task = Task.fromJson(json.decode(response.body));
      onUpdate(task, item.status);
    } else {
      print(response.statusCode);
    }
  }

  deleteTask() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token')!;
    final response = await http.delete(
      Uri.http(url, '/tasks/' + item.id.toString() + '/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
    );
    if (response.statusCode == 204) {
      onUpdate(item, 0);
    } else {
      print(response.statusCode);
    }
  }

  String categoryToString(int category) {
    String cat = '';
    if (category == 1) {
      cat = 'Task';
    } else if (category == 2) {
      cat = 'Feature';
    } else if (category == 3) {
      cat = 'Bugfix';
    } else if (category == 4) {
      cat = 'Other';
    }
    return cat;
  }
}
