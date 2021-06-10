import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_tracker/pages/projectList_page.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
              child: Text(
                'Options',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              margin: EdgeInsets.all(0.0),
              padding: EdgeInsets.all(10.0)),
          _createDrawerItem(
              text: 'Project List',
              onTap: () => {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ProjectListPage(location: 1)))
                  }),
          _createDrawerItem(
              text: 'Archive',
              onTap: () => {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ProjectListPage(location: 2)))
                  }),
          _createDrawerItem(
              text: 'Trash',
              onTap: () => {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ProjectListPage(location: 3)))
                  }),
          _createDrawerItem(
              text: 'Logout',
              onTap: () {
                signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }),
        ],
      ),
    );
  }

  Widget _createDrawerItem(
      {required String text, required GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
  }
}
