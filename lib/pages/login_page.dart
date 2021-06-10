import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_tracker/pages/projectList_page.dart';
import 'package:project_tracker/helper/url.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  /* Creating key to check FormState(status) */

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  late String _username, _password;

  /* Method for Navigation to Sign Up page (optional) */

  navigateToSignUpScreen() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  /* Whenever App starts/restarts i.e. a lifecycle finishes
     and starts again following methods are executed
  */

  @override
  void initState() {
    super.initState();
  }

  Future<bool> setToken(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString('token', value);
  }

  /* Method to check whether the user is signed in
     after all the validation of form is done
  */

  void login() async {
    if (_formkey.currentState!.validate()) {
      _formkey.currentState!.save();

      final response = await http.post(
        Uri.https(url, '/auth/token/login/'),
        body: {'username': _username, 'password': _password},
      );
      if (response.statusCode < 300) {
        String token = json.decode(response.body)['auth_token'];
        setToken(token);
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) =>
                    ProjectListPage(location: 1)));
      } else {
        showError(json.decode(response.body)['non_field_errors'][0]);
      }
    }
  }

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    padding: EdgeInsets.fromLTRB(80, 15, 80, 15),
    primary: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.circular(30),
    ),
  );

  /* Showing the error message */

  showError(String errorMessage) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.fromLTRB(30, 50, 30, 40),
        child: Center(
          child: ListView(
            children: <Widget>[
              Card(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 50.0),
                      child: Image(
                        image: AssetImage('asset/index.png'),
                        height: 100,
                        width: 100,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: <Widget>[
                            // Username TextField
                            Container(
                              child: TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Colors.white,
                                style: TextStyle(color: Colors.white),
                                // ignore: missing_return
                                validator: (input) {
                                  if (input!.isEmpty) {
                                    return 'Provide a username';
                                  }
                                },
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black87),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    contentPadding: EdgeInsets.all(15),
                                    suffixIcon: Icon(
                                      Icons.account_circle,
                                      color: Colors.white,
                                    ),
                                    filled: true,
                                    fillColor: Colors.black87,
                                    focusColor: Colors.black87,
                                    border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    hintStyle: TextStyle(color: Colors.white),
                                    hintText: 'Username'),
                                onSaved: (input) => _username = input!,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(10),
                            ),
                            // Password TextField
                            Container(
                              child: TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                cursorColor: Colors.white,
                                style: TextStyle(color: Colors.white),
                                obscureText: true,
                                // ignore: missing_return
                                validator: (input) {
                                  if (input!.length < 6) {
                                    return 'Password must be at least 6 char long';
                                  }
                                },
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black87),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    contentPadding: EdgeInsets.all(15),
                                    suffixIcon: Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                    ),
                                    filled: true,
                                    fillColor: Colors.black87,
                                    focusColor: Colors.black87,
                                    border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    hintStyle: TextStyle(color: Colors.white),
                                    hintText: 'Password'),
                                onSaved: (input) => _password = input!,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 20),
                            ),
                            //  Sign In button
                            ElevatedButton(
                                style: raisedButtonStyle,
                                onPressed: login,
                                child: Text(
                                  'Log In',
                                  style: TextStyle(
                                      color: Colors.black87, fontSize: 20),
                                )),
                            Padding(
                              padding: EdgeInsets.only(top: 20),
                            ),
                            // Text Button to Sign Up page
                            GestureDetector(
                              onTap: navigateToSignUpScreen,
                              child: Text(
                                'Create an account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                elevation: 20,
                shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(150),
                )),
              ),
              Padding(
                padding: EdgeInsets.all(10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
