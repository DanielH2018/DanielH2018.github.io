import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:project_tracker/widgets/myDrawer.dart';
import 'package:project_tracker/models/project.dart';
import 'package:project_tracker/views/project_list.dart';
import 'package:project_tracker/helper/url.dart';

class ProjectListPage extends StatefulWidget {
  final int location;
  ProjectListPage({required this.location});

  @override
  _ProjectListPageState createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  String token = '';
  int page = 1;
  late ScrollController controller;
  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    fetchProjects();
    controller = new ScrollController()..addListener(_scrollListener);
  }

  // TODO Add Search
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        centerTitle: true,
        title: Text(getTitle()),
      ),
      body: Center(
        child: Scrollbar(
            child: ProjectList(
          items: projects,
          onSwipeTap: (int itemID) => updateProject(itemID),
          hasMore: loadingMoreProjects,
          controller: controller,
        )),
      ),
      floatingActionButton: widget.location == 1
          ? FloatingActionButton(
              backgroundColor: Colors.black87,
              child: Icon(Icons.add),
              onPressed: () {
                createProjectAlert();
              },
            )
          : null,
      drawer: MyDrawer(),
    );
  }

  fetchProjects() async {
    if (token == '') {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token')!;
    }
    final response = await http.get(
      Uri.https(url, '/projects/',
          {'location': widget.location.toString(), 'page': page.toString()}),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
    );
    if (response.statusCode == 200) {
      final parsed = json.decode(response.body)['results'] as List;
      setState(() {
        projects.addAll(
            List<Project>.from(parsed.map((model) => Project.fromJson(model))));
      });
      final next = json.decode(response.body)['next'];
      if (next == null) {
        controller.removeListener(_scrollListener);
        page = 0;
      } else {
        page++;
      }
    } else {
      // TODO Display error alert
      print(response.statusCode);
    }
  }

  void createProject(
    String name,
    String description,
  ) async {
    // Create Project
    final response = await http.post(
      Uri.https(url, '/projects/'),
      headers: {HttpHeaders.authorizationHeader: ("Token " + token)},
      body: {"name": name, 'description': description},
    );
    if (response.statusCode == 201) {
      Project newProject = Project.fromJson(json.decode(response.body));
      // TODO check length of projects before add
      setState(() {
        projects.add(newProject);
      });
    } else {
      // TODO Display error alert
      print(response.statusCode);
    }
  }

  updateProject(int itemID) {
    setState(() {
      projects.removeWhere((project) => project.id == itemID);
    });
  }

  createProjectAlert() {
    /// Key used to reference the form.
    final _formKey = GlobalKey<FormState>();
    String _projectName = '';
    String _projectDescription = '';
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
          createProject(_projectName, _projectDescription);
          Navigator.pop(context);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("New Project:"),
      content: Form(
        key: _formKey,
        onChanged: () => _btnEnabled = _formKey.currentState!.validate(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Task Title TextField
            Container(
              child: TextFormField(
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                validator: (input) {
                  if (input!.isEmpty) {
                    return 'Provide a name';
                  }
                },
                onSaved: (input) => _projectName = input!,
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
                    hintText: 'Project Name'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            Container(
              child: TextFormField(
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
                // ignore: missing_return
                onSaved: (input) => _projectDescription = input!,
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
                    hintText: 'Project Description'),
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

  void _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      fetchProjects();
    }
  }

  Widget loadingMoreProjects() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: page != 0 ? 1.0 : 0.0,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
  }

  String getTitle() {
    String toReturn = '';
    if (widget.location == 1) {
      toReturn = 'Project List';
    } else if (widget.location == 2) {
      toReturn = 'Archive';
    } else if (widget.location == 3) {
      toReturn = 'Trash';
    }
    return toReturn;
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    super.dispose();
  }
}
