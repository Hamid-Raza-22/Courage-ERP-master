import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart' show Align, Alignment, AlwaysStoppedAnimation, AnimatedContainer, Border, BorderRadius, BorderSide, BoxDecoration, BuildContext, Card, Center, CircularProgressIndicator, Color, Colors, Column, Container, EdgeInsets, ElevatedButton, FloatingLabelBehavior, FontWeight, Form, FormState, GlobalKey, Icon, Icons, Image, InputBorder, InputDecoration, LinearProgressIndicator, MainAxisAlignment, MaterialPageRoute, Navigator, OutlineInputBorder, Padding, RoundedRectangleBorder, RouteSettings, Row, Scaffold, SingleChildScrollView, SizedBox, Stack, State, StatefulWidget, Text, TextEditingController, TextFormField, TextStyle, Widget, showDialog;
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart' show Fluttertoast, Toast, ToastGravity;
import 'package:order_booking_shop/Views/HomePage.dart' show HomePage;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import '../API/Globals.dart' show userId, userNames;
import '../API/newDatabaseOutPuts.dart';
import '../Databases/DBHelper.dart';
import '../Models/loginModel.dart';
import '../main.dart';
import 'PolicyDBox.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    // _showPolicyDialog();
    // showDialog(
    //               context: context,
    //               builder: (context) => const PolicyDialog(),
    //             );
    // _requestPermission();

    // DatabaseOutputs outputs = DatabaseOutputs();
    // outputs.initializeData();
  }
  Future<void> _requestPermissions() async {
    // Request notification permission
    if (await Permission.notification.request().isDenied) {
      // Notification permission not granted
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      return;
    }

    // Request location permission
    if (await Permission.location.request().isDenied) {
      // Location permission not granted
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }
  //
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   //_showPolicyDialog();
  // }
  // Future<void> _showPolicyDialog() async {
  //   bool? agreed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => const PolicyDialog(),
  //   );
  //
  //   if (agreed == null || !agreed) {
  //     // User did not agree, close the app or keep showing the dialog
  //     _showPolicyDialog(); // Show the dialog again until the user agrees
  //   }
  // }
  final dblogin = DBHelper();
  Future<void> _handleLogin() async {
    // Check if both ID and password fields are not empty
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter ID and password",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return; // Exit the method if either field is empty
    }

    setState(() {
      _isLoading = true; // Set loading to true when button is pressed
    });

    bool isConnected = await isInternetAvailable();
    if (isConnected) {
      await _login();
    } else {
      Fluttertoast.showToast(
        msg: "No internet connection.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    setState(() {
      _isLoading = false; // Set loading to false after login function is complete
    });
  }


  _login() async {
    bool isLoggedIn = await _checkLoginStatus();

    var response = await dblogin.login(
      Users(user_id: _emailController.text, password: _passwordController.text, user_name: ''),
    );
    if (response == true) {
      setState(() {
        _loadingProgress = 20; // Start progress
      });
      var userName = await dblogin.getUserName(_emailController.text);
      var userCity = await dblogin.getUserCity(_emailController.text);
      var designation = await dblogin.getUserDesignation(_emailController.text);
      setState(() {
        _loadingProgress = 40; // Start progress
      });
      if (userName != null && userCity != null && designation!= null) {
        if (kDebugMode) {
          print('User Name: $userName, City: $userCity, Designation: $designation');
        }
        // Store user inputs in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('userId', _emailController.text);
        prefs.setString('userNames', userName);
        prefs.setString('userCitys', userCity);
        prefs.setString('userDesignation', designation);

        // Print saved values
        if (kDebugMode) {
          print('Saved userId: ${prefs.getString('userId')}');
          print('Saved userNames: ${prefs.getString('userNames')}');
          print('Saved userCitys: ${prefs.getString('userCitys')}');
          print('Saved userDesignation: ${prefs.getString('userDesignation')}');
        }
        Map<String, dynamic> dataToPass = {
          'userName': userName,
        };
        if (kDebugMode) {
          print("userId: $userId");
        }
        newDatabaseOutputs outputs = newDatabaseOutputs();
        setState(() {
          _loadingProgress = 90; // Start progress
        });
        await outputs.checkFirstRun();
        if (isLoggedIn) {
          Map<String, dynamic> dataToPass = {
            'userName': userNames
          };
          // User is already logged in, navigate to the home page directly
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const HomePage(),
                settings: RouteSettings(arguments: dataToPass)
            ),
          );
          return;
        }
        setState(() {
          _loadingProgress = 100; // Start progress
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
            settings: RouteSettings(arguments: dataToPass),
          ),
        );
      } else {
        if (kDebugMode) {
          print('Failed to fetch user name or city');
        }
      }
      Fluttertoast.showToast(msg: "Successfully logged in", toastLength: Toast.LENGTH_LONG);
    } else {
      Fluttertoast.showToast(msg: "Failed login", toastLength: Toast.LENGTH_LONG);
    }
  }
  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userNames = prefs.getString('userNames');
    String? userCitys = prefs.getString('userCitys');
    String? userDesignation = prefs.getString('userDesignation');
    return userDesignation!= null && userId != null && userId.isNotEmpty && userCitys!=null && userCitys.isNotEmpty && userNames!=null && userNames.isNotEmpty;
  }

  // void _setFirstLoginStatus(bool value) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setBool('isFirstLogin', value);
  // }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/images/p1.png',
                        width: 250.0,
                        height: 250.0,
                      ),
                    ),
                    const SizedBox(height: 0.0),
                    const Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.brown,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: const BorderSide(color: Colors.white, width: 1),
                      ),
                      child: SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'User ID',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(1.0),
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.black,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12.0),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.green, width: 0),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white, width: 0),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: const BorderSide(color: Colors.white, width: 1),
                      ),
                      child: SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(1.0),
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.black,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(12.0),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      height: 40,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background container to represent the remaining progress
                          Container(
                            width: 200,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green, // Default background color set to green
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          // Colored container representing the progress
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300), // Adjust animation duration as needed
                            width: _isLoading ? 200 * _loadingProgress / 100 : 0,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white, // Color of the progress
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          // Button content
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLoading ? '$_loadingProgress%' : 'Login',
                                    style: TextStyle(fontSize: 18, color: Colors.black),
                                  ),
                                  Icon(Icons.arrow_forward, color: Colors.black,),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),


                    const SizedBox(height: 30.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Add some space between the new text and image
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Image.asset(
                                  'assets/images/b1.png',
                                  width: 23.0,
                                  height: 23.0,
                                ),
                                const Text(
                                  'MetaXperts',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  '03456699233',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
        );
    }
}