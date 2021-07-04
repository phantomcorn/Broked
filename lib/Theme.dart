import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class customTheme {

  static ThemeData get defaultTheme {
    return ThemeData(
      scaffoldBackgroundColor: MyApp.theme[MyApp.selectedTheme]!["bg"],
      textTheme: TextTheme(
        bodyText1: GoogleFonts.nunitoTextTheme().bodyText1,
        bodyText2: GoogleFonts.nunitoTextTheme().bodyText2
      ).apply(
        bodyColor: MyApp.theme[MyApp.selectedTheme]!["text"],
        displayColor: MyApp.theme[MyApp.selectedTheme]!["text"]
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          primary: MyApp.theme[MyApp.selectedTheme]!["dateButton"],
          textStyle: TextStyle(
            fontFamily: GoogleFonts.nunito().fontFamily,
            color: MyApp.theme[MyApp.selectedTheme]!["text"]
          )
        )
      ),
    );
  }
}