import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:guffgaff_ai/backend/API.dart';
import 'package:guffgaff_ai/pages/MyHomePage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Gemini.init(apiKey: Gemini_API_Key);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  Myhomepage(),
    );
  }
}
