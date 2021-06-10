import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Spent {
  final int day;
  final int month;
  final int year;
  final double amount;

  Spent({
    required this.day,
    required this.month,
    required this.year,
    required this.amount
  });

  Map<String, dynamic> toMap() {
    return {
      'date': month.toString() + "-" + day.toString() + "-" + year.toString(),
      'amountSpent': amount
    };
  }

  @override
  String toString() {
    return "spent{date: $month-$day-$year, amountSpent: $amount}";
  }
}

void main() async {
  final database = openDatabase(
    join(await getDatabasesPath(), "spent.db"),
    onCreate : (db, version)  {
      return db.execute(
          'CREATE TABLE spent(date DATE PRIMARY KEY, amountSpent REAL)'
      );
    },
    version : 1
  );
}