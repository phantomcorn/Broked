import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
class Spent {
  final DateTime date;
  final double amount;
  final double? budget;

  Spent({
    required this.date,
    required this.amount,
    this.budget
  });

  static String dateToSQLFormat(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  
  Map<String, dynamic> toMap() {
    return {
      'date': dateToSQLFormat(date),
      'amountSpent': amount,
      'budget' : budget?? null
    };
  }

  static Spent fromMap(Map<String, Object?> map) {
    return Spent(
        date : DateTime.parse(map['date'] as String),
        amount : map['amountSpent'] as double,
        budget : map['budget'] as double? ?? null
    );
  }

  Spent copy({
    DateTime? date,
    double? amount
  }) =>
      Spent(
          date: date ?? this.date,
          amount: amount ?? this.amount
      );


  @override
  String toString() {
    return "spent{date: $date, amountSpent: $amount, budget: ${budget?? null}";
  }
}



class spentDatabase {

  //creds to : https://www.youtube.com/watch?v=UpKrhZ0Hppk

  static final spentDatabase instance = spentDatabase._init();
  static Database? _database;
  spentDatabase._init();

  static final int noOfMonths = 12;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('spent.db');
    return _database!;
  }

  Future<Database> _initDB(String filename) async {
    final dbPath = await getDatabasesPath();
    var path = join(dbPath, filename);
    
    return await openDatabase(path, version : 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE spent('
        'date DATE PRIMARY KEY NOT NULL,'
        'amountSpent REAL NOT NULL,'
        'budget REAL'
        ')'
    );
  }

  DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  Future<void> deleteAllRecords() async {
    final db = await instance.database;
    await db.rawDelete("DELETE FROM spent");
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  
  Future<double> getSpendingByDate(DateTime date) async {
    final db = await instance.database;
    final map = await db.query(
        'spent',
        columns: ['date','amountSpent'],
        where: 'date = ?',
        whereArgs: [Spent.dateToSQLFormat(date)]);
    

    if (map.isEmpty) {
      return 0;
    }
    return map.first['amountSpent'] as double;
  }

  Future<int> accumulateAmount(Spent oldSpent) async {
    final db = await instance.database;
    var prevAmt = await getSpendingByDate(oldSpent.date);
    var newAmt = prevAmt + oldSpent.amount;
    Spent newSpent = Spent(
        date : oldSpent.date,
        amount : newAmt,
        budget: oldSpent.budget ?? null
    );
    return db.insert(
        'spent',
        newSpent.toMap(),
        conflictAlgorithm : ConflictAlgorithm.replace
    );
  }

  Future<List<Spent>> getAll() async {
    final db = await instance.database;
    final results = await db.query('spent');

    return results.map((map) => Spent.fromMap(map)).toList();
  }

  Future<double> getTotalSpending() async {
    List<Spent> results = await getAll();
    if (results.isEmpty) {
      return 0;
    }

    return results.map((spent) => spent.amount)
        .reduce((value, element) => value + element);
  }

  Future<double> getTotalSpendingYearly(int year) async {
    final db = await instance.database;

    final results = await db.rawQuery(
        "SELECT * FROM spent WHERE strftime('%Y', date) = '$year'"
    );

    if (results.isEmpty) {
      return 0;
    }

    return results.map((map) => Spent.fromMap(map).amount)
        .toList()
        .reduce((value, element) => value + element);
  }

  Future<double> getTotalSpendingMonthly(int month) async {
    final db = await instance.database;
    String monthStr;
    if (month < 10) {
      monthStr = '0' + month.toString();
    } else {
      monthStr = month.toString();
    }

    final results = await db.rawQuery(
      "SELECT * FROM spent WHERE strftime('%m', date) = '$monthStr'"
    );

    if (results.isEmpty) {
      return 0;
    }

    return results.map((map) => Spent.fromMap(map).amount)
        .toList()
        .reduce((value, element) => value + element);
  }

  Future addBudget(double budget) async {
    final db = await instance.database;
    DateTime now = DateTime.now();
    if (await getSpendingByDate(startOfMonth(now)) == 0) {
      print("creating new");
      Spent spent = Spent(
        date: startOfMonth(now),
        amount: 0,
        budget: budget
      );
      await accumulateAmount(spent);
    } else {
      await db.rawUpdate(
          """UPDATE spent
             SET budget = ?
             WHERE date = ? """,
          [DateTime(now.year, now.month, 1)]
      );
    }
  }

  

  Future<double> getSpendingToday() async {
    return await getSpendingByDate(DateTime.now());
  }

  Future<double> getAvgSpending(int year) async {
    return (await getTotalSpendingYearly(year) / noOfMonths).roundToDouble() ;
  }

}