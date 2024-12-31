import 'package:flutter/material.dart';
import 'package:hotel_reservation/home_page.dart';
import 'package:hotel_reservation/link.dart';
import 'package:hotel_reservation/verify_person.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Link(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hotel Reservation',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: VerifyPerson(),
      ), // Fermeture de MaterialApp
    ); // Fermeture de ChangeNotifierProvider
  }
}
