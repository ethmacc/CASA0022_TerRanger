import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Hike {
  final int id;
  final String name;
  final int distance;
  final int elevation;

  const Hike({required this.id, required this.name, required this.distance, required this.elevation});

  Map<String, Object?> toMap() {
    return {'id' : id, 'name' : name, 'distance' : distance, 'elevation' : elevation};
  }

  @override
  String toString() {
    return 'Hike{id : $id, name : $name, distance : $distance, elevation : $elevation}';
  }
}

class Sample {
  final int id;
  final String hikeName;
  final String tofData; 

  const Sample({required this.id, required this.hikeName, required this.tofData});
}
void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'hikes_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE hikes(id INTEGER PRIMARY KEY, name TEXT, distance INTEGER, elevation INTEGER); CREATE TABLE samples(id INTEGER PRIMARY KEY, hikeName TEXT, tofData TEXT)'
      );
    },
    version: 1,
  );

  Future<void> insertHike(Hike hike) async {
    //Get reference to db
    final db = await database;

    await db.insert(
      'hikes', 
      hike.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

  


