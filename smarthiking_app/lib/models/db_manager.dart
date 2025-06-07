import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Hike {
  final int id;
  final String name;
  final String date;

  const Hike({required this.id, required this.name, required this.date});

  Map<String, Object?> toMap() {
    return {'id' : id, 'name' : name, 'date': date};
  }

  @override
  String toString() {
    return 'Hike{id : $id, name : $name, date: $date}';
  }
}

class Sample {
  final int id;
  final int hikeId;
  final String tofData;
  final double lat; 
  final double long;
  final double elevation;

  const Sample({required this.id, required this.hikeId, required this.tofData, required this.lat, required this.long, required this.elevation});

  Map<String, Object?> toMap() {
    return {'id' : id, 'hikeId' : hikeId, 'tofData' : tofData, 'lat' : lat, 'long': long, 'elevation':elevation};
  }

  @override
  String toString() {
    return 'Hike{id : $id, hikeId : $hikeId, tofData : $tofData, lat : $lat, long: $long, elevation: $elevation}';
  }
}

Future<Database> openHikingDataBase () async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'hikes_database.db'),
    onCreate: (db, version) {
      db.execute(
        'CREATE TABLE hikes(id INTEGER PRIMARY KEY, name TEXT, date TEXT)'
      );
      db.execute(
        'CREATE TABLE samples(id INTEGER PRIMARY KEY, hikeId INTEGER, tofData TEXT, lat FLOAT, long FLOAT, elevation FLOAT)'
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

Future<void> insertSample(Sample sample) async {
    //Get reference to db
    final db = await openHikingDataBase();

    try{
      await db.insert(
        'samples', 
        sample.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
    debugPrint('$e');
    }
}

Future<int> deleteAllSamples(int hikeId) async{
//Get reference to db
    final db = await openHikingDataBase();

    return await db.delete('samples', where: 'hikeId = ?', whereArgs: [hikeId]);
}

Future<List<Map>> getSamplesByID (int hikeId) async {
  //Get reference to db
  final db = await openHikingDataBase();

  List<Map> maps = await db.rawQuery("SELECT * FROM samples WHERE hikeId = $hikeId");
  return maps;
}

Future<List<Map>> getAllData (String tableName) async {
  //Get reference to db
  final db = await openHikingDataBase();

  List<Map> maps = await db.rawQuery("SELECT * FROM $tableName");
  return maps;
}



