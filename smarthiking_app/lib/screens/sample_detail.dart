import 'package:flutter/material.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:vector_math/vector_math.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

List<Vector3> sensorVectors = [
  Vector3(-0.09379656,  0.63931437, -0.76320334),
  Vector3(-0.09754516,  0.47720249, -0.87336288),
  Vector3(-0.09754516,  0.29675198, -0.94995958),
  Vector3(-0.09379656,  0.10489746, -0.99004986),
  Vector3(-0.27778512,  0.62501455, -0.72951507),
  Vector3(-0.28888688,  0.46233117, -0.83832825),
  Vector3(-0.28888688,  0.28188066, -0.91492495),
  Vector3(-0.27778512,  0.09059764, -0.95636159),
  Vector3(-0.45109855,  0.59696444, -0.66343316),
  Vector3(-0.46912683,  0.43316003, -0.76960536),
  Vector3(-0.46912683,  0.25270952, -0.84620205),
  Vector3(-0.45109855,  0.06254753, -0.89027968),
  Vector3(-0.60707652,  0.55624199, -0.56749709),
  Vector3(-0.63133851,  0.3908101 , -0.66983517),
  Vector3(-0.63133851,  0.21035959, -0.74643187),
  Vector3(-0.60707652,  0.02182508, -0.7943436 ),
  Vector3( 0.09379656,  0.10489746, -0.99004986),
  Vector3( 0.09754516,  0.29675198, -0.94995958),
  Vector3( 0.09754516,  0.47720249, -0.87336288),
  Vector3( 0.09379656,  0.63931437, -0.76320334),
  Vector3( 0.27778512,  0.09059764, -0.95636159),
  Vector3( 0.28888688,  0.28188066, -0.91492495),
  Vector3( 0.28888688,  0.46233117, -0.83832825),
  Vector3( 0.27778512,  0.62501455, -0.72951507),
  Vector3( 0.45109855,  0.06254753, -0.89027968),
  Vector3( 0.46912683,  0.25270952, -0.84620205),
  Vector3( 0.46912683,  0.43316003, -0.76960536),
  Vector3( 0.45109855,  0.59696444, -0.66343316),
  Vector3( 0.60707652,  0.02182508, -0.7943436 ),
  Vector3( 0.63133851,  0.21035959, -0.74643187),
  Vector3( 0.63133851,  0.3908101 , -0.66983517),
  Vector3( 0.60707652,  0.55624199, -0.56749709)
 ];


class SampleDetail extends StatefulWidget {
  const SampleDetail({super.key, required this.hikeId, required this.initialSamples});
  final int hikeId;
  final List<Map> initialSamples;

  @override
  State<SampleDetail> createState() => _SampleDetailState();
}

class _SampleDetailState extends State<SampleDetail> {

  void parseAndCalcPts(String rawData) {
    List<int> dataList = json.decode(rawData).cast<int>().toList();
    List<Vector> scaledList = [];
    for (int i=0; i < dataList.length; i++) {
      //scaledList.add(); TODO: finish off data processing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Erosion Sampling'),
      ),
      bottomNavigationBar: BottomNavbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EnterHike())
            );
        },
        child: Icon(Icons.add)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      body: FutureBuilder(
        future: getSamplesByID(widget.hikeId), 
        builder: (context, allSamples) {
          late List<Map> samplesToLoad;

          if (allSamples.data != null) {
            samplesToLoad = List.from(allSamples.data as List);
          } else {
            samplesToLoad = widget.initialSamples;
          }

          if (samplesToLoad.isNotEmpty) {
            Map selectedSample = samplesToLoad[0];


            return Column(

            );
          } else {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('No samples logged yet'),
                ],
              );
          }      
        }
      ),
    );
  }
}