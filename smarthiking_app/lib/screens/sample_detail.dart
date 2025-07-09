import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:terranger_lite/widgets/bottom_navbar.dart';
import 'package:terranger_lite/models/conn_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:ditredi/ditredi.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

late List<List> pointListData;
late List<Model3D> vectorData;
late String selectedSample;

class SampleDetail extends StatefulWidget {
  const SampleDetail({super.key});

  @override
  State<SampleDetail> createState() => _SampleDetailState();
}

class _SampleDetailState extends State<SampleDetail> {
 late DiTreDiController controller;

  @override
  void initState() {
    super.initState();
    controller = DiTreDiController();
  }

  double selected = 1.0;
  int selectedSection = 0;
  List<Color> dotColours = [Colors.red,Colors.orange, Colors.yellow, Colors.green];
  List<String> sectionTypes = ['Fore', 'Mid-Fore', 'Mid-Aft', 'Aft'];

  List<List> parseAndScalePts(String rawData) {
    List<int> dataList = json.decode(rawData).cast<int>().toList();
    List<vmath.Vector3> scaledList = [];
    List<List> pointList = [];
    List fore = [];
    List midFore = [];
    List midAft = [];
    List aft = [];
    List<int> accData = [];
    List<Model3D> figures = [];

    vmath.Vector3 xAxis = vmath.Vector3(1.0, 0.0, 0.0);
    vmath.Vector3 yAxis = vmath.Vector3(0.0, 1.0, 0.0);

    //List of precompmuted vectors from Jupyter notebook
    List<vmath.Vector3> sensorVectors = [
      vmath.Vector3(-0.09567086,  0.69340456, -0.83848475),
      vmath.Vector3(-0.09567086,  0.50276177, -0.91940782),
      vmath.Vector3(-0.09567086,  0.31211897, -1.00033089),
      vmath.Vector3(-0.09567086,  0.12147617, -1.08125395),
      vmath.Vector3(-0.28701257,  0.66243665, -0.76552891),
      vmath.Vector3(-0.28701257,  0.47179385, -0.84645198),
      vmath.Vector3(-0.28701257,  0.28115105, -0.92737505),
      vmath.Vector3(-0.28701257,  0.09050825, -1.00829811),
      vmath.Vector3(-0.47835429,  0.63146873, -0.69257307),
      vmath.Vector3(-0.47835429,  0.44082593, -0.77349614),
      vmath.Vector3(-0.47835429,  0.25018314, -0.85441921),
      vmath.Vector3(-0.47835429,  0.05954034, -0.93534227),
      vmath.Vector3(-0.66969601,  0.60050081, -0.61961723),
      vmath.Vector3(-0.66969601,  0.40985802, -0.7005403 ),
      vmath.Vector3(-0.66969601,  0.21921522, -0.78146337),
      vmath.Vector3(-0.66969601,  0.02857242, -0.86238643),
      vmath.Vector3( 0.09567086,  0.12147617, -1.08125395),
      vmath.Vector3( 0.09567086,  0.31211897, -1.00033089),
      vmath.Vector3( 0.09567086,  0.50276177, -0.91940782),
      vmath.Vector3( 0.09567086,  0.69340456, -0.83848475),
      vmath.Vector3( 0.28701257,  0.09050825, -1.00829811),
      vmath.Vector3( 0.28701257,  0.28115105, -0.92737505),
      vmath.Vector3( 0.28701257,  0.47179385, -0.84645198),
      vmath.Vector3( 0.28701257,  0.66243665, -0.76552891),
      vmath.Vector3( 0.47835429,  0.05954034, -0.93534227),
      vmath.Vector3( 0.47835429,  0.25018314, -0.85441921),
      vmath.Vector3( 0.47835429,  0.44082593, -0.77349614),
      vmath.Vector3( 0.47835429,  0.63146873, -0.69257307),
      vmath.Vector3( 0.66969601,  0.02857242, -0.86238643),
      vmath.Vector3( 0.66969601,  0.21921522, -0.78146337),
      vmath.Vector3( 0.66969601,  0.40985802, -0.7005403 ),
      vmath.Vector3( 0.66969601,  0.60050081, -0.61961723)
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
      vmath.Vector3 newVect = quartX.rotate(scaledList[i]);
      vmath.Vector3 finalVect = quartY.rotate(newVect);

      final point = (finalVect.x, finalVect.z + 900, 2.0); // Convert vector to point, and discard y (depth) value for 2D display
      switch (i) {
        case 0 || 4 || 8 || 12 || 19 || 23 || 27 || 31: //indices corresponding to fore section
          fore.add(point);
          figures.add(Point3D(vmath.Vector3(finalVect.x, finalVect.z, finalVect.y), width:7, color: Colors.red));
        case 1 || 5 || 9 || 13 || 18 || 22 || 26 || 30: //indices corresponding to midfore section
          midFore.add(point);
          figures.add(Point3D(vmath.Vector3(finalVect.x, finalVect.z, finalVect.y), width:7, color: Colors.orange));
        case 2 || 6 || 10 || 14 || 17 || 21 || 25 ||29: //etc
          midAft.add(point);
          figures.add(Point3D(vmath.Vector3(finalVect.x, finalVect.z, finalVect.y), width:7, color: Colors.yellow));
        case 3 || 7 || 11 || 15 || 16 || 20 || 24 || 28: //etc
          aft.add(point);
          figures.add(Point3D(vmath.Vector3(finalVect.x, finalVect.z, finalVect.y), width:7, color: Colors.green));
      }
    }
    pointList.add(fore);
    pointList.add(midFore);
    pointList.add(midAft);
    pointList.add(aft);

    debugPrint('$accData');

    return [pointList, figures];
  }

  @override
  Widget build(BuildContext context) {
    ConnManager connManager = Provider.of<ConnManager>(context, listen:true);
    
    controller.update(userScale: 2);

    if (connManager.isSampleReady) {
      selectedSample = connManager.getDataSample;
      List<List> parsed = parseAndScalePts(selectedSample);
      pointListData = List.from(parsed[0]);
      vectorData = List.from(parsed[1]);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Sample Data Viewer'),
      ),
      bottomNavigationBar: BottomNavbar(),  
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      body: SingleChildScrollView(child: 
                Center(
                child: Column(
                children: connManager.isSampleReady ? [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: ListTile(
                      leading: Icon(Icons.timeline, size:36),
                      title: Text(
                        'Sample Data Viewer',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 28.0,
                        ),
                      ),
                      subtitle: Text('LiDAR point clouds of ground surface'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 40, 10, 0),
                    child: Text('3D Point Cloud', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.width / 10 * 6,
                    width: MediaQuery.of(context).size.width / 10 * 9,
                    child: DiTreDiDraggable(
                      controller: controller,
                      child: DiTreDi(
                      figures: vectorData,
                      controller: controller,
                      ),),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: Text('2D Cross Sections', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(5, 20, 5, 20),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      height: MediaQuery.of(context).size.width / 10 * 5,
                      child:  ScatterChart(
                        ScatterChartData(
                          scatterSpots: pointListData[selectedSection].asMap().entries.map((e) {
                            final (double x, double y, double size) = e.value;
                            return ScatterSpot(
                              x,
                              y,
                              dotPainter: FlDotCirclePainter(color: dotColours[selectedSection])
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Text('Sample Location', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width / 10 * 4,
                      width: MediaQuery.of(context).size.width / 10 * 8,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(51.53768801847068, -0.01206702370748751),
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(markers: [Marker(point: LatLng(51.53768801847068, -0.01206702370748751), child: Icon(Icons.location_on, color: Colors.blueAccent,))]),
                          RichAttributionWidget(attributions: [
                            TextSourceAttribution('OpenStreetMap contributors')
                          ])
                        ],
                      ),
                    ),
                    Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 50),
                  ),
                ] : [CircularProgressIndicator()],
              )
            )
          )
      );
    }
  }