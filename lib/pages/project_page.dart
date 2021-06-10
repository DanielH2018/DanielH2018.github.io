import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:project_tracker/models/project_membership.dart';
import 'package:project_tracker/helper/task_list_obj.dart';
import 'package:project_tracker/widgets/myDrawer.dart';
import 'package:project_tracker/views/task_grid.dart';
import 'package:project_tracker/models/project.dart';
import 'package:project_tracker/models/task.dart';
import 'package:project_tracker/helper/url.dart';

class ProjectPage extends StatefulWidget {
  final Project project;

  ProjectPage({required this.project});
  // This widget is the root of your application.
  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage>
    with TickerProviderStateMixin {
  // Task Objects
  late TabController _tabController;
  List<TaskListObj> taskList = [];
  // Membership Objects
  List<ProjectMembership> membershipList = [];
  late ScrollController membershipController;
  int membershipPage = 1;
  // Task Filter Fields
  var filters = {
    'owner': '',
    'name': '',
    'category': '',
    'priority': '',
  };
  // Auth Token
  String token = '';

  @override
  void initState() {
    for (int i = 1; i < 5; i++) {
      taskList.add(new TaskListObj(
        status: i,
        tasks: [],
        fetchTasks: (int status) => fetchTasks(status),
      ));
      fetchTasks(i);
      taskList[i - 1].controller = new ScrollController()
        ..addListener(taskList[i - 1].taskScrollListener);
    }
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 0,
    )..addListener(() {
        setState(() {});
      });
    membershipController = new ScrollController()..addListener(_scrollListener);
    super.initState();
    fetchMemberships();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        actions: [
          ElevatedButton(
            onPressed: () {
              filterTasksAlert();
            },
            child: Text('Filter'),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.project.permissionLevel < 2) {
                shareProjectAlert();
              } else {
                insufficientPermissionsAlert();
              }
            },
            child: Text('Share'),
          ),
        ],
        centerTitle: true,
        title: Text(widget.project.name),
        backgroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              text: "Backlog",
            ),
            Tab(
              text: "Ongoing",
            ),
            Tab(
              text: "Testing",
            ),
            Tab(
              text: "Complete",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          for (int i = 0; i < taskList.length; i++)
            TaskGrid(
              items: taskList[i].tasks,
              onUpdate: updateTasks,
              controller: taskList[i].controller,
              hasMore: loadingMoreTasks,
              status: i + 1,
              permissionLevel: widget.project.permissionLevel,
              insufficientPermissionsAlert: insufficientPermissionsAlert,
            ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              backgroundColor: Colors.black87,
              child: Icon(Icons.add),
              onPressed: () {
                if (widget.project.permissionLevel < 3) {
                  createTaskAlert();
                } else {
                  insufficientPermissionsAlert();
                }
              },
            )
          : _tabController.index == 3
              ? FloatingActionButton(
                  backgroundColor: Colors.black87,
                  child: Icon(Icons.delete),
                  onPressed: () {
                    if (widget.project.permissionLevel < 3) {
                      clearCompleteAlert();
                    } else {
                      insufficientPermissionsAlert();
                    }
                  },
                )
              : null,
      drawer:
          MyDrawer(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  fetchTasks(int status) async {
    if (token == '') {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token')!;
    }
    final response = await http.get(
      Uri.http(url, '/tasks/', {
        'project': widget.project.id.toString(),
        'owner': filters['owner'],
        'name': filters['name'],
        'category': filters['category'],
        'priority': filters['priority'],
        'status': status.toString()
      }),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
    );
    if (response.statusCode == 200) {
      final parsed = json.decode(response.body)['results'] as List;
      List<Task> tasks =
          List<Task>.from(parsed.map((model) => Task.fromJson(model)));
      setState(() {
        taskList[status - 1].tasks.addAll(tasks);
      });
      final next = json.decode(response.body)['next'];
      if (next == null) {
        taskList[status - 1].page = 0;
        taskList[status - 1]
            .controller
            .removeListener(taskList[status - 1].taskScrollListener);
      } else {
        taskList[status - 1].page++;
      }
    }
  }

  fetchMemberships() async {
    if (token == '') {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token')!;
    }
    final response = await http.get(
      Uri.http(url, '/projectmemberships/', {
        'project': widget.project.id.toString(),
      }),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
    );
    if (response.statusCode == 200) {
      final parsed = json.decode(response.body)['results'] as List;
      List<ProjectMembership> memberships = List<ProjectMembership>.from(
          parsed.map((model) => ProjectMembership.fromJson(model)));
      setState(() {
        membershipList.addAll(memberships);
      });
      final next = json.decode(response.body)['next'];
      if (next == null) {
        membershipPage = 0;
        membershipController.removeListener(_scrollListener);
      } else {
        membershipPage++;
      }
    }
  }

  filterTasksAlert() {
    // Key used to reference the form.
    final _formKey = GlobalKey<FormState>();
    String _owner = filters['owner']!,
        _name = filters['name']!,
        _category = filters['category']!,
        _priority = filters['priority']!;

    List<DropdownMenuItem<int>> categoryItems = [
      DropdownMenuItem(child: Text("Category:"), value: 0)
    ];
    categoryItems.addAll(getItems(0));

    List<DropdownMenuItem<int>> priorityItems = [
      DropdownMenuItem(child: Text("Priority:"), value: 0)
    ];
    priorityItems.addAll(getItems(1));

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
        _formKey.currentState!.save();
        filterTasks(_owner, _name, _category, _priority);
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Filter Tasks:"),
      content: Form(
        key: _formKey,
        onChanged: () => {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Task Owner TextField
            Container(
              child: TextFormField(
                initialValue: _owner != '' ? _owner.toString() : null,
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                validator: (input) {
                  if (input!.isEmpty) {
                    return 'Provide an owner';
                  }
                },
                onSaved: (input) => _owner = input!,
                decoration: InputDecoration(
                  hintText: _owner != '' ? _owner.toString() : "Owner:",
                  hintStyle: TextStyle(color: Colors.white),
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
                initialValue: _name != '' ? _name.toString() : null,
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
                  hintText: _name != '' ? _name.toString() : "Name:",
                  hintStyle: TextStyle(color: Colors.white),
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
            // Task Category Field
            Container(
              child: DropdownButtonFormField<int>(
                hint: Text(_category != '' ? _category.toString() : "Category"),
                value: _category != '' ? int.parse(_category) : 0,
                items: categoryItems,
                onChanged: (value) {
                  if (value == 0) {
                    _category = '';
                  } else {
                    _category = value!.toString();
                  }
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            // Task Priority Field
            Container(
              child: DropdownButtonFormField<int>(
                hint: Text(_priority != '' ? _priority.toString() : "Priority"),
                value: _priority != '' ? int.parse(_priority) : 0,
                items: priorityItems,
                onChanged: (value) {
                  if (value == 0) {
                    _priority = '';
                  } else {
                    _priority = value!.toString();
                  }
                },
              ),
            ),
          ],
        ),
      ),
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

  filterTasks(
      String owner, String name, String category, String priority) async {
    filters['owner'] = owner;
    filters['name'] = name;
    filters['category'] = category;
    filters['priority'] = priority;
    print(priority);

    for (int i = 1; i < 5; i++) {
      setState(() {
        taskList[i - 1].controller.dispose();
        taskList[i - 1] = (new TaskListObj(
          status: i,
          tasks: [],
          fetchTasks: (int status) => fetchTasks(status),
        ));
        fetchTasks(i);
        taskList[i - 1].controller = new ScrollController()
          ..addListener(taskList[i - 1].taskScrollListener);
      });
    }
  }

  // 0 = Category, 1 = Priority, 2 = Status
  List<DropdownMenuItem<int>> getItems(int field) {
    List<DropdownMenuItem<int>> items = [];
    if (field == 0) {
      items.add(DropdownMenuItem<int>(child: Text('Task'), value: 1));
      items.add(DropdownMenuItem<int>(child: Text('Feature'), value: 2));
      items.add(DropdownMenuItem<int>(child: Text('Bug'), value: 3));
      items.add(DropdownMenuItem<int>(child: Text('Other'), value: 4));
    } else if (field == 1) {
      items.add(DropdownMenuItem<int>(child: Text('Wishlist'), value: 1));
      items.add(DropdownMenuItem<int>(child: Text('Low'), value: 2));
      items.add(DropdownMenuItem<int>(child: Text('Medium'), value: 3));
      items.add(DropdownMenuItem<int>(child: Text('High'), value: 4));
    } else if (field == 2) {
      items.add(DropdownMenuItem<int>(child: Text('Backlog'), value: 1));
      items.add(DropdownMenuItem<int>(child: Text('In Progress'), value: 2));
      items.add(DropdownMenuItem<int>(child: Text('Testing'), value: 3));
      items.add(DropdownMenuItem<int>(child: Text('Completed'), value: 4));
    }
    return items;
  }

  void _scrollListener() {
    if (membershipController.offset >=
            membershipController.position.maxScrollExtent &&
        !membershipController.position.outOfRange) {
      fetchMemberships();
    }
  }

  Widget loadingMore() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: membershipPage != 0 ? 1.0 : 0.0,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
  }

  createTaskAlert() {
    // Key used to reference the form.
    final _formKey = GlobalKey<FormState>();
    String _owner = '', _name = '', _description = '';
    int _category = 0, _priority = 0, _status = 0;
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
          createTask(
              _owner, _name, _description, _category, _priority, _status);
          Navigator.pop(context);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("New Task:"),
      content: Form(
        key: _formKey,
        onChanged: () => _btnEnabled = _formKey.currentState!.validate(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Owner TextField
            Container(
              child: TextFormField(
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                validator: (value) => value == '' ? 'Owner required' : null,
                onSaved: (input) => _owner = input!,
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
                    hintStyle: TextStyle(color: Colors.white),
                    hintText: 'Owner'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            // Name TextField
            Container(
              child: TextFormField(
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                validator: (value) => value == '' ? 'Name required' : null,
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
                    hintStyle: TextStyle(color: Colors.white),
                    hintText: 'Name'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            // Description TextField
            Container(
              child: TextFormField(
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
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
                    hintStyle: TextStyle(color: Colors.white),
                    hintText: 'Description'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            // Category Field
            Container(
              child: DropdownButtonFormField<int>(
                hint: Text("Category"),
                items: getItems(0),
                onChanged: (value) {
                  _category = value!;
                },
                validator: (value) =>
                    value == null ? 'Category required' : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            // Priority Field
            Container(
              child: DropdownButtonFormField<int>(
                hint: Text("Priority"),
                items: getItems(1),
                onChanged: (value) {
                  _priority = value!;
                },
                validator: (value) =>
                    value == null ? 'Priority required' : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
            ),
            // Status Field
            Container(
              child: DropdownButtonFormField<int>(
                hint: Text("Status"),
                items: getItems(2),
                onChanged: (value) {
                  _status = value!;
                },
                validator: (value) => value == null ? 'Status required' : null,
              ),
            ),
          ],
        ),
      ),
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

  void createTask(String owner, String name, String description, int category,
      int priority, int status) async {
    // Create Task
    final response = await http.post(
      Uri.http(url, '/tasks/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      body: {
        'project': widget.project.id.toString(),
        'owner': widget.project.owner,
        'name': name,
        'description': description,
        'priority': priority.toString(),
        'category': category.toString(),
        'status': status.toString(),
      },
    );
    if (response.statusCode == 201) {
      Task newTask = Task.fromJson(json.decode(response.body));
      setState(() {
        taskList[status - 1].tasks.add(newTask);
      });
    } else {
      print(response.statusCode);
    }
  }

  clearCompleteAlert() {
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
        clearComplete();
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Are you sure you want to delete all completed tasks?"),
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

  clearComplete() async {
    taskList[3].tasks.forEach((task) async {
      final response = await http.delete(
        Uri.http(url, '/tasks/' + task.id.toString() + '/'),
        headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      );
      if (response.statusCode == 204) {
        setState(() {
          taskList[3].tasks.removeLast();
        });
      } else {
        print(response.statusCode);
      }
    });
  }

  shareProjectAlert() {
    // Key used to reference the form.
    final _formKey = GlobalKey<FormState>();
    String _username = '';
    int _permissionLevel = 3;
    bool _btnEnabled = false;

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Exit"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget continueButton = TextButton(
      child: Text("Share"),
      onPressed: () {
        if (_btnEnabled) {
          _formKey.currentState!.save();
          // TODO error alert
          createMembership(_username, _permissionLevel);
          Navigator.pop(context);
        }
      },
    );

    // TODO Make alert pretty
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            title: Text("Share:"),
            content: Column(
              children: [
                Form(
                  key: _formKey,
                  onChanged: () =>
                      _btnEnabled = _formKey.currentState!.validate(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Task Title TextField
                      Flexible(
                        child: TextFormField(
                          keyboardType: TextInputType.text,
                          cursorColor: Colors.white,
                          style: TextStyle(color: Colors.white),
                          // ignore: missing_return
                          validator: (input) {
                            if (input!.isEmpty) {
                              return 'Provide a username';
                            }
                          },
                          onSaved: (input) => _username = input!,
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
                              hintStyle: TextStyle(color: Colors.white),
                              hintText: 'Username'),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(5),
                      ),
                      Flexible(
                        child: DropdownButtonFormField<int>(
                          hint: Text("View"),
                          value: 3,
                          items: permissionLevels(),
                          onChanged: (value) {
                            _permissionLevel = value!;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.maxFinite,
                  height: double.maxFinite,
                  child: ListView.builder(
                    controller: membershipController,
                    itemCount: membershipList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == membershipList.length) {
                        return loadingMore();
                      } else {
                        return Row(
                          children: [
                            Text(
                              membershipList[index].owner,
                            ),
                            Padding(
                              padding: EdgeInsets.all(5),
                            ),
                            Flexible(
                              child: DropdownButtonFormField<int>(
                                hint: Text(permissionLevelTransform(
                                    membershipList[index].permissionLevel)),
                                value: membershipList[index].permissionLevel,
                                items: permissionLevels(),
                                onChanged: (value) {
                                  updateMembership(
                                      membershipList[index].id, value!);
                                },
                              ),
                            ),
                            TextButton(
                                onPressed: () => {
                                      deleteMembership(
                                          membershipList[index].id, setState)
                                    },
                                child: Icon(Icons.delete_outlined))
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
      },
    );
  }

  createMembership(String username, int permissionLevel) async {
    final response = await http.post(
      Uri.http(url, '/projectmemberships/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      body: {
        "project": widget.project.id.toString(),
        "owner": username,
        'permission_level': permissionLevel.toString(),
        'location': '1',
      },
    );
    if (response.statusCode == 201) {
      ProjectMembership newMembership =
          ProjectMembership.fromJson(json.decode(response.body));
      setState(() {
        membershipList.add(newMembership);
      });
    } else {
      print(response.statusCode);
    }
  }

  updateMembership(int id, int permissionLevel) async {
    final response = await http.patch(
      Uri.http(url, '/projectmemberships/' + id.toString() + '/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      body: {
        'permission_level': permissionLevel.toString(),
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        membershipList[membershipList.indexWhere((element) => element.id == id)]
            .permissionLevel = permissionLevel;
      });
    } else {
      print(response.statusCode);
    }
  }

  deleteMembership(int id, Function setState2) async {
    final response = await http.delete(
      Uri.http(url, '/projectmemberships/' + id.toString() + '/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
    );
    if (response.statusCode == 204) {
      setState2(() {
        membershipList.removeWhere((element) => element.id == id);
      });
    } else {
      print(response.statusCode);
    }
  }

  List<DropdownMenuItem<int>> permissionLevels() {
    List<DropdownMenuItem<int>> items = [
      DropdownMenuItem<int>(child: Text('Share'), value: 1),
      DropdownMenuItem<int>(child: Text('Edit'), value: 2),
      DropdownMenuItem<int>(child: Text('View'), value: 3),
    ];
    return items;
  }

  Widget loadingMoreTasks(int status) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: taskList[status - 1].page != 0 ? 1.0 : 0.0,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
  }

  String permissionLevelTransform(int permissionLevel) {
    String permLevel = '';
    switch (permissionLevel) {
      case 1:
        permLevel = 'Share';
        break;
      case 2:
        permLevel = 'Edit';
        break;
      case 3:
        permLevel = 'View';
        break;
    }
    return permLevel;
  }

  void updateTasks(Task task, int initialStatus) {
    // Initial Status is 0 if the task was deleted
    if (initialStatus == 0) {
      setState(() {
        taskList[task.status - 1].tasks.removeAt(taskList[task.status - 1]
            .tasks
            .indexWhere((item) => item.id == task.id));
      });
    } else {
      int index = taskList[initialStatus - 1]
          .tasks
          .indexWhere((item) => item.id == task.id);
      if (task.status == initialStatus) {
        setState(() {
          taskList[task.status - 1].tasks[index].copyWith(task: task);
        });
      } else {
        // Remove task from list
        setState(() {
          taskList[initialStatus - 1].tasks.removeAt(index);
          taskList[task.status - 1].tasks.add(task);
        });
      }
    }
  }

  insufficientPermissionsAlert() {
    // Set up the buttons
    Widget okayButton = TextButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("You don't have the permission to complete this action"),
      actions: [
        okayButton,
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

  void dispose() {
    for (int i = 0; i < taskList.length; i++) {
      taskList[i].controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }
}
