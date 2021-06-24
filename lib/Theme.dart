import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class customTheme {

  static ThemeData get defaultTheme {
    return ThemeData(
      scaffoldBackgroundColor: MyApp.Theme[MyApp.selectedTheme]!["bg"],
      textTheme: TextTheme(
        bodyText1: GoogleFonts.nunitoTextTheme().bodyText1,
        bodyText2: GoogleFonts.nunitoTextTheme().bodyText2
      ).apply(
        bodyColor: MyApp.Theme[MyApp.selectedTheme]!["text"],
        displayColor: MyApp.Theme[MyApp.selectedTheme]!["text"]
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          primary: MyApp.Theme[MyApp.selectedTheme]!["dateButton"],
          textStyle: TextStyle(
            fontSize: 30,
            fontFamily: GoogleFonts.nunito().fontFamily
          )
        )
      ),
    );
  }
}