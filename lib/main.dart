import 'package:dragmetal_app/services/storage_manager.dart';
import 'package:dragmetal_app/views/start_page.dart';
import 'package:flutter/material.dart';


void main() async{
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    StorageManager.removeData("sessionId");
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Arsenal'),
      debugShowCheckedModeBanner: false,
      home: StartPage(),
    );
  }
}