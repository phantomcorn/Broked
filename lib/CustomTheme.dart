import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class customTheme {

  static ThemeData get greyTheme {
    return ThemeData(
      primaryColor: Colors.grey,
      scaffoldBackgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      textTheme: GoogleFonts.nunitoTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style : ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          primary : const Color.fromRGBO(169, 169, 169, 1),
        )
      )
    );
  }
}