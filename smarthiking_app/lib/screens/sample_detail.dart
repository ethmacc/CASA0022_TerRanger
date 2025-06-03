import 'package:flutter/material.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:vector_math/vector_math.dart' as vmath;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

class SampleDetail extends StatefulWidget {
  const SampleDetail({super.key, required this.hikeId, required this.initialSamples});
  final int hikeId;
  final List<Map> initialSamples;

  @override
  State<SampleDetail> createState() => _SampleDetailState();
}

class _SampleDetailState extends State<SampleDetail> {
  double selected = 1.0;
  int selectedSection = 0;
  List<String> sectionTypes = ['Fore', 'Mid-Fore', 'Mid-Aft', 'Aft'];

  dynamic getRouteBounds (List<LatLng> routeCoords) {
    //derived from VitList's answer on StackOverflow (https://stackoverflow.com/questions/57986855/center-poly-line-google-maps-plugin-flutter-fit-to-screen-google-map)
    double minLat = routeCoords.first.latitude;
    double minLong = routeCoords.first.longitude;
    double maxLat = routeCoords.first.latitude;
    double maxLong = routeCoords.first.longitude;

    for (var i = 0; i < routeCoords.length; i ++) {
      if(routeCoords[i].latitude < minLat) minLat = routeCoords[i].latitude;
      if(routeCoords[i].latitude > maxLat) maxLat = routeCoords[i].latitude;
      if(routeCoords[i].longitude < minLong) minLong = routeCoords[i].longitude;
      if(routeCoords[i].longitude > maxLong) maxLong = routeCoords[i].longitude;
    }

    LatLng startCoord = LatLng(minLat, minLong);
    LatLng endCoord = LatLng(maxLat, maxLong);

    if (Point(startCoord.latitude, startCoord.longitude).distanceTo(Point(endCoord.latitude, endCoord.longitude)) > 0) {
        LatLngBounds bounds = LatLngBounds(startCoord, endCoord);
        return bounds;
    } else {
      return -1;
    }
  }
  
  List<List> parseAndScalePts(String rawData) {
    List<int> dataList = json.decode(rawData).cast<int>().toList();
    List<vmath.Vector3> scaledList = [];
    List<List> pointList = [];
    List fore = [];
    List midFore = [];
    List midAft = [];
    List aft = [];
    List<int> accData = [];

    vmath.Vector3 xAxis = vmath.Vector3(1.0, 0.0, 0.0);
    vmath.Vector3 yAxis = vmath.Vector3(0.0, 1.0, 0.0);

    //List of precompmuted vectors from Jupyter notebook
    List<vmath.Vector3> sensorVectors = [
      vmath.Vector3(-0.09379656,  0.63931437, -0.76320334),
      vmath.Vector3(-0.09754516,  0.47720249, -0.87336288),
      vmath.Vector3(-0.09754516,  0.29675198, -0.94995958),
      vmath.Vector3(-0.09379656,  0.10489746, -0.99004986),
      vmath.Vector3(-0.27778512,  0.62501455, -0.72951507),
      vmath.Vector3(-0.28888688,  0.46233117, -0.83832825),
      vmath.Vector3(-0.28888688,  0.28188066, -0.91492495),
      vmath.Vector3(-0.27778512,  0.09059764, -0.95636159),
      vmath.Vector3(-0.45109855,  0.59696444, -0.66343316),
      vmath.Vector3(-0.46912683,  0.43316003, -0.76960536),
      vmath.Vector3(-0.46912683,  0.25270952, -0.84620205),
      vmath.Vector3(-0.45109855,  0.06254753, -0.89027968),
      vmath.Vector3(-0.60707652,  0.55624199, -0.56749709),
      vmath.Vector3(-0.63133851,  0.3908101 , -0.66983517),
      vmath.Vector3(-0.63133851,  0.21035959, -0.74643187),
      vmath.Vector3(-0.60707652,  0.02182508, -0.7943436 ),
      vmath.Vector3( 0.09379656,  0.10489746, -0.99004986),
      vmath.Vector3( 0.09754516,  0.29675198, -0.94995958),
      vmath.Vector3( 0.09754516,  0.47720249, -0.87336288),
      vmath.Vector3( 0.09379656,  0.63931437, -0.76320334),
      vmath.Vector3( 0.27778512,  0.09059764, -0.95636159),
      vmath.Vector3( 0.28888688,  0.28188066, -0.91492495),
      vmath.Vector3( 0.28888688,  0.46233117, -0.83832825),
      vmath.Vector3( 0.27778512,  0.62501455, -0.72951507),
      vmath.Vector3( 0.45109855,  0.06254753, -0.89027968),
      vmath.Vector3( 0.46912683,  0.25270952, -0.84620205),
      vmath.Vector3( 0.46912683,  0.43316003, -0.76960536),
      vmath.Vector3( 0.45109855,  0.59696444, -0.66343316),
      vmath.Vector3( 0.60707652,  0.02182508, -0.7943436 ),
      vmath.Vector3( 0.63133851,  0.21035959, -0.74643187),
      vmath.Vector3( 0.63133851,  0.3908101 , -0.66983517),
      vmath.Vector3( 0.60707652,  0.55624199, -0.56749709)
    ];
    
    for (int i=0; i < dataList.length; i++) {
      if (i < dataList.length - 2) {
        scaledList.add(sensorVectors[i]); //seperate out tof sensor data from accelerometer data
      } else {
        accData.add(dataList[i] - 180); //convert accelerometer data back to correct pitch and roll values
      }
    }
    for (int i=0; i < dataList.length - 2; i++) {
      scaledList[i].scale(dataList[i].toDouble()); //scale vectors using tofdata
      //rotate vectors using IMU data
      double rotX = vmath.radians(((accData[0] + 90) * -1).toDouble());
      double rotY = vmath.radians(accData[1].toDouble());
      vmath.Quaternion quartX = vmath.Quaternion.axisAngle(xAxis, rotX);
      vmath.Quaternion quartY = vmath.Quaternion.axisAngle(yAxis, rotY);
      if(i==0)debugPrint('${scaledList[i]}');
      vmath.Vector3 newVect = quartX.rotate(scaledList[i]);
      vmath.Vector3 finalVect = quartY.rotate(newVect);
      if(i==0)debugPrint('$finalVect');

      final point = (finalVect.x, finalVect.z + 900, 2.0); // Convert vector to point, and discard y (depth) value for 2D display
      switch (i) {
        case 0 || 4 || 8 || 12 || 19 || 23 || 27 || 31: //indices corresponding to fore section
          fore.add(point);
        case 1 || 5 || 9 || 13 || 18 || 22 || 26 || 30: //indices corresponding to midfore section
          midFore.add(point);
        case 2 || 6 || 10 || 14 || 17 || 21 || 25 ||29: //etc
          midAft.add(point);
        case 3 || 7 || 11 || 15 || 16 || 20 || 24 || 28: //etc
          aft.add(point);
      }
    }
    pointList.add(fore);
    pointList.add(midFore);
    pointList.add(midAft);
    pointList.add(aft);

    debugPrint('$accData');

    return pointList;
  }

  Future<void> _handleRefresh() async {
    // Simulate network fetch or database query
    await Future.delayed(Duration(seconds: 2));
    // Update the list of items and refresh the UI
    setState(() {});
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
      body: RefreshIndicator(onRefresh: _handleRefresh, // from https://www.dhiwise.com/post/flutter-pull-to-refresh-how-to-implement-customize,
        child:FutureBuilder(
          future: getSamplesByID(widget.hikeId), 
          builder: (context, allSamples) {
            List<LatLng> routeCoords = [];
            late List<Map> samplesToLoad;

            if (allSamples.data != null) {
              samplesToLoad = List.from(allSamples.data as List);
            } else {
              samplesToLoad = widget.initialSamples;
            }

            if (samplesToLoad.isNotEmpty) {
              Map selectedSample = samplesToLoad[(selected - 1).floor()];
              List<List> pointListData = parseAndScalePts(selectedSample['tofData']);

              for (var i = 0; i < samplesToLoad.length; i ++) {
                LatLng coord = LatLng(samplesToLoad[i]['lat'], samplesToLoad[i]['long']);
                routeCoords.add(coord);
              }
              
              late dynamic bounds; 

              if (routeCoords.length > 1) {
                bounds = getRouteBounds(routeCoords);
              } else {
                bounds = -1;
              }

              return SingleChildScrollView(child: 
                Center(
                child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: ListTile(
                      title: Text(
                        '2D Cross Sections',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 32.0,
                        ),
                      ),
                      subtitle: Text('LiDAR point clouds of ground surface'),
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(5, 20, 5, 20),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width / 10 * 5,
                      child:  ScatterChart(
                        ScatterChartData(
                          scatterSpots: pointListData[selectedSection].asMap().entries.map((e) {
                            final (double x, double y, double size) = e.value;
                            return ScatterSpot(
                              x,
                              y,
                            );
                          }).toList(),
                          maxX: 1000.0,
                          minX: -1000.0,
                          maxY: 1000.0,
                          minY: 0,
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(minIncluded: false, maxIncluded: false, showTitles: true, reservedSize: 24, interval: 200.0)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,maxIncluded: false, reservedSize: 36, interval: 100.0))
                          ),
                          gridData: FlGridData(
                            horizontalInterval: 100.0,
                            verticalInterval: 100.0,
                          )
                        )
                      )
                    )
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    IconButton(
                      onPressed: () {
                        if (selectedSection > 0) {
                          setState(() {
                            selectedSection -= 1;
                          });
                        }
                      }, 
                      icon: Icon(Icons.chevron_left)
                    ),
                    Text('Selected Section: ${sectionTypes[selectedSection]}'),
                    IconButton(
                      onPressed: () {
                        if (selectedSection < 3) {
                          setState(() {
                            selectedSection += 1;
                          });
                        }
                      }, 
                      icon: Icon(Icons.chevron_right)
                    ),
                  ],),
                  Slider(
                    value: selected, 
                    onChanged: (double value) {
                      setState(() {
                        debugPrint('$value');
                        selected = value;
                      });
                    },
                    min: 1,
                    max: samplesToLoad.length.toDouble(),
                    divisions: samplesToLoad.length > 1 ? samplesToLoad.length - 1 : 1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: Text('Selected sample'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 10, 10, 30),
                          child: Text('${selected.floor()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 22),
                          ),
                        )
                      ]
                    ),
                    Column(children: [
                      Padding(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Text('No. of samples')
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 10, 30),
                      child: Text('${samplesToLoad.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 22),
                      )
                    ),
                    ],)
                  ]
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Text('Sample Location', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                    ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height / 3,
                      width: MediaQuery.of(context).size.width / 10 * 8,
                      child: FlutterMap(
                        options: (routeCoords.length < 2 || bounds == -1) ? MapOptions(
                          initialCenter: LatLng(51.5, 0.127),
                          initialZoom: 9,
                        ) :
                        MapOptions(
                          initialCameraFit: CameraFit.bounds(bounds: bounds),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(markers: [Marker(point: routeCoords[(selected-1).floor()], child: Icon(Icons.location_on, color: Colors.blueAccent,))]),
                          PolylineLayer(
                            polylines: routeCoords.isNotEmpty ? [Polyline(
                              points: routeCoords,
                              color: Colors.blue,
                              strokeWidth: 5,
                              )] :
                            <Polyline<Object>> []),
                          RichAttributionWidget(attributions: [
                            TextSourceAttribution('OpenStreetMap contributors')
                          ])
                        ],
                      ),
                    ),
                    Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 50),
                  ),
                ],
              )
              )
              );
            } else {
              return Center(
                child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('No samples logged yet'),
                  ],
                )
                );
            }      
          }
        ),
      )
    );
  }
}