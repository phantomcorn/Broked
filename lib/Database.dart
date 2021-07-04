import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
class Spent {
  final DateTime date;
  final double amount;
  final double? budget;
  final double? target;

  Spent({
    required this.date,
    required this.amount,
    this.budget,
    this.target
  });

  static String dateToSQLFormat(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  
  Map<String, dynamic> toMap() {
    return {
      'date': dateToSQLFormat(date),
      'amountSpent': amount,
      'budget' : budget?? null,
      'savingTarget' : target?? null
    };
  }

  static Spent fromMap(Map<String, Object?> map) {
    return Spent(
        date : DateTime.parse(map['date'] as String),
        amount : map['amountSpent'] as double,
        budget : map['budget'] as double? ?? null,
        target: map['savingTarget'] as double? ?? null
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
    return "spent{date: $date,"
        "amountSpent: $amount, "
        "budget: ${budget?? null},"
        "target: ${target?? null}";
  }
}



class SpentDatabase {

  //creds to : https://www.youtube.com/watch?v=UpKrhZ0Hppk

  static final SpentDatabase instance = SpentDatabase._init();
  static Database? _database;
  SpentDatabase._init();

  static final double noOfMonths = 12.0;

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
        'budget REAL,'
        'savingTarget REAL'
        ')'
    );
  }

  DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  int numOfDaysInMonth(DateTime date) {
    //handles date.month + 1 > 12 case
    return DateTime(date.year, date.month + 1, 0).day;
  }
  
  Future<void> deleteAllRecords() async {
    final db = await instance.database;
    await db.rawDelete("DELETE FROM spent");
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<Spent?> getSpentByDate(DateTime date) async {
    final db = await instance.database;
    final map = await db.query(
        'spent',
        columns: ['date','amountSpent','budget', 'savingTarget'],
        where: 'date = ?',
        whereArgs: [Spent.dateToSQLFormat(date)]);

    if (map.isEmpty) {
      return null;
    }
    return Spent.fromMap(map.first);
  }


  Future<double> getSpendingByDate(DateTime date) async {
    final res = await getSpentByDate(date);

    if (res == null) {
      return 0;
    }
    return res.amount;
  }

  Future<int> accumulateAmount(Spent spent) async {
    //budget and target are never accumulated so it always take in the new value from argument spent

    final db = await instance.database;
    Spent? prevSpent = await getSpentByDate(spent.date);
    Spent newSpent;
    if (prevSpent == null) {
      newSpent = Spent(
          date : spent.date,
          amount : spent.amount,
          budget: spent.budget,
          target: spent.target
      );
    } else {
      newSpent = Spent(
          date : spent.date,
          amount : prevSpent.amount + spent.amount,
          budget: spent.budget ?? prevSpent.budget,
          target: spent.target ?? prevSpent.target
      );
    }

    return db.insert(
        'spent',
        newSpent.toMap(),
        conflictAlgorithm : ConflictAlgorithm.replace
    );
  }

  Future<List<Spent>> getAllSpentInAMonth(int month) async {
    final db = await instance.database;
    String monthStr;
    if (month < 10) {
      monthStr = '0' + month.toString();
    } else {
      monthStr = month.toString();
    }

    final results = await db.rawQuery(
        "SELECT * "
        "FROM spent "
        "WHERE strftime('%m', date) = '$monthStr'"
        "ORDER BY date(date)"
    );

    return results.map((map) => Spent.fromMap(map)).toList();
  }


  Future<double> getTotalSpendingYearly(int year) async {
    final db = await instance.database;

    final results = await db.rawQuery(
        "SELECT * "
        "FROM spent "
        "WHERE strftime('%Y', date) = '$year'"
        "ORDER BY date(date)"
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
    final results = await getAllSpentInAMonth(month);

    if (results.isEmpty) {
      return 0;
    }

    return results.map((spent) => spent.amount)
        .toList()
        .reduce((value, element) => value + element);
  }

  Future addBudgetAndTarget(double budget, double target) async {
    final db = await instance.database;
    DateTime now = DateTime.now();
    //no query
    if (await getSpentByDate(startOfMonth(now)) == null) {
      Spent spent = Spent(
          date: startOfMonth(now),
          amount: 0,
          budget: budget,
          target: target
      );
      await accumulateAmount(spent);
    } else {
      await db.rawUpdate(
          """UPDATE spent
             SET budget = ?,
                 savingTarget = ?
             WHERE date = ? 
          """,
          [budget, target, Spent.dateToSQLFormat(startOfMonth(now))]
      );
    }
  }


  Future<double> getBudgetByDate(DateTime date) async {

    final res = await getSpentByDate(startOfMonth(date));

    if (res == null) {
      return 0;
    }
    return res.budget ?? 0;
  }

  Future<double> getTargetByDate(DateTime date) async {

    final res = await getSpentByDate(startOfMonth(date));

    if (res == null) {
      return 0;
    }

    return res.target ?? 0;
  }



  Future<double> getOverUnderSpent(DateTime date) async {
    return await getBudgetByDate(date) - await getTotalSpendingMonthly(date.month);
  }

  Future<double> getAvgSpending(DateTime date) async {
    return await getTotalSpendingMonthly(date.month) / numOfDaysInMonth(date);
  }

  Future<double> getSpendingPerDayToHitTarget(DateTime date) async {
    final availToSpend = await getBudgetByDate(date) - await getTargetByDate(date);
    return availToSpend / numOfDaysInMonth(date);
  }

}