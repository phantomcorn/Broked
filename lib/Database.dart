import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
class Spent {
  final DateTime date;
  final double amount;

  Spent({
    required this.date,
    required this.amount
  });

  static String dateToSQLFormat(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  Map<String, dynamic> toMap() {
    return {
      'date': dateToSQLFormat(date),
      'amountSpent': amount
    };
  }

  static Spent fromMap(Map<String, Object?> map) {
    return Spent(
        date : map['date'] as DateTime,
        amount : map['amountSpent'] as double);
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
    return "spent{date: $date, amountSpent: $amount}";
  }
}



class spentDatabase {

  static final spentDatabase instance = spentDatabase._init();
  static Database? _database;
  spentDatabase._init();

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
    print('path = $path');

    return await openDatabase(path, version : 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE spent(date DATE PRIMARY KEY, amountSpent REAL)');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }


  Future<void> insertAmount(Spent data) async {
    final db = await instance.database;

    final id = await db.insert(
        'spent',
        data.toMap(),
        conflictAlgorithm : ConflictAlgorithm.replace
    );

  }
  
  Future<Spent> readAmount(DateTime date) async {
    final db = await instance.database;
    final map = await db.query(
        'spent',
        columns: ['date','amountSpent'],
        where: 'date = ?',
        whereArgs: [Spent.dateToSQLFormat(date)]);

    if (map.isNotEmpty) {
      return Spent.fromMap(map.first);
    } else {
      throw Exception('No query exists from database');
    }
  }

  Future<int> accumulateAmount(Spent spent) async {
    final db = await instance.database;
    var prevRead = await readAmount(spent.date);
    var prevAmt = prevRead.amount;
    var newAmt = prevAmt + spent.amount;
    Spent newSpent = Spent(date : spent.date, amount : newAmt);
    return db.update(
        'spent',
        newSpent.toMap(),
        where: 'date = ?',
        whereArgs: [Spent.dateToSQLFormat(spent.date)]
    );
  }

  Future<List<Spent>> getAll() async {
    final db = await instance.database;
    final result = await db.query('spent');

    return result.map((map) => Spent.fromMap(map)).toList();
  }

  Future<double> getTotalSpending() async {
    List<Spent> results = await getAll();

    if (results.isEmpty) {
      return 0;
    }

    return results.map((spent) => spent.amount).reduce((value, element) => value + element);
  }
}