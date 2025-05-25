import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Hike {
  final int id;
  final String name;
  final int distance;
  final int elevation;
  final String date;

  const Hike({required this.id, required this.name, required this.distance, required this.elevation, required this.date});

  Map<String, Object?> toMap() {
    return {'id' : id, 'name' : name, 'distance' : distance, 'elevation' : elevation, 'date': date};
  }

  @override
  String toString() {
    return 'Hike{id : $id, name : $name, distance : $distance, elevation : $elevation, date: $date}';
  }
}

class Sample {
  final int id;
  final String hikeName;
  final String tofData; 

  const Sample({required this.id, required this.hikeName, required this.tofData});
}

Future<Database> openHikingDataBase () async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'hikes_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE hikes(id INTEGER PRIMARY KEY, name TEXT, distance INTEGER, elevation INTEGER date TEXT); CREATE TABLE samples(id INTEGER PRIMARY KEY, hikeName TEXT, tofData TEXT)'
      );
    },
    version: 1,
  );
  return database;
}

Future<void> insertHike(Hike hike) async {
    //Get reference to db
    final db = await openHikingDataBase();

    try{
      await db.insert(
        'hikes', 
        hike.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
    debugPrint('$e');
    }
}

Future<int> deleteHike(int id) async {
  final db = await openHikingDataBase();
    
  return await db.delete('hikes', where: 'id = ?', whereArgs: [id]);
}

Future<int> getLatestID (String tableName) async {
  //Get reference to db
  final db = await openHikingDataBase();

  List<Map> maps = await db.rawQuery("SELECT MAX(id) FROM $tableName");
  var maxID = maps[0]['MAX(id)'];
  if (maxID == null) {
    return 0;
  } else {
    return maxID += 1;
  }
}

Future<List<Map>> getHikeByID (int id) async {
  //Get reference to db
  final db = await openHikingDataBase();

  List<Map> maps = await db.rawQuery("SELECT * FROM hikes WHERE id = $id");
  return maps;
}

Future<List<Map>> getAllData (String tableName) async {
  //Get reference to db
  final db = await openHikingDataBase();

  List<Map> maps = await db.rawQuery("SELECT * FROM $tableName");
  return maps;
}

void devOnly () async {
  //Dev only function for manipulating the database
  final db = await openHikingDataBase();
  return db.execute(
        'CREATE TABLE hikes(id INTEGER PRIMARY KEY, name TEXT, distance INTEGER, elevation INTEGER, date TEXT)'
      );
}
  


